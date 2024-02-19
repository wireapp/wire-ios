////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import WireCoreCrypto

// sourcery: AutoMockable
public protocol CoreCryptoProviderProtocol {

    /// Retrieve the shared core crypto instance or create one if one does not yet exist.
    ///
    /// This function is safe to be called concurrently from multiple Tasks
    func coreCrypto() async throws -> SafeCoreCryptoProtocol

    /// Initialise a new MLS client with basic credentials
    ///
    /// - parameters:
    ///   - mlsClientID: qualified client ID of the self client
    func initialiseMLSWithBasicCredentials(mlsClientID: MLSClientID) async throws

    /// Initialise a new MLS client after completing end to end identity enrollment
    /// 
    /// - parameters:
    ///   - enrollment: enrollment instance which was used to establish end to end identity
    ///   - certificateChain: the resulting certificate chain from the end to end identity enrollment
    func initialiseMLSWithEndToEndIdentity(enrollment: E2eiEnrollment, certificateChain: String) async throws

}

public actor CoreCryptoProvider: CoreCryptoProviderProtocol {
    private let selfUserID: UUID
    private let sharedContainerURL: URL
    private let accountDirectory: URL
    private let cryptoboxMigrationManager: CryptoboxMigrationManagerInterface
    private let syncContext: NSManagedObjectContext
    private let allowCreation: Bool
    private var coreCrypto: SafeCoreCrypto?
    private var loadingCoreCrypto = false
    private var initialisatingMLS = false
    private var hasInitialisedMLS = false
    private var coreCryptoContinuations: [CheckedContinuation<SafeCoreCrypto, Error>] = []
    private var initialiseMlsContinuations: [CheckedContinuation<Void, Error>] = []

    public init(selfUserID: UUID,
                sharedContainerURL: URL,
                accountDirectory: URL,
                syncContext: NSManagedObjectContext,
                cryptoboxMigrationManager: CryptoboxMigrationManagerInterface,
                allowCreation: Bool = true) {
        self.selfUserID = selfUserID
        self.sharedContainerURL = sharedContainerURL
        self.accountDirectory = accountDirectory
        self.syncContext = syncContext
        self.allowCreation = allowCreation
        self.cryptoboxMigrationManager = cryptoboxMigrationManager
    }

    public func coreCrypto() async throws -> SafeCoreCryptoProtocol {
        return try await getCoreCrypto()
    }

    public func initialiseMLSWithBasicCredentials(mlsClientID: MLSClientID) async throws {
        WireLogger.mls.info("Initialising MLS client with basic credentials")
        _ = try await coreCrypto().perform { coreCrypto in
            try await coreCrypto.mlsInit(
                clientId: mlsClientID.clientID.utf8Data!, // TODO: [jacob] don't force unwrap
                ciphersuites: [CiphersuiteName.default.rawValue],
                nbKeyPackage: nil
            )
            try await generateClientPublicKeysIfNeeded(with: coreCrypto)
        }
    }

    public func initialiseMLSWithEndToEndIdentity(enrollment: E2eiEnrollment, certificateChain: String) async throws {
        WireLogger.mls.info("Initialising MLS client from end-to-end identity enrollment")
        try await coreCrypto().perform { coreCrypto in
            _ = try await coreCrypto.e2eiMlsInitOnly(
                enrollment: enrollment,
                certificateChain: certificateChain,
                nbKeyPackage: nil
            )
            try await generateClientPublicKeysIfNeeded(with: coreCrypto)
        }
    }

    private func resumeInitialiseMlsContinuations(with result: Swift.Result<Void, Error>) {
        for continuation in initialiseMlsContinuations {
            continuation.resume(with: result)
        }
        coreCryptoContinuations = []
    }

    // Create an CoreCrypto instance with guranteees that only one task is performing
    // the operation while others wait for it to complete.
    //
    // Based on the structured caching in an actor:
    // https://forums.swift.org/t/structured-caching-in-an-actor/65501/13
    private func getCoreCrypto() async throws -> SafeCoreCrypto {
        guard !loadingCoreCrypto else {
            return try await withCheckedThrowingContinuation { continuation in
                coreCryptoContinuations.append(continuation)
            }
        }

        if let coreCrypto = coreCrypto {
            return coreCrypto
        } else {
            loadingCoreCrypto = true
            let cc: SafeCoreCrypto
            do {
                cc = try await createCoreCrypto()
            } catch {
                resumeCoreCryptoContinuations(with: .failure(error))
                loadingCoreCrypto = false
                throw error
            }

            resumeCoreCryptoContinuations(with: .success(cc))
            loadingCoreCrypto = false
            coreCrypto = cc
            return cc
        }
    }

    private func resumeCoreCryptoContinuations(with result: Swift.Result<SafeCoreCrypto, Error>) {
        for continuation in coreCryptoContinuations {
            continuation.resume(with: result)
        }
        coreCryptoContinuations = []
    }

    func createCoreCrypto() async throws -> SafeCoreCrypto {
        let provider = CoreCryptoConfigProvider()

        let configuration = try provider.createInitialConfiguration(
            sharedContainerURL: sharedContainerURL,
            userID: selfUserID,
            createKeyIfNeeded: allowCreation
        )

        let coreCrypto = try await SafeCoreCrypto(
            path: configuration.path,
            key: configuration.key
        )

        updateKeychainItemAccess()
        await migrateCryptoboxSessionsIfNeeded(with: coreCrypto)

        try await coreCrypto.perform { try await $0.proteusInit() }

        return coreCrypto
    }

    // WORKAROUND:
    // Problem: Core Crypto stores an item in the keychain, but it doesn't provide an
    // access level. The default level is kSecAttrAccessibleWhenUnlocked. This means
    // that if Core Crypto is initialized while the phone is locked (e.g via the
    // notification extension or periodic background refresh) then it will fail due
    // to a keychain error thrown in Core Crypto.
    //
    // Ideal solution: Core Crypto stores the item with the appropriate access level.
    // Unfortunately it cannot do this at the moment due to Rust issues.
    //
    // Workaround: set the access level for the keychain item on our side.

    private func updateKeychainItemAccess() {
        WireLogger.coreCrypto.info("updating keychain item access")

        for account in accountsForAllItemsNeedingUpdates() {
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: "wire.com",
                kSecAttrAccount: account
            ] as CFDictionary

            let update = [
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
            ] as CFDictionary

            SecItemUpdate(query, update)
        }
    }

    private func accountsForAllItemsNeedingUpdates() -> [String] {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecReturnAttributes: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitAll
        ] as CFDictionary

        var result: AnyObject?

        guard SecItemCopyMatching(query, &result) == noErr else {
            return []
        }

        let items = result as? [[String: Any]] ?? []

        return items.compactMap { item in
            item[kSecAttrAccount as String] as? String
        }.filter { account in
            // Core Crypto says that the items are all prefixed with this.
            account.hasPrefix("keystore_salt")
        }
    }

    private func generateClientPublicKeysIfNeeded(with coreCrypto: CoreCryptoProtocol) async throws {
        let mlsPublicKeys = await syncContext.perform {
            ZMUser.selfUser(in: self.syncContext).selfClient()?.mlsPublicKeys
        }

        guard mlsPublicKeys?.ed25519 == nil else {
            return
        }

        WireLogger.mls.info("generating ed25519 public key")
        let keyBytes = try await coreCrypto.clientPublicKey(ciphersuite: CiphersuiteName.default.rawValue)
        let keyData = Data(keyBytes)
        var keys = UserClient.MLSPublicKeys()
        keys.ed25519 = keyData.base64EncodedString()

        await syncContext.perform {
            ZMUser.selfUser(in: self.syncContext).selfClient()?.mlsPublicKeys = keys
            self.syncContext.saveOrRollback()
        }
    }

    private func migrateCryptoboxSessionsIfNeeded(with coreCrypto: SafeCoreCrypto) async {
        guard cryptoboxMigrationManager.isMigrationNeeded(accountDirectory: accountDirectory) else {
            WireLogger.proteus.info("cryptobox migration is not needed")
            return
        }

        WireLogger.proteus.info("preparing for cryptobox migration...")

        do {
            try await self.cryptoboxMigrationManager.performMigration(
                accountDirectory: accountDirectory,
                coreCrypto: coreCrypto
            )
        } catch {
            WireLogger.proteus.critical("cryptobox migration failed: \(error.localizedDescription)")
            fatalError("Failed to migrate data from CryptoBox to CoreCrypto keystore, error : \(error.localizedDescription)")
        }

        WireLogger.proteus.info("cryptobox migration success")
    }

}

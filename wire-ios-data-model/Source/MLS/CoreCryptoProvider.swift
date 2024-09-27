//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - CoreCryptoProviderProtocol

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
        -> CRLsDistributionPoints?
}

// MARK: - CoreCryptoProvider

public actor CoreCryptoProvider: CoreCryptoProviderProtocol {
    // MARK: Lifecycle

    public init(
        selfUserID: UUID,
        sharedContainerURL: URL,
        accountDirectory: URL,
        syncContext: NSManagedObjectContext,
        cryptoboxMigrationManager: CryptoboxMigrationManagerInterface,
        allowCreation: Bool = true
    ) {
        self.selfUserID = selfUserID
        self.sharedContainerURL = sharedContainerURL
        self.accountDirectory = accountDirectory
        self.syncContext = syncContext
        self.allowCreation = allowCreation
        self.cryptoboxMigrationManager = cryptoboxMigrationManager
        self.featureRespository = FeatureRepository(context: syncContext)
    }

    // MARK: Public

    public func coreCrypto() async throws -> SafeCoreCryptoProtocol {
        try await getCoreCrypto()
    }

    public func initialiseMLSWithBasicCredentials(mlsClientID: MLSClientID) async throws {
        WireLogger.mls.info("Initialising MLS client with basic credentials")
        let defaultCiphersuite = await featureRespository.fetchMLS().config.defaultCipherSuite
        _ = try await coreCrypto().perform { coreCrypto in
            try await coreCrypto.mlsInit(
                clientId: Data(mlsClientID.rawValue.utf8),
                ciphersuites: [UInt16(defaultCiphersuite.rawValue)],
                nbKeyPackage: nil
            )
            try await generateClientPublicKeys(with: coreCrypto, credentialType: .basic)
        }
    }

    public func initialiseMLSWithEndToEndIdentity(
        enrollment: E2eiEnrollment,
        certificateChain: String
    ) async throws -> CRLsDistributionPoints? {
        WireLogger.mls.info("Initialising MLS client from end-to-end identity enrollment")
        return try await coreCrypto().perform { coreCrypto in
            let crlsDistributionPoints = try await coreCrypto.e2eiMlsInitOnly(
                enrollment: enrollment,
                certificateChain: certificateChain,
                nbKeyPackage: nil
            )
            try await generateClientPublicKeys(with: coreCrypto, credentialType: .x509)
            return CRLsDistributionPoints(from: crlsDistributionPoints)
        }
    }

    // MARK: Internal

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

        try await configureProteusClient(coreCrypto: coreCrypto)
        try await configureMLSClient(coreCrypto: coreCrypto)

        return coreCrypto
    }

    // MARK: Private

    private let selfUserID: UUID
    private let sharedContainerURL: URL
    private let accountDirectory: URL
    private let cryptoboxMigrationManager: CryptoboxMigrationManagerInterface
    private let featureRespository: FeatureRepositoryInterface
    private let syncContext: NSManagedObjectContext
    private let allowCreation: Bool
    private var coreCrypto: SafeCoreCrypto?
    private var loadingCoreCrypto = false
    private var initialisatingMLS = false
    private var hasInitialisedMLS = false
    private var coreCryptoContinuations: [CheckedContinuation<SafeCoreCrypto, Error>] = []

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

        if let coreCrypto {
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

    private func resumeCoreCryptoContinuations(with result: Result<SafeCoreCrypto, Error>) {
        for continuation in coreCryptoContinuations {
            continuation.resume(with: result)
        }
        coreCryptoContinuations = []
    }

    private func configureProteusClient(coreCrypto: SafeCoreCrypto) async throws {
        try await coreCrypto.perform { try await $0.proteusInit() }
    }

    private func configureMLSClient(coreCrypto: SafeCoreCrypto) async throws {
        let mlsClientID: MLSClientID? = await syncContext.perform {
            guard
                let selfClient = ZMUser.selfUser(in: self.syncContext).selfClient(),
                selfClient.hasRegisteredMLSClient
            else {
                return nil
            }
            return MLSClientID(userClient: selfClient)
        }

        // Initialise MLS if we have previously registered an MLS client
        if let mlsClientID {
            let cipherSuite = await UInt16(featureRespository.fetchMLS().config.defaultCipherSuite.rawValue)
            try await coreCrypto.perform { try await $0.mlsInit(
                clientId: Data(mlsClientID.rawValue.utf8),
                ciphersuites: [cipherSuite],
                nbKeyPackage: nil
            ) }
        }
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
                kSecAttrAccount: account,
            ] as CFDictionary

            let update = [
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            ] as CFDictionary

            SecItemUpdate(query, update)
        }
    }

    private func accountsForAllItemsNeedingUpdates() -> [String] {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecReturnAttributes: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitAll,
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

    private func generateClientPublicKeys(
        with coreCrypto: CoreCryptoProtocol,
        credentialType: MlsCredentialType
    ) async throws {
        WireLogger.mls.info("generating public key")
        let ciphersuite = await featureRespository.fetchMLS().config.defaultCipherSuite
        let keyBytes = try await coreCrypto.clientPublicKey(
            ciphersuite: UInt16(ciphersuite.rawValue),
            credentialType: credentialType
        )
        let keyData = Data(keyBytes)
        var keys = UserClient.MLSPublicKeys()

        switch ciphersuite {
        case .MLS_128_DHKEMP256_AES128GCM_SHA256_P256:
            keys.p256 = keyData.base64EncodedString()
        case .MLS_256_DHKEMP384_AES256GCM_SHA384_P384:
            keys.p384 = keyData.base64EncodedString()
        case .MLS_256_DHKEMP521_AES256GCM_SHA512_P521:
            keys.p521 = keyData.base64EncodedString()
        case .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448,
             .MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448:
            keys.ed448 = keyData.base64EncodedString()
        case .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
             .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519:
            keys.ed25519 = keyData.base64EncodedString()
        }

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
            try await cryptoboxMigrationManager.performMigration(
                accountDirectory: accountDirectory,
                coreCrypto: coreCrypto
            )
        } catch {
            WireLogger.proteus.critical("cryptobox migration failed: \(error.localizedDescription)")
            fatalError(
                "Failed to migrate data from CryptoBox to CoreCrypto keystore, error : \(error.localizedDescription)"
            )
        }

        WireLogger.proteus.info("cryptobox migration success")
    }
}

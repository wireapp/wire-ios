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

// sourcery: AutoMockable
public protocol CoreCryptoProviderProtocol {

    func coreCrypto(requireMLS: Bool) throws -> SafeCoreCryptoProtocol

}

public class CoreCryptoProvider: CoreCryptoProviderProtocol {
    private let selfUserID: UUID
    private let sharedContainerURL: URL
    private let accountDirectory: URL
    private let cryptoboxMigrationManager: CryptoboxMigrationManagerInterface
    private let syncContext: NSManagedObjectContext
    private let allowCreation: Bool
    private let lock = NSLock()
    private var coreCrypto: SafeCoreCrypto?

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

    // NOTE: this will turn async when we upgrade CC
    public func coreCrypto(requireMLS: Bool = false) throws -> SafeCoreCryptoProtocol {
        // TODO: this lock should go away when this function turn async and the class can become an actor
        return try lock.withLock {
            let coreCrypto = if let coreCrypto = coreCrypto {
                coreCrypto
            } else {
                try createCoreCrypto()
            }

            self.coreCrypto = coreCrypto

            if requireMLS {
                let provider = CoreCryptoConfigProvider()
                let clientID = try provider.clientID(of: .selfUser(in: syncContext))
                try coreCrypto.mlsInit(clientID: clientID)
                try generateClientPublicKeysIfNeeded(with: coreCrypto)
            }

            return coreCrypto
        }
    }

    func createCoreCrypto() throws -> SafeCoreCrypto {
        let provider = CoreCryptoConfigProvider()

        let configuration = try provider.createInitialConfiguration(
            sharedContainerURL: sharedContainerURL,
            userID: selfUserID,
            createKeyIfNeeded: allowCreation
        )

        let coreCrypto = try SafeCoreCrypto(
            path: configuration.path,
            key: configuration.key
        )

        updateKeychainItemAccess()
        migrateCryptoboxSessionsIfNeeded(with: coreCrypto)

        try coreCrypto.perform { try $0.proteusInit() }

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

    private func generateClientPublicKeysIfNeeded(with coreCrypto: SafeCoreCrypto) throws {
        let mlsPublicKeys = syncContext.performAndWait {
            ZMUser.selfUser(in: self.syncContext).selfClient()?.mlsPublicKeys
        }

        guard mlsPublicKeys?.ed25519 == nil else {
            return
        }

        WireLogger.mls.info("generating ed25519 public key")
        let keyBytes = try coreCrypto.perform { try $0.clientPublicKey(ciphersuite: defaultCipherSuite.rawValue) }
        let keyData = Data(keyBytes)
        var keys = UserClient.MLSPublicKeys()
        keys.ed25519 = keyData.base64EncodedString()

        syncContext.performAndWait {
            ZMUser.selfUser(in: self.syncContext).selfClient()?.mlsPublicKeys = keys
            self.syncContext.saveOrRollback()
        }
    }

    private func migrateCryptoboxSessionsIfNeeded(with coreCrypto: SafeCoreCrypto) {
        guard cryptoboxMigrationManager.isMigrationNeeded(accountDirectory: accountDirectory) else {
            WireLogger.proteus.info("cryptobox migration is not needed")
            return
        }

        WireLogger.proteus.info("preparing for cryptobox migration...")

        do {
            try self.cryptoboxMigrationManager.performMigration(
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

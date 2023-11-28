//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireDataModel
import WireRequestStrategy
import WireCoreCrypto

extension ZMUserSession {

//    enum CryptoStackSetupStage {
//        case proteus(userID: UUID)
//        case mls
//    }
//
//    func setupCryptoStack(stage: CryptoStackSetupStage) {
//        guard shouldSetupCryptoStack else {
//            WireLogger.coreCrypto.info("not setting up core crypto stack because it is not needed")
//            return
//        }
//
//        switch stage {
//        case .proteus(let userID) where shouldSetupProteus:
//            setupProteus(userID: userID)
//        case .mls where shouldSetupMLSService:
//            setupMLS()
//        default:
//            break
//        }
//    }
//
//    private func setupProteus(userID: UUID) {
//        syncContext.performAndWait {
//            let provider = CoreCryptoConfigProvider()
//
//            do {
//                let configuration = try provider.createInitialConfiguration(
//                    sharedContainerURL: sharedContainerURL,
//                    userID: userID,
//                    createKeyIfNeeded: true
//                )
//
//                let coreCrypto = try SafeCoreCrypto(
//                    path: configuration.path,
//                    key: configuration.key
//                )
//
//                updateKeychainItemAccess()
//                syncContext.coreCrypto = coreCrypto
//                createProteusServiceIfNeeded(coreCrypto: coreCrypto)
//                migrateCryptoboxSessionsIfNeeded()
//
//                WireLogger.coreCrypto.info("success: setup crypto stack (proteus)")
//            } catch {
//                WireLogger.coreCrypto.error("fail: setup crypto stack (proteus): \(String(describing: error))")
//            }
//        }
//    }
//
//    // WORKAROUND:
//    // Problem: Core Crypto stores an item in the keychain, but it doesn't provide an
//    // access level. The default level is kSecAttrAccessibleWhenUnlocked. This means
//    // that if Core Crypto is initialized while the phone is locked (e.g via the
//    // notification extension or periodic background refresh) then it will fail due
//    // to a keychain error thrown in Core Crypto.
//    //
//    // Ideal solution: Core Crypto stores the item with the appropriate access level.
//    // Unfortunately it cannot do this at the moment due to Rust issues.
//    //
//    // Workaround: set the access level for the keychain item on our side.
//
//    private func updateKeychainItemAccess() {
//        WireLogger.coreCrypto.info("updating keychain item access")
//
//        for account in accountsForAllItemsNeedingUpdates() {
//            let query = [
//                kSecClass: kSecClassGenericPassword,
//                kSecAttrService: "wire.com",
//                kSecAttrAccount: account
//            ] as CFDictionary
//
//            let update = [
//                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
//            ] as CFDictionary
//
//            SecItemUpdate(query, update)
//        }
//    }
//
//    private func accountsForAllItemsNeedingUpdates() -> [String] {
//        let query = [
//            kSecClass: kSecClassGenericPassword,
//            kSecReturnAttributes: kCFBooleanTrue!,
//            kSecMatchLimit: kSecMatchLimitAll
//        ] as CFDictionary
//
//        var result: AnyObject?
//
//        guard SecItemCopyMatching(query, &result) == noErr else {
//            return []
//        }
//
//        let items = result as? [[String: Any]] ?? []
//
//        return items.compactMap { item in
//            item[kSecAttrAccount as String] as? String
//        }.filter { account in
//            // Core Crypto says that the items are all prefixed with this.
//            account.hasPrefix("keystore_salt")
//        }
//    }
//
//    private func setupMLS() {
//        syncContext.performAndWait {
//            let provider = CoreCryptoConfigProvider()
//
//            do {
//                let clientID = try provider.clientID(of: .selfUser(in: syncContext))
//
//                if let coreCrypto = syncContext.coreCrypto {
//                    try coreCrypto.mlsInit(clientID: clientID)
//                } else {
//                    try createCoreCryptoForMLS(with: provider)
//                }
//
//                guard let coreCrypto = syncContext.coreCrypto else {
//                    throw CryptoStackSetupError.missingCoreCrypto
//                }
//
//                try createMLSServiceIfNeeded(coreCrypto: coreCrypto, clientID: clientID)
//
//                WireLogger.coreCrypto.info("success: setup crypto stack (mls)")
//            } catch let error as MLSServiceSetupFailure {
//                WireLogger.coreCrypto.error("fail: setup mlsService: \(String(describing: error))")
//            } catch {
//                WireLogger.coreCrypto.error("fail: setup crypto stack (mls): \(String(describing: error))")
//            }
//        }
//    }
//
//    private func createCoreCryptoForMLS(with provider: CoreCryptoConfigProvider) throws {
//        let config = try provider.createFullConfiguration(
//            sharedContainerURL: sharedContainerURL,
//            selfUser: .selfUser(in: syncContext),
//            createKeyIfNeeded: true
//        )
//
//        syncContext.coreCrypto = try SafeCoreCrypto(coreCryptoConfiguration: config)
//    }
//
//    private enum CryptoStackSetupError: Error {
//        case missingCoreCrypto
//    }
//
//    private var shouldSetupCryptoStack: Bool {
//        return shouldSetupProteus || shouldSetupMLSService
//    }
//
//    // MARK: - Proteus
//
//    private func createProteusServiceIfNeeded(coreCrypto: SafeCoreCryptoProtocol) {
//        guard
//            shouldSetupProteus,
//            syncContext.proteusService == nil
//        else {
//            return
//        }
//
//        syncContext.proteusService = ProteusService(coreCrypto: coreCrypto)
//    }
//
//    private func migrateCryptoboxSessionsIfNeeded() {
//        guard cryptoboxMigrationManager.isMigrationNeeded(accountDirectory: coreDataStack.accountContainer) else {
//            WireLogger.proteus.info("cryptobox migration is not needed")
//
//            do {
//                try cryptoboxMigrationManager.completeMigration(syncContext: syncContext)
//            } catch {
//                WireLogger.proteus.critical("failed to complete migration: \(error.localizedDescription)")
//                fatalError("failed to complete proteus initialization")
//            }
//            return
//        }
//
//        WireLogger.proteus.info("preparing for cryptobox migration...")
//
//        do {
//            try self.cryptoboxMigrationManager.performMigration(
//                accountDirectory: coreDataStack.accountContainer,
//                syncContext: syncContext
//            )
//        } catch {
//            WireLogger.proteus.critical("cryptobox migration failed: \(error.localizedDescription)")
//            fatalError("Failed to migrate data from CryptoBox to CoreCrypto keystore, error : \(error.localizedDescription)")
//        }
//
//        do {
//            try self.cryptoboxMigrationManager.completeMigration(syncContext: syncContext)
//        } catch {
//            fatalError("failed to complete proteus initialization")
//        }
//
//        WireLogger.proteus.info("cryptobox migration success")
//    }
//
//    private var shouldSetupProteus: Bool {
//        return DeveloperFlag.proteusViaCoreCrypto.isOn
//    }
//
//    // MARK: - MLS
//
//    private func createMLSServiceIfNeeded(
//        coreCrypto: SafeCoreCryptoProtocol,
//        clientID: String
//    ) throws {
//        guard
//            shouldSetupMLSService,
//            syncContext.mlsService == nil
//        else {
//            return
//        }
//
//        guard let syncStatus = syncStatus else {
//            throw MLSServiceSetupFailure.missingSyncStatus
//        }
//
//        guard let userDefaults = UserDefaults(suiteName: "com.wire.mls.\(clientID)") else {
//            throw MLSServiceSetupFailure.invalidUserDefaults
//        }
//
//        syncContext.mlsService = MLSService(
//            context: syncContext,
//            coreCrypto: coreCrypto,
//            conversationEventProcessor: ConversationEventProcessor(context: syncContext),
//            userDefaults: userDefaults,
//            syncStatus: syncStatus
//        )
//    }
//
//    private var shouldSetupMLSService: Bool {
//        return DeveloperFlag.enableMLSSupport.isOn && (BackendInfo.apiVersion ?? .v0) >= .v5
//    }
//
//    private enum MLSServiceSetupFailure: Error {
//        case missingSyncStatus
//        case invalidUserDefaults
//    }

}

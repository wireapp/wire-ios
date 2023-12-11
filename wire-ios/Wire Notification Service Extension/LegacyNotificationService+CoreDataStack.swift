//
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
import WireDataModel

extension LegacyNotificationService {

    // MARK: Properties

    private var shouldSetupCryptoStack: Bool {
        shouldSetupProteusService || shouldSetupMLSService
    }

    private var shouldSetupProteusService: Bool {
        DeveloperFlag.proteusViaCoreCrypto.isOn
    }

    private var shouldSetupMLSService: Bool {
        DeveloperFlag.enableMLSSupport.isOn && (BackendInfo.apiVersion ?? .v0) >= .v5
    }

    // MARK: - Functions

    func createCoreDataStack(applicationGroupIdentifier: String, accountIdentifier: UUID) throws -> CoreDataStack {
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        let accountManager = AccountManager(sharedDirectory: sharedContainerURL)

        guard let account = accountManager.account(with: accountIdentifier) else {
            throw LegacyNotificationServiceError.noAccount
        }

        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: sharedContainerURL
        )

        guard coreDataStack.storesExists else {
            throw LegacyNotificationServiceError.coreDataMissingSharedContainer
        }

        guard !coreDataStack.needsMigration  else {
            throw LegacyNotificationServiceError.coreDataMigrationRequired
        }

        let dispatchGroup = DispatchGroup()
        var loadStoresError: Error?

        dispatchGroup.enter()
        coreDataStack.loadStores { error in
            loadStoresError = error

            if let error = error {
                WireLogger.notifications.error("Loading coreDataStack with error: \(error.localizedDescription)")
            }

            dispatchGroup.leave()
        }
        let timeoutResult = dispatchGroup.wait(timeout: .now() + .seconds(5))

        if loadStoresError != nil || timeoutResult == .timedOut {
            throw LegacyNotificationServiceError.coreDataLoadStoresFailed
        }

        return coreDataStack
    }

    func setUpCoreCryptoStack(
        using coreDataStack: CoreDataStack,
        cryptoboxMigrationManager: CryptoboxMigrationManagerInterface = CryptoboxMigrationManager()
    ) throws {
        guard !cryptoboxMigrationManager.isMigrationNeeded(accountDirectory: coreDataStack.accountContainer) else {
            throw LegacyNotificationServiceError.cryptoboxHasPendingMigration
        }

        guard shouldSetupCryptoStack else {
            WireLogger.coreCrypto.info("not setting up core crypto stack because it is not needed")
            return
        }

        coreDataStack.syncContext.performAndWait {
            let provider = CoreCryptoConfigProvider()

            do {
                let configuration = try provider.createFullConfiguration(
                    sharedContainerURL: coreDataStack.applicationContainer,
                    selfUser: .selfUser(in: coreDataStack.syncContext),
                    createKeyIfNeeded: false
                )

                let safeCoreCrypto = try SafeCoreCrypto(coreCryptoConfiguration: configuration)

                coreDataStack.syncContext.coreCrypto = safeCoreCrypto

                if DeveloperFlag.proteusViaCoreCrypto.isOn, coreDataStack.syncContext.proteusService == nil {
                    coreDataStack.syncContext.proteusService = ProteusService(coreCrypto: safeCoreCrypto)
                }

                if DeveloperFlag.enableMLSSupport.isOn, coreDataStack.syncContext.mlsDecryptionService == nil {
                    coreDataStack.syncContext.mlsDecryptionService = MLSDecryptionService(
                        context: coreDataStack.syncContext,
                        coreCrypto: safeCoreCrypto
                    )
                }

                WireLogger.coreCrypto.info("success: setup crypto stack")
            } catch {
                WireLogger.coreCrypto.error("fail: setup crypto stack: \(String(describing: error))")
            }
        }

        coreDataStack.syncContext.performAndWait {
            try? cryptoboxMigrationManager.completeMigration(syncContext: coreDataStack.syncContext)
        }
    }
}

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

import CoreData
import WireDataModel

extension LegacyNotificationService {

    private enum Constant {
        static let loadStoreMaxWaitingTimeInSeconds: Int = 5
    }

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

        guard !coreDataStack.needsMigration else {
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
        let timeoutResult = dispatchGroup.wait(timeout: .now() + .seconds(Constant.loadStoreMaxWaitingTimeInSeconds))

        if loadStoresError != nil || timeoutResult == .timedOut {
            throw LegacyNotificationServiceError.coreDataLoadStoresFailed
        }

        return coreDataStack
    }
}

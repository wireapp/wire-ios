//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLogging

extension SessionManager: UserSessionEncryptionAtRestDelegate {

    func prepareForMigration(
        for account: Account,
        onReady: @escaping (NSManagedObjectContext) throws -> Void
    ) {
        let sharedContainerURL = sharedContainerURL
        let dispatchGroup = dispatchGroup

        delegate?.sessionManagerWillMigrateAccount(userSessionCanBeTornDown: { [weak self] in
            self?.tearDownBackgroundSession(for: account.userIdentifier) {
                self?.activeUserSession = nil
                Task {
                    do {
                        try await CoreDataStack.migrateLocalStorage(
                            accountIdentifier: account.userIdentifier,
                            applicationContainer: sharedContainerURL,
                            migration: onReady
                        )
                        _ = await self?.loadSession(for: account)
                    } catch {
                        WireLogger.ear.error("failed to migrate account: \(error)")
                    }
                }
            }
        })
    }

}

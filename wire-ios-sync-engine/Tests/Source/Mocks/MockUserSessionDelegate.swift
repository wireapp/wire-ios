//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

@testable import WireSyncEngine

final class MockUserSessionDelegate: NSObject, UserSessionDelegate {

    var prepareForMigrationOnReadyMockMethod: ((Account, (NSManagedObjectContext) throws -> Void) throws -> Void)?
    var prepareForMigration_Invocations = [Account]()
    func prepareForMigration(
        for account: WireDataModel.Account,
        onReady: @escaping (NSManagedObjectContext) throws -> Void
    ) {
        try? prepareForMigrationOnReadyMockMethod?(account, onReady)
        prepareForMigration_Invocations.append(account)

    }

    func userSessionDidUnlock(_ session: ZMUserSession) {}

    func clientRegistrationDidSucceed(accountId: UUID) {}

    func clientRegistrationDidFail(_ error: NSError, accountId: UUID) {}

    func clientCompletedInitialSync(accountId: UUID) {}

    var calleduserDidLogout: (Bool, UUID)?
    func userDidLogout(accountId: UUID) {
        calleduserDidLogout = (true, accountId)
    }

    func authenticationInvalidated(_ error: NSError, accountId: UUID) {}

    func clientDidFailSyncing(error: any Error, retryHandler: @escaping () -> Void) {}

    func userSessionDidDiscoverBuildIsBlacklisted() {}

}

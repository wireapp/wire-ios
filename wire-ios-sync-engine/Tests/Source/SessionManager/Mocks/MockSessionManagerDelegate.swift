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

final class MockSessionManagerDelegate: SessionManagerDelegate {
    var onLogout: ((NSError?) -> Void)?
    var appState = "authenticated"
    var isInAuthenticatedAppState: Bool {
        return appState == "authenticated"
    }
    var isInUnathenticatedAppState: Bool {
        return appState == "unauthenticated"
    }
    func sessionManagerWillLogout(error: Error?, userSessionCanBeTornDown: (() -> Void)?) {
        onLogout?(error as NSError?)
        userSessionCanBeTornDown?()
    }

    var sessionManagerDidFailToLogin: Bool = false
    func sessionManagerDidFailToLogin(error: Error?) {
        sessionManagerDidFailToLogin = true
    }

    func sessionManagerWillOpenAccount(_ account: Account,
                                       from selectedAccount: Account?,
                                       userSessionCanBeTornDown: @escaping () -> Void) {
        userSessionCanBeTornDown()
    }

    func sessionManagerDidBlacklistCurrentVersion(reason: BlacklistReason) {
        // no op
    }

    func sessionManagerDidFailToLoadDatabase(error: Error) {
        // no op
    }

    var jailbroken = false
    func sessionManagerDidBlacklistJailbrokenDevice() {
        jailbroken = true
    }

    var userSession: ZMUserSession?
    func sessionManagerDidChangeActiveUserSession(userSession: ZMUserSession) {
        self.userSession = userSession
    }

    func sessionManagerDidReportLockChange(forSession session: UserSession) {
        // No op
    }

    var startedMigrationCalled = false
    func sessionManagerWillMigrateAccount(userSessionCanBeTornDown: @escaping () -> Void) {
        startedMigrationCalled = true
    }

    func sessionManagerDidPerformFederationMigration(activeSession: UserSession?) {
        // no op
    }

    func sessionManagerDidPerformAPIMigrations(activeSession: UserSession?) {
        // no op
    }

    public func sessionManagerAsksToRetryStart() {
        // no op
    }
}

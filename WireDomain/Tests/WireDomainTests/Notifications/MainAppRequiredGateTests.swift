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

import Foundation
import Testing
import WireSystem
@testable import WireDomain

struct MainAppRequiredGateTests {
    private let userDefaults = UserDefaults.temporary()
    private let accountID = UUID()

    private var sut: MainAppRequiredGate {
        MainAppRequiredGate(userDefaults: userDefaults)
    }

    @Test("It notifies on first main-app-required error")
    func notifiesOnFirstMainAppRequiredError() {
        #expect(sut.shouldNotify(accountID: accountID, now: Date(timeIntervalSince1970: 1000)))
    }

    @Test("It suppresses notifications within one hour")
    func suppressesNotificationsWithinOneHour() {
        let now = Date(timeIntervalSince1970: 2000)

        sut.markNotified(accountID: accountID, now: now)

        #expect(!sut.shouldNotify(accountID: accountID, now: now.addingTimeInterval(3599)))
    }

    @Test("It notifies again after one hour")
    func notifiesAgainAfterOneHour() {
        let now = Date(timeIntervalSince1970: 2000)

        sut.markNotified(accountID: accountID, now: now)

        #expect(sut.shouldNotify(accountID: accountID, now: now.addingTimeInterval(3600)))
    }

    @Test("It scopes notifications by account")
    func scopesNotificationsByAccount() {
        let now = Date(timeIntervalSince1970: 2000)
        let otherAccountID = UUID()

        sut.markNotified(accountID: accountID, now: now)

        // The marked account is suppressed, but a different account still notifies.
        #expect(!sut.shouldNotify(accountID: accountID, now: now.addingTimeInterval(3599)))
        #expect(sut.shouldNotify(accountID: otherAccountID, now: now.addingTimeInterval(3599)))
    }

    @Test("It extracts the account ID from a main-app-required error")
    func extractsAccountIDFromMainAppRequiredError() {
        let error = NSEUserScope.Failure.mainAppRequired(message: "test", accountID: accountID)

        #expect(MainAppRequiredGate.isMainAppRequiredErrorFoAccount(error) == accountID)
    }

    @Test("It ignores non main-app-required errors")
    func ignoresNonMainAppRequiredErrors() {
        let error = TestError(message: "test")

        #expect(MainAppRequiredGate.isMainAppRequiredErrorFoAccount(error) == nil)
    }
}

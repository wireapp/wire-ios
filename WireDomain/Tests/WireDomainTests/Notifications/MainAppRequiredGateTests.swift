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

import Testing
import WireSystem
@testable import WireDomain

struct MainAppRequiredGateTests {
    private let userDefaults = UserDefaults.temporary()

    private var sut: MainAppRequiredGate {
        MainAppRequiredGate(userDefaults: userDefaults)
    }

    @Test("It notifies on first main-app-required error")
    func notifiesOnFirstMainAppRequiredError() {
        let error = NSEUserScope.Failure.mainAppRequired(message: "test")

        #expect(sut.shouldNotify(error, now: Date(timeIntervalSince1970: 1000)))
    }

    @Test("It suppresses notifications within one hour")
    func suppressesNotificationsWithinOneHour() {
        let now = Date(timeIntervalSince1970: 2000)
        let error = NSEUserScope.Failure.mainAppRequired(message: "test")

        sut.markNotified(now: now)

        #expect(!sut.shouldNotify(error, now: now.addingTimeInterval(3599)))
    }

    @Test("It notifies again after one hour")
    func notifiesAgainAfterOneHour() {
        let now = Date(timeIntervalSince1970: 2000)
        let error = NSEUserScope.Failure.mainAppRequired(message: "test")

        sut.markNotified(now: now)

        #expect(sut.shouldNotify(error, now: now.addingTimeInterval(3600)))
    }

    @Test("It ignores non main-app-required errors")
    func ignoresNonMainAppRequiredErrors() {
        let error = TestError(message: "test")

        #expect(!sut.shouldNotify(error, now: Date(timeIntervalSince1970: 1000)))
    }
}

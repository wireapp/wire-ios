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

import WireSystem
import XCTest
@testable import WireDomain

final class MainAppRequiredGateTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var sut: MainAppRequiredGate!

    override func setUp() {
        super.setUp()
        userDefaults = .temporary()
        sut = MainAppRequiredGate(userDefaults: userDefaults)
    }

    override func tearDown() {
        sut = nil
        userDefaults = nil
        super.tearDown()
    }

    func test_shouldNotify_whenNoPreviousNotification_returnsTrue() {
        XCTAssertTrue(sut.shouldNotify(now: Date(timeIntervalSince1970: 1000)))
    }

    func test_shouldNotify_withinOneHourOfPreviousNotification_returnsFalse() {
        let now = Date(timeIntervalSince1970: 2000)
        sut.markNotified(now: now)

        XCTAssertFalse(sut.shouldNotify(now: now.addingTimeInterval(3599)))
    }

    func test_shouldNotify_afterOneHourOfPreviousNotification_returnsTrue() {
        let now = Date(timeIntervalSince1970: 2000)
        sut.markNotified(now: now)

        XCTAssertTrue(sut.shouldNotify(now: now.addingTimeInterval(3600)))
    }

    func test_isMainAppRequiredError_withMatchingError_returnsTrue() {
        let error = NSEUserScope.Failure.mainAppRequired(message: "test")

        XCTAssertTrue(MainAppRequiredGate.isMainAppRequiredError(error))
    }

    func test_isMainAppRequiredError_withNonMatchingError_returnsFalse() {
        let error = TestError(message: "test")

        XCTAssertFalse(MainAppRequiredGate.isMainAppRequiredError(error))
    }

    func test_shouldNotify_withMatchingErrorAndNoPreviousNotification_returnsTrue() {
        let error = NSEUserScope.Failure.mainAppRequired(message: "test")

        XCTAssertTrue(sut.shouldNotify(error, now: Date(timeIntervalSince1970: 1000)))
    }

    func test_shouldNotify_withNonMatchingError_returnsFalse() {
        let error = TestError(message: "test")

        XCTAssertFalse(sut.shouldNotify(error, now: Date(timeIntervalSince1970: 1000)))
    }
}

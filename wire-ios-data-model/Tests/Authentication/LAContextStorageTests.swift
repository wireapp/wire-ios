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

import LocalAuthentication
@testable import WireDataModel
import XCTest

final class LAContextStorageTests: XCTestCase {

    func testContext_givenInit_thenContextIsNil() {
        // given
        let storage = LAContextStorage()

        // when
        // then
        XCTAssertNil(storage.context)
    }

    func testContext_givenOneValue_thenContextIsValue() {
        // given
        let context = LAContext()
        let storage = LAContextStorage()

        // when
        storage.context = context

        // then
        XCTAssert(storage.context === context)
    }

    func testContext_givenMutipleValue_thenContextIsLastValue() {
        // given
        let context1 = LAContext()
        let context2 = LAContext()
        let storage = LAContextStorage()

        // when
        storage.context = context1
        storage.context = context2

        // then
        XCTAssert(storage.context === context2)
    }

    func testClear_givenSomeContext_thenContextIsNil() {
        // given
        let storage = LAContextStorage()
        storage.context = LAContext()

        // when
        storage.clear()

        // then
        XCTAssertNil(storage.context)
    }

    func testContext_givenNotificationDidEnterBackground_thenContextIsNil() {
        // given
        let notificationCenter = NotificationCenter()

        let storage = LAContextStorage(notificationCenter: notificationCenter)
        storage.context = LAContext()

        // when
        notificationCenter.post(.init(name: UIApplication.didEnterBackgroundNotification))

        // then
        XCTAssertNil(storage.context)
    }
}

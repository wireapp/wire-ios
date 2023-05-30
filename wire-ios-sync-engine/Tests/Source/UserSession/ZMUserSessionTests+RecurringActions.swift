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
import XCTest
@testable import WireSyncEngine

class ZMUserSessionTests_RecurringActions: ZMUserSessionTestsBase {

    var mockRecurringActionService: MockRecurringActionService!

    override func setUp() {
        super.setUp()

        mockRecurringActionService = MockRecurringActionService()
    }

    override func tearDown() {
        mockRecurringActionService = nil

        super.tearDown()
    }

    func testThatItCallsPerformActionsAfterQuickSync() {
        // given
        sut.recurringActionService = mockRecurringActionService

        // when
        XCTAssertFalse(mockRecurringActionService.performActionsIsCalled)
        sut.didFinishQuickSync()

        // then
        XCTAssertTrue(mockRecurringActionService.performActionsIsCalled)
    }

    func testThatItAddsActions() {
        // given
        let action = RecurringAction(id: "11", interval: 5, perform: {})
        sut.recurringActionService = mockRecurringActionService

        // when
        XCTAssertEqual(mockRecurringActionService.actions.count, 0)
        sut.recurringActionService.registerAction(action)

        // then
        XCTAssertEqual(mockRecurringActionService.actions.count, 1)
    }
}

class RecurringActionServiceTests: ZMTBaseTest {

    var sut: RecurringActionService!
    let actionID = "11"
    var actionPerformed = false

    override func setUp() {
        super.setUp()

        sut = RecurringActionService()
    }

    override func tearDown() {
        sut = nil
        actionPerformed = false

        super.tearDown()
    }

    func testThatItPerformsAction() {
        // given
        let action = RecurringAction(id: actionID, interval: 2, perform: { self.actionPerformed = true })
        sut.registerAction(action)
        sut.persistLastActionDate(for: actionID, newDate: Date() - 20)

        // when
        sut.performActionsIfNeeded()

        // then
        XCTAssertTrue(actionPerformed)
    }

    func testThatItDoesNotPerformAction_TimeHasNotExpired() {
        // given
        let action = RecurringAction(id: actionID, interval: 25, perform: { self.actionPerformed = true })
        sut.registerAction(action)
        sut.persistLastActionDate(for: actionID, newDate: Date() - 20)

        // when
        sut.performActionsIfNeeded()

        // then
        XCTAssertFalse(actionPerformed)
    }

}

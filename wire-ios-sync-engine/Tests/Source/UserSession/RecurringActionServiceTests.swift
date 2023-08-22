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

class RecurringActionServiceTests: ZMTBaseTest {

    var sut: RecurringActionService!
    let actionID = "11"
    var actionPerformed = false

    override func setUp() {
        super.setUp()

        sut = RecurringActionService()
        sut.storage = UserDefaults(suiteName: "RecurringActionServiceTests")!
    }

    override func tearDown() {
        actionPerformed = false
        sut.storage.removePersistentDomain(forName: actionID)
        sut = nil

        super.tearDown()
    }

    func testThatItAddsActions() {
        // given
        let action = RecurringAction(id: actionID, interval: 5, perform: {})

        // when
        XCTAssertEqual(sut.actions.count, 0)
        sut.registerAction(action)

        // then
        XCTAssertEqual(sut.actions.count, 1)
    }

    func testThatItPerformsAction() {
        // given
        sut.persistLastCheckDate(for: actionID)
        let action = RecurringAction(id: actionID, interval: 1, perform: { self.actionPerformed = true })
        sut.registerAction(action)

        // when
        Thread.sleep(forTimeInterval: 2)
        sut.performActionsIfNeeded()

        // then
        XCTAssertTrue(actionPerformed)
    }

    func testThatItDoesNotPerformAction_TimeHasNotExpired() {
        // given
        let action = RecurringAction(id: actionID, interval: 4, perform: { self.actionPerformed = true })
        sut.registerAction(action)
        sut.persistLastCheckDate(for: actionID)

        // when
        Thread.sleep(forTimeInterval: 2)
        sut.performActionsIfNeeded()

        // then
        XCTAssertFalse(actionPerformed)
    }

}

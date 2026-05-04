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
import WireFoundationSupport
import WireTesting
import XCTest

@testable import WireSyncEngine

final class RecurringActionServiceTests: XCTestCase {

    var userDefaults: UserDefaults!
    var dateProvider: CurrentDateProvidingMock!
    var sut: RecurringActionService!

    override func setUp() {
        super.setUp()

        userDefaults = .temporary()
        dateProvider = .init()
        dateProvider.now = .now.addingTimeInterval(-.oneDay)
        sut = RecurringActionService(
            storage: userDefaults,
            dateProvider: dateProvider
        )
    }

    override func tearDown() {
        sut = nil
        dateProvider = nil
        userDefaults = nil

        super.tearDown()
    }

    func testThatItPerformsActionInitially() async {
        // Given
        var actionPerformed = false
        sut.registerAction(.init(id: .randomAlphanumerical(length: 5), interval: 1) {
            actionPerformed = true
        })

        // When
        await sut.performActionsIfNeeded()

        // Then
        XCTAssertTrue(actionPerformed)
    }

    func testThatItDoesNotPerformActionTooEarly() async {
        // Given
        var actionPerformed = false
        sut.registerAction(.init(id: .randomAlphanumerical(length: 5), interval: 3) {
            actionPerformed = true
        })

        // When
        await sut.performActionsIfNeeded()
        actionPerformed = false
        dateProvider.now += .oneSecond
        await sut.performActionsIfNeeded()

        // Then
        XCTAssertFalse(actionPerformed)
    }

    func testThatItForcePerformsAction() async {
        // given
        var actionPerformed = false
        let actionID = String.randomAlphanumerical(length: 5)

        sut.persistLastCheckDate(for: actionID)
        sut.registerAction(.init(id: actionID, interval: 100) {
            actionPerformed = true
        })

        XCTAssertFalse(actionPerformed)

        // when
        await sut.forcePerformAction(id: actionID)

        // then
        XCTAssertTrue(actionPerformed)
    }

    func testThatItPerformsActionAgain() async {
        // Given
        var actionPerformed = false
        sut.registerAction(.init(id: .randomAlphanumerical(length: 5), interval: 3) {
            actionPerformed = true
        })

        // When
        await sut.performActionsIfNeeded()
        actionPerformed = false
        dateProvider.now += .tenSeconds
        await sut.performActionsIfNeeded()

        // Then
        XCTAssertTrue(actionPerformed)
    }
}

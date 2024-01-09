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
import WireTesting
import XCTest

@testable import WireSyncEngine

final class RecurringActionServiceTests: XCTestCase {

    var suiteName: String!
    var dateProvider: MockDateProvider!
    var sut: RecurringActionService!

    override func setUp() {
        super.setUp()

        suiteName = String(describing: RecurringActionServiceTests.self) + "." + .random(length: 5)
        dateProvider = .init(now: .now)
        sut = RecurringActionService(
            storage: .init(suiteName: suiteName)!,
            dateProvider: dateProvider
        )
    }

    override func tearDown() {
        sut = nil
        dateProvider = nil
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        suiteName = nil

        super.tearDown()
    }

    func testThatItPerformsActionInitially() {
        // Given
        var actionPerformed = false
        sut.registerAction(.init(id: .random(length: 5), interval: 1) {
            actionPerformed = true
        })

        // When
        sut.performActionsIfNeeded()

        // Then
        XCTAssertTrue(actionPerformed)
    }

    func testThatItDoesNotPerformActionTooEarly() {
        // Given
        var actionPerformed = false
        sut.registerAction(.init(id: .random(length: 5), interval: 3) {
            actionPerformed = true
        })

        // When
        sut.performActionsIfNeeded()
        actionPerformed = false
        dateProvider.now += .oneSecond
        sut.performActionsIfNeeded()

        // Then
        XCTAssertFalse(actionPerformed)
    }

    func testThatItPerformsActionAgain() {
        // Given
        var actionPerformed = false
        sut.registerAction(.init(id: .random(length: 5), interval: 3) {
            actionPerformed = true
        })

        // When
        sut.performActionsIfNeeded()
        actionPerformed = false
        dateProvider.now += .tenSeconds
        sut.performActionsIfNeeded()

        // Then
        XCTAssertTrue(actionPerformed)
    }
}

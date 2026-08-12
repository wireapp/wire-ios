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

    let userID = UUID()
    var userDefaults: UserDefaults!
    var dateProvider: CurrentDateProvidingMock!
    var sut: RecurringActionService!

    override func setUp() {
        super.setUp()
        userDefaults = .temporary()
        dateProvider = .init()
        dateProvider.now = .now.addingTimeInterval(-.oneDay)
        sut = RecurringActionService(
            userID: userID,
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
        sut.registerAction(
            .init(
                id: .randomAlphanumerical(length: 5),
                shouldRunEveryLaunch: false,
                interval: 1,
                perform: { actionPerformed = true }
            )
        )

        // When
        await sut.performActionsIfNeeded()

        // Then
        XCTAssertTrue(actionPerformed)
    }

    func testThatItDoesNotPerformActionTooEarly() async {
        // Given
        var actionPerformed = false
        sut.registerAction(
            .init(
                id: .randomAlphanumerical(length: 5),
                shouldRunEveryLaunch: false,
                interval: 3,
                perform: { actionPerformed = true }
            )
        )

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
        sut.registerAction(
            .init(
                id: actionID,
                shouldRunEveryLaunch: false,
                interval: 100,
                perform: { actionPerformed = true }
            )
        )

        XCTAssertFalse(actionPerformed)

        // when
        await sut.forcePerformAction(id: actionID)

        // then
        XCTAssertTrue(actionPerformed)
    }

    func testThatItPerformsActionAgain() async {
        // Given
        var actionPerformed = false
        sut.registerAction(
            .init(
                id: .randomAlphanumerical(length: 5),
                shouldRunEveryLaunch: false,
                interval: 3,
                perform: { actionPerformed = true }
            )
        )

        // When
        await sut.performActionsIfNeeded()
        actionPerformed = false
        dateProvider.now += .tenSeconds
        await sut.performActionsIfNeeded()

        // Then
        XCTAssertTrue(actionPerformed)
    }

    // MARK: - Run Every Launch Tests

    func testThatItPerformsRunEveryLaunchActionImmediately() async {
        // Given
        var actionPerformed = false
        sut.registerAction(
            .init(
                id: .randomAlphanumerical(length: 5),
                shouldRunEveryLaunch: true,
                interval: .oneDay,
                perform: { actionPerformed = true }
            )
        )

        // When
        await sut.performActionsIfNeeded()

        // Then
        XCTAssertTrue(actionPerformed)
    }

    func testThatItPerformsRunEveryLaunchActionOnlyOnceUntilIntervalPasses() async {
        // Given
        var actionPerformedCount = 0
        let actionID = String.randomAlphanumerical(length: 5)
        sut.registerAction(
            .init(
                id: actionID,
                shouldRunEveryLaunch: true,
                interval: .oneDay,
                perform: { actionPerformedCount += 1 }
            )
        )

        // When - First launch (should run immediately)
        await sut.performActionsIfNeeded()

        // Then
        XCTAssertEqual(actionPerformedCount, 1)

        // When - Run again immediately (should not run)
        await sut.performActionsIfNeeded()

        // Then
        XCTAssertEqual(actionPerformedCount, 1)

        // When - Advance time but not past interval (should not run)
        dateProvider.now += .oneHour
        await sut.performActionsIfNeeded()

        // Then
        XCTAssertEqual(actionPerformedCount, 1)

        // When - Advance time past interval (should run)
        dateProvider.now += .oneDay
        await sut.performActionsIfNeeded()

        // Then
        XCTAssertEqual(actionPerformedCount, 2)
    }

    func testThatRunEveryLaunchActionRunsAgainAfterReinitialization() async {
        // Given
        var actionPerformedCount = 0
        let actionID = String.randomAlphanumerical(length: 5)
        sut.registerAction(
            .init(
                id: actionID,
                shouldRunEveryLaunch: true,
                interval: .oneDay,
                perform: { actionPerformedCount += 1 }
            )
        )

        // When - First launch
        await sut.performActionsIfNeeded()

        // Then
        XCTAssertEqual(actionPerformedCount, 1)

        // When - Simulate relaunch by creating new service instance
        let newSut = RecurringActionService(
            userID: userID, // Same user id
            storage: userDefaults,
            dateProvider: dateProvider
        )
        newSut.registerAction(
            .init(
                id: actionID,
                shouldRunEveryLaunch: true,
                interval: .oneDay,
                perform: { actionPerformedCount += 1 }
            )
        )
        await newSut.performActionsIfNeeded()

        // Then - Should run again on relaunch even though interval hasn't passed
        XCTAssertEqual(actionPerformedCount, 2)
    }

    // MARK: - User Scoping Tests

    func testThatRecurringActionChecksAreScopedToUserID() async {
        // Given
        let actionID = String.randomAlphanumerical(length: 5)
        let userID1 = UUID()
        let userID2 = UUID()
        var user1ActionPerformedCount = 0
        var user2ActionPerformedCount = 0

        let service1 = RecurringActionService(
            userID: userID1,
            storage: userDefaults,
            dateProvider: dateProvider
        )
        let service2 = RecurringActionService(
            userID: userID2,
            storage: userDefaults,
            dateProvider: dateProvider
        )

        service1.registerAction(
            .init(
                id: actionID,
                shouldRunEveryLaunch: false,
                interval: .oneDay,
                perform: { user1ActionPerformedCount += 1 }
            )
        )
        service2.registerAction(
            .init(
                id: actionID,
                shouldRunEveryLaunch: false,
                interval: .oneDay,
                perform: { user2ActionPerformedCount += 1 }
            )
        )

        // When - User 1 performs action
        await service1.performActionsIfNeeded()

        // Then - Only user 1's action performed
        XCTAssertEqual(user1ActionPerformedCount, 1)
        XCTAssertEqual(user2ActionPerformedCount, 0)

        // When - User 2 performs action
        await service2.performActionsIfNeeded()

        // Then - User 2's action also performed (not blocked by user 1's action)
        XCTAssertEqual(user1ActionPerformedCount, 1)
        XCTAssertEqual(user2ActionPerformedCount, 1)
    }

    func testThatOncePerLaunchActionsAreScopedToUserID() async {
        // Given
        let actionID = String.randomAlphanumerical(length: 5)
        let userID1 = UUID()
        let userID2 = UUID()
        var user1ActionPerformedCount = 0
        var user2ActionPerformedCount = 0

        let service1 = RecurringActionService(
            userID: userID1,
            storage: userDefaults,
            dateProvider: dateProvider
        )
        let service2 = RecurringActionService(
            userID: userID2,
            storage: userDefaults,
            dateProvider: dateProvider
        )

        service1.registerAction(
            .init(
                id: actionID,
                shouldRunEveryLaunch: true,
                interval: .oneDay,
                perform: { user1ActionPerformedCount += 1 }
            )
        )
        service2.registerAction(
            .init(
                id: actionID,
                shouldRunEveryLaunch: true,
                interval: .oneDay,
                perform: { user2ActionPerformedCount += 1 }
            )
        )

        // When - Both users perform actions
        await service1.performActionsIfNeeded()
        await service2.performActionsIfNeeded()

        // Then - Both actions performed independently
        XCTAssertEqual(user1ActionPerformedCount, 1)
        XCTAssertEqual(user2ActionPerformedCount, 1)

        // When - Both try again immediately
        await service1.performActionsIfNeeded()
        await service2.performActionsIfNeeded()

        // Then - Neither action performed again (interval not passed)
        XCTAssertEqual(user1ActionPerformedCount, 1)
        XCTAssertEqual(user2ActionPerformedCount, 1)

        // When - Simulate relaunch for both users
        let newService1 = RecurringActionService(
            userID: userID1,
            storage: userDefaults,
            dateProvider: dateProvider
        )
        let newService2 = RecurringActionService(
            userID: userID2,
            storage: userDefaults,
            dateProvider: dateProvider
        )

        newService1.registerAction(
            .init(
                id: actionID,
                shouldRunEveryLaunch: true,
                interval: .oneDay,
                perform: { user1ActionPerformedCount += 1 }
            )
        )
        newService2.registerAction(
            .init(
                id: actionID,
                shouldRunEveryLaunch: true,
                interval: .oneDay,
                perform: { user2ActionPerformedCount += 1 }
            )
        )

        await newService1.performActionsIfNeeded()
        await newService2.performActionsIfNeeded()

        // Then - Both actions run again on relaunch
        XCTAssertEqual(user1ActionPerformedCount, 2)
        XCTAssertEqual(user2ActionPerformedCount, 2)
    }
}

//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireDataModelSupport
import XCTest

@testable import WireRequestStrategy
@testable import WireSyncEngine

final class ZMUserSessionTests_Syncing: ZMUserSessionTestsBase {

    // The mock in this place is a workaround, because somewhere down the line the test funcs call
    // `func startQuickSync()` and this calls `PushSupportedProtocolsAction`.
    // A proper solution and mocking requires a further refactoring.
    private var mockPushSupportedProtocolsActionHandler: MockActionHandler<PushSupportedProtocolsAction>!

    override func setUp() {
        super.setUp()

        mockMLSService.repairOutOfSyncConversations_MockMethod = {}

        mockPushSupportedProtocolsActionHandler = .init(
            result: .success(()),
            context: syncMOC.notificationContext
        )
    }

    override func tearDown() {
        mockPushSupportedProtocolsActionHandler = nil

        super.tearDown()
    }

    // MARK: Helpers

    func startQuickSync() {
        sut.didStartIncrementalSync()
    }

    func finishQuickSync() {
        sut.didFinishIncrementalSync(isRecovering: false)
    }

    func startSlowSync() {
        sut.didStartInitialSync()
    }

    func finishSlowSync() {
        sut.didFinishInitialSync()
    }

    // MARK: Slow Sync

    func testThatObserverSystemIsDisabledDuringSlowSync() {

        // given
        finishSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(sut.notificationDispatcher.isEnabled)

        // when
        syncMOC.performAndWait {
            startSlowSync()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sut.notificationDispatcher.isEnabled)
    }

    func testThatObserverSystemIsEnabledAfterSlowSync() {

        // given
        startSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertFalse(sut.notificationDispatcher.isEnabled)

        // when
        finishSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.notificationDispatcher.isEnabled)
    }

    func testThatInitialSyncIsCompletedAfterSlowSync() {

        // given
        startSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertFalse(sut.hasCompletedInitialSync)

        // when
        finishSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.hasCompletedInitialSync)
    }

    func testThatItNotifiesObserverWhenInitialIsSyncCompleted() {
        // given
        var didNotify = false

        let token = NotificationInContext.addObserver(
            name: .initialSync,
            context: uiMOC.notificationContext
        ) { _ in
            didNotify = true
        }

        startSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertFalse(didNotify)

        // when
        finishSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        withExtendedLifetime(token) {
            XCTAssertTrue(didNotify)
        }
    }

    func testThatPerformingSyncIsStillOngoingAfterSlowSync() {

        // given
        startSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(sut.isPerformingSync)

        // when
        finishSlowSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(sut.isPerformingSync)
    }

    // MARK: Quick Sync

    func testThatPerformingSyncIsFinishedAfterQuickSync() {

        // given
        startQuickSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(sut.isPerformingSync)

        // when
        finishQuickSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sut.isPerformingSync)
    }

}

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

import WireRequestStrategy
import XCTest

final class QuickSyncObserverTests: MessagingTestBase {

    func testThatSynchronisationStateIsOnline_thenDontWait() async {
        // given
        let (_, quickSyncObserver) = Arrangement(coreDataStack: coreDataStack)
            .withSynchronizationState(.online)
            .arrange()

        // then test completes
        let before = Date.now
        await quickSyncObserver.waitForQuickSyncToFinish()
        XCTAssert(Date.now.timeIntervalSince(before) < 0.5, "sync duration > 500ms")
    }

    func testThatSynchronisationStateIsNotOnline_thenWaitUntilQuickSyncCompletes() {
        // given
        let (_, quickSyncObserver) = Arrangement(coreDataStack: coreDataStack)
            .withSynchronizationState(.quickSyncing)
            .arrange()

        Task {
            // Sleeping in order to hit the code path where we start observing .quickSyncCompletedNotification
            if #available(iOS 16.0, *) {
                try? await Task.sleep(for: .seconds(0.25))
            } else {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            NotificationInContext(name: .quickSyncCompletedNotification, context: syncMOC.notificationContext).post()
        }

        // then test completes
        let expectation = XCTestExpectation(description: "sync is done within 500ms")
        Task {
            await quickSyncObserver.waitForQuickSyncToFinish()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }
}

// MARK: -

private struct Arrangement {

    let coreDataStack: CoreDataStack
    let applicationStatus = MockApplicationStatus()

    func withSynchronizationState(_ state: SynchronizationState) -> Arrangement {
        applicationStatus.mockSynchronizationState = state
        return self
    }

    func arrange() -> (Arrangement, QuickSyncObserver) {
        (
            self,
            QuickSyncObserver(
                context: coreDataStack.syncContext,
                applicationStatus: applicationStatus,
                notificationContext: coreDataStack.syncContext.notificationContext
            )
        )
    }
}

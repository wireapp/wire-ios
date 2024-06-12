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

import XCTest

final class QuickSyncObserverTests: MessagingTestBase {

    func testThatSynchronisationStateIsOnline_thenDontWait() {
        // given
        let (_, quickSyncObserver) = Arrangement(coreDataStack: coreDataStack)
            .withSynchronizationState(.online)
            .arrange()

        // then test completes
        let expectation = XCTestExpectation(description: "sync is done within 500ms")
        Task {
            await quickSyncObserver.waitForQuickSyncToFinish()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testThatSynchronisationStateIsNotOnline_thenWaitUntilQuickSyncCompletes() async throws {
        // given
        let (_, quickSyncObserver) = Arrangement(coreDataStack: coreDataStack)
            .withSynchronizationState(.quickSyncing)
            .arrange()

        try await Task.sleep(nanoseconds: 250_000_000)
        NotificationInContext(name: .quickSyncCompletedNotification, context: syncMOC.notificationContext).post()

        // then test completes
        await quickSyncObserver.waitForQuickSyncToFinish()
    }

    struct Arrangement {

        let coreDataStack: CoreDataStack
        let applicationStatus = MockApplicationStatus()

        func withSynchronizationState(_ state: SynchronizationState) -> Arrangement {
            applicationStatus.mockSynchronizationState = state
            return self
        }

        func arrange() -> (Arrangement, QuickSyncObserver) {
            return (self, QuickSyncObserver(
                context: coreDataStack.syncContext,
                applicationStatus: applicationStatus,
                notificationContext: coreDataStack.syncContext.notificationContext
                )
            )
        }
    }
}

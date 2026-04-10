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
import Testing

@testable import WireUtilitiesPackage

struct RegisterExpiringActivityTests {

    @Test
    func reasonIsForwardedToPerformer() async throws {
        // Given
        var receivedReason: String?
        let performer: ExpiringActivityPerformer = { reason, block in
            receivedReason = reason
            block(false)
        }
        let task = Task<Void, Never> {}

        // When
        registerExpiringActivity(
            performer: performer,
            reason: "sync messages",
            task: task
        )

        // Then
        #expect(receivedReason == "sync messages")
    }

    @Test
    func taskIsCancelledWhenExpiring() async throws {
        // Given
        let performer: ExpiringActivityPerformer = { _, block in
            block(true)
        }
        let task = Task<Void, Never> {
            try? await Task.sleep(for: .seconds(60))
        }

        // When
        registerExpiringActivity(
            performer: performer,
            reason: "sync",
            task: task
        )

        // Then
        #expect(task.isCancelled)
    }

    @Test
    func blockWaitsForTaskToFinishWhenNotExpiring() async throws {
        // Given
        let taskStarted = DispatchSemaphore(value: 0)
        let taskCanFinish = DispatchSemaphore(value: 0)
        var blockDidReturn = false

        let task = Task<Void, Never> {
            taskStarted.signal()
            taskCanFinish.wait()
        }

        let performer: ExpiringActivityPerformer = { _, block in
            DispatchQueue.global().async {
                block(false)
                blockDidReturn = true
            }
        }

        // When
        registerExpiringActivity(
            performer: performer,
            reason: "sync",
            task: task
        )

        // Wait for the task to actually start running.
        taskStarted.wait()

        // The block should still be waiting because the task hasn't finished.
        try await Task.sleep(for: .milliseconds(100))
        #expect(!blockDidReturn)

        // Allow the task to finish.
        taskCanFinish.signal()

        // The block should return shortly after.
        try await Task.sleep(for: .milliseconds(100))
        #expect(blockDidReturn)
    }

    @Test
    func blockReturnsEvenWhenTaskThrows() async throws {
        // Given
        struct TestError: Error {}
        var blockDidReturn = false

        let task = Task<Void, Error> {
            throw TestError()
        }

        let performer: ExpiringActivityPerformer = { _, block in
            DispatchQueue.global().async {
                block(false)
                blockDidReturn = true
            }
        }

        // When
        registerExpiringActivity(
            performer: performer,
            reason: "sync",
            task: task
        )

        // Then — block should return despite the task throwing.
        try await Task.sleep(for: .milliseconds(100))
        #expect(blockDidReturn)
    }

}

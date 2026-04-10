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

import XCTest

@testable import WireUtilitiesPackage

final class RegisterExpiringActivityTests: XCTestCase {

    func testReasonIsForwardedToPerformer() {
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
        XCTAssertEqual(receivedReason, "sync messages")
    }

    func testTaskIsCancelledWhenExpiring() {
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
        XCTAssertTrue(task.isCancelled)
    }

    func testBlockWaitsForTaskToFinishWhenNotExpiring() async throws {
        // Given
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let flag = Flag()

        let task = Task<Void, Never> {
            for await _ in stream {}
        }

        let performer: ExpiringActivityPerformer = { _, block in
            DispatchQueue.global().async {
                block(false)
                Task { await flag.set() }
            }
        }

        // When
        registerExpiringActivity(
            performer: performer,
            reason: "sync",
            task: task
        )

        // Then — the block should still be waiting because the task hasn't finished.
        try await Task.sleep(for: .milliseconds(200))
        var didReturn = await flag.value
        XCTAssertFalse(didReturn)

        // Allow the task to complete.
        continuation.finish()

        // The block should return shortly after.
        try await Task.sleep(for: .milliseconds(200))
        didReturn = await flag.value
        XCTAssertTrue(didReturn)
    }

    func testBlockReturnsEvenWhenTaskThrows() async throws {
        // Given
        struct TestError: Error {}
        let flag = Flag()

        let task = Task<Void, Error> {
            throw TestError()
        }

        let performer: ExpiringActivityPerformer = { _, block in
            DispatchQueue.global().async {
                block(false)
                Task { await flag.set() }
            }
        }

        // When
        registerExpiringActivity(
            performer: performer,
            reason: "sync",
            task: task
        )

        // Then — block should return despite the task throwing.
        try await Task.sleep(for: .milliseconds(200))
        let didReturn = await flag.value
        XCTAssertTrue(didReturn)
    }

}

// MARK: -

private actor Flag {
    var value = false
    func set() { value = true }
}

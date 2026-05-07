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
@testable import WireDomain

struct WorkerTests {

    private final class WorkCounter: Sendable {
        nonisolated(unsafe) var count = 0
    }

    private let workCounter: WorkCounter
    private var workResult: Bool
    private let continuation: AsyncStream<Void>.Continuation
    private let sut: Worker

    init() {
        let workCounter = WorkCounter()
        let (trigger, continuation) = AsyncStream.makeStream(of: Void.self)

        self.workCounter = workCounter
        self.workResult = true
        self.continuation = continuation
        self.sut = Worker(
            work: {
                workCounter.count += 1
                return true
            },
            interval: .oneHour,
            trigger: trigger
        )
    }

    // MARK: - Tests

    @Test
    func `calls work on trigger`() async {
        // Given
        continuation.yield()
        continuation.finish()

        // When
        await sut.startAndWait()

        // Then
        #expect(workCounter.count == 1)
    }

    @Test
    func `skips work when not stale`() async {
        // Given
        continuation.yield()
        continuation.yield()
        continuation.finish()

        // When
        await sut.startAndWait()

        // Then
        #expect(workCounter.count == 1)
    }

    @Test
    func `retries after failure because result remains stale`() async {
        // Given
        let workCounter = WorkCounter()
        let (trigger, continuation) = AsyncStream.makeStream(of: Void.self)
        let sut = Worker(
            work: {
                workCounter.count += 1
                return false
            },
            interval: .oneHour,
            trigger: trigger
        )

        continuation.yield()
        continuation.yield()
        continuation.finish()

        // When
        await sut.startAndWait()

        // Then
        #expect(workCounter.count == 2)
    }

    @Test
    func `records success and becomes not stale`() async {
        // Given
        continuation.yield()
        continuation.yield()
        continuation.yield()
        continuation.finish()

        // When
        await sut.startAndWait()

        // Then
        #expect(workCounter.count == 1)
    }

    @Test
    func `does not call work without trigger`() async {
        // Given
        continuation.finish()

        // When
        await sut.startAndWait()

        // Then
        // swiftformat:disable:next isEmpty
        #expect(workCounter.count == 0)
    }

}

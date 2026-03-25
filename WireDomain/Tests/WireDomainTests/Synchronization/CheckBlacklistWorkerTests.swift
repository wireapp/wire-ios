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
import WireDomainSupport
@testable import WireDomain

struct CheckBlacklistWorkerTests {

    private final class CallbackCounter: Sendable {
        nonisolated(unsafe) var count = 0
    }

    private let mockUseCase: MockIsBuildBlacklistedUseCase
    private let continuation: AsyncStream<Void>.Continuation
    private let sut: CheckBlacklistWorker
    private let callbackCounter: CallbackCounter

    init() {
        let mockUseCase = MockIsBuildBlacklistedUseCase()
        mockUseCase.invoke_MockValue = (false, nil)
        let (trigger, continuation) = AsyncStream.makeStream(of: Void.self)
        let callbackCounter = CallbackCounter()

        self.mockUseCase = mockUseCase
        self.continuation = continuation
        self.callbackCounter = callbackCounter
        self.sut = CheckBlacklistWorker(
            isBuildBlacklistedUseCase: mockUseCase,
            trigger: trigger,
            onIsBuildBlacklisted: { callbackCounter.count += 1 }
        )
    }

    // MARK: - Tests

    @Test
    func `calls use case on trigger`() async {
        // Given
        continuation.yield()
        continuation.finish()

        // When
        await sut.startAndWait()

        // Then
        #expect(mockUseCase.invoke_Invocations.count == 1)
    }

    @Test
    func `calls blacklisted callback when build is blacklisted`() async {
        // Given
        mockUseCase.invoke_MockValue = (true, nil)
        continuation.yield()
        continuation.finish()

        // When
        await sut.startAndWait()

        // Then
        #expect(callbackCounter.count == 1)
    }

    @Test
    func `does not call blacklisted callback when build is not blacklisted`() async {
        // Given
        mockUseCase.invoke_MockValue = (false, nil)
        continuation.yield()
        continuation.finish()

        // When
        await sut.startAndWait()

        // Then
        #expect(callbackCounter.isEmpty)
    }

    @Test
    func `calls blacklisted callback when build is blacklisted even if error`() async {
        // Given
        mockUseCase.invoke_MockValue = (true, URLError(.notConnectedToInternet))
        continuation.yield()
        continuation.finish()

        // When
        await sut.startAndWait()

        // Then
        #expect(callbackCounter.count == 1)
    }

    @Test
    func `skips check when not stale`() async {
        // Given
        mockUseCase.invoke_MockValue = (false, nil)
        continuation.yield()
        continuation.yield()
        continuation.finish()

        // When
        await sut.startAndWait()

        // Then
        #expect(mockUseCase.invoke_Invocations.count == 1)
    }

    @Test
    func `rechecks after error because result remains stale`() async {
        // Given
        mockUseCase.invoke_MockValue = (false, URLError(.notConnectedToInternet))
        continuation.yield()
        continuation.yield()
        continuation.finish()

        // When
        await sut.startAndWait()

        // Then
        #expect(mockUseCase.invoke_Invocations.count == 2)
    }
}

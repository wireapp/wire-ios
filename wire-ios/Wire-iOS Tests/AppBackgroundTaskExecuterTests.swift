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

import os
import Testing
import UIKit
import WireTesting

@testable import Wire

@Suite(.serialized)
struct AppBackgroundTaskExecuterTests {

    let application: MockBackgroundTaskApplication
    let sut: AppBackgroundTaskExecuter

    @MainActor
    init() {
        self.application = MockBackgroundTaskApplication()
        application.underlyingBackgroundTimeRemaining = 30
        application.beginBackgroundTaskWithNameExpirationHandler_MockMethod = { _, _ in
            UIBackgroundTaskIdentifier(rawValue: 99)
        }
        application.endBackgroundTask_MockMethod = { _ in }

        self.sut = AppBackgroundTaskExecuter(application: application, isInBackground: false)
    }

    @Test
    func `returns the operation's result`() async throws {
        // given, when
        let result = try await sut.execute(name: "task") { "result" }

        // then
        #expect(result == "result")
    }

    @Test
    func `rethrows the operation's error`() async throws {
        // then
        await #expect(throws: URLError(.unsupportedURL)) {
            // given, when
            try await sut.execute(name: "task") { throw URLError(.unsupportedURL) }
        }
    }

    @Test
    func `passes the provided name to beginBackgroundTask`() async throws {
        // given, when
        _ = try await sut.execute(name: "my-task") { () }

        // then
        let names = application.beginBackgroundTaskWithNameExpirationHandler_Invocations.map(\.taskName)
        #expect(names == ["my-task"])
    }

    @Test
    func `defaults a nil name to "unnamed"`() async throws {
        // given, when
        _ = try await sut.execute(name: nil) { () }

        // then
        let names = application.beginBackgroundTaskWithNameExpirationHandler_Invocations.map(\.taskName)
        #expect(names == ["unnamed"])
    }

    @Test
    func `ends the background task after the operation succeeds`() async throws {
        // given
        application.beginBackgroundTaskWithNameExpirationHandler_MockMethod = { _, _ in
            UIBackgroundTaskIdentifier(rawValue: 10)
        }

        // when
        _ = try await sut.execute(name: "task") { () }

        // then
        #expect(application.endBackgroundTask_Invocations == [UIBackgroundTaskIdentifier(rawValue: 10)])
    }

    @Test
    func `ends the background task even when the operation throws`() async throws {
        // given
        application.beginBackgroundTaskWithNameExpirationHandler_MockMethod = { _, _ in
            UIBackgroundTaskIdentifier(rawValue: 20)
        }

        // when
        try? await sut.execute(name: "task") { throw URLError(.unsupportedURL) }

        // then
        #expect(application.endBackgroundTask_Invocations == [UIBackgroundTaskIdentifier(rawValue: 20)])
    }

    @Test
    func `firing the expiration handler cancels the operation`() async throws {
        // given
        application.beginBackgroundTaskWithNameExpirationHandler_MockMethod = { _, _ in
            UIBackgroundTaskIdentifier(rawValue: 42)
        }

        let task = Task {
            try await sut.execute(name: "task") {
                try await Task.sleep(for: .seconds(10))
            }
        }

        // when
        await application.expireFirstBackgroundTask()

        // then
        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }
        #expect(application.endBackgroundTask_Invocations == [UIBackgroundTaskIdentifier(rawValue: 42)])
    }

    @Test
    @MainActor
    func `throws CancellationError when the app is in the background with insufficient time`() async throws {
        // given
        application.underlyingBackgroundTimeRemaining = 3
        let sut = AppBackgroundTaskExecuter(application: application, isInBackground: true)
        let didRunOperation = OSAllocatedUnfairLock(initialState: false)

        // then
        await #expect(throws: CancellationError.self) {
            // when
            try await sut.execute(name: "task") {
                didRunOperation.withLock { $0 = true }
            }
        }
        #expect(didRunOperation.withLock { $0 } == false)
        #expect(application.beginBackgroundTaskWithNameExpirationHandler_Invocations.isEmpty)
    }

    @Test
    @MainActor
    func `executes the operation when the app is in the background with sufficient time`() async throws {
        // given
        application.underlyingBackgroundTimeRemaining = 10
        let sut = AppBackgroundTaskExecuter(application: application, isInBackground: true)

        // when
        let result = try await sut.execute(name: "task") { "done" }

        // then
        #expect(result == "done")
        #expect(!application.beginBackgroundTaskWithNameExpirationHandler_Invocations.isEmpty)
    }

    @Test
    func `throws CancellationError when beginBackgroundTask returns invalid`() async throws {
        // given
        application.beginBackgroundTaskWithNameExpirationHandler_MockMethod = { _, _ in .invalid }
        let didRunOperation = OSAllocatedUnfairLock(initialState: false)

        // then
        await #expect(throws: CancellationError.self) {
            // when
            try await sut.execute(name: "task") {
                didRunOperation.withLock { $0 = true }
            }
        }
        #expect(didRunOperation.withLock { $0 } == false)
    }

    @Test
    @MainActor
    func `throws CancellationError when the expiration handler fires before the task starts`() async throws {
        // given
        let didRunOperation = OSAllocatedUnfairLock(initialState: false)
        application.beginBackgroundTaskWithNameExpirationHandler_MockMethod = { _, handler in
            handler?()
            return UIBackgroundTaskIdentifier(rawValue: 30)
        }

        // then
        await #expect(throws: CancellationError.self) {
            // when
            try await sut.execute(name: "task") {
                didRunOperation.withLock { $0 = true }
            }
        }
        #expect(didRunOperation.withLock { $0 } == false)
        #expect(application.endBackgroundTask_Invocations == [UIBackgroundTaskIdentifier(rawValue: 30)])
    }

    @Test
    func `external cancellation cancels the operation and ends the background task`() async throws {
        // given
        let didCancel = OSAllocatedUnfairLock(initialState: false)
        let task = Task {
            try await sut.execute(name: "task") {
                try await withTaskCancellationHandler {
                    try await Task.sleep(for: .seconds(10))
                } onCancel: {
                    didCancel.withLock { $0 = true }
                }
            }
        }

        // when
        task.cancel()

        // then
        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }
        #expect(didCancel.withLock { $0 } == true)
    }

}

// MARK: - Helpers

private extension MockBackgroundTaskApplication {

    func expireFirstBackgroundTask() async {
        while beginBackgroundTaskWithNameExpirationHandler_Invocations.isEmpty {
            try? await Task.sleep(for: .milliseconds(50))
        }
        await beginBackgroundTaskWithNameExpirationHandler_Invocations.first?.handler?()
    }

}

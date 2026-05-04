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

import Combine
import Testing
import WireDomain
@testable import WireSyncEngine
@testable import WireSyncEngineSupport

class IncrementalSyncObserverTests {

    private lazy var sut = IncrementalSyncObserver(
        syncAgent: syncAgent,
        notificationContext: notificationContext
    )

    private let syncAgent = MockSyncAgentProtocol()
    private let notificationContext = MockNotificationContext()

    @Test("Don't wait if app is live")
    func ifAppIsLiveThenDontWait() async {
        // Given
        syncAgent.isSyncV2Enabled = true
        let subject = PassthroughSubject<SyncState, Never>()
        syncAgent.syncStatePublisher = subject.eraseToAnyPublisher()
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000)
            subject.send(.liveSyncing(.ongoing))
        }

        // When
        let before = Date.now
        await sut.waitUntilCanSendMessage()

        // Then
        #expect(Date.now.timeIntervalSince(before) < 0.5, "sync duration > 500ms")
    }

    @Test("Don't wait if app is live (legacy)")
    func ifAppIsLiveThenDontWaitLegacy() async {
        // Given
        syncAgent.isSyncV2Enabled = false
        syncAgent.isLive = true

        // When
        let before = Date.now
        await sut.waitUntilCanSendMessage()

        // Then
        #expect(Date.now.timeIntervalSince(before) < 0.5, "sync duration > 500ms")
    }

    @Test("Wait for decryption to finish")
    func waitForDecryptionToFinish() async {
        // Given
        syncAgent.isSyncV2Enabled = true
        let syncStateSubject = CurrentValueSubject<SyncState, Never>(.incrementalSyncing(.pullPendingEvents))
        syncAgent.syncStatePublisher = syncStateSubject.eraseToAnyPublisher()

        let flag = ObserverFlag()

        Task {
            await flag.markStarted()
            await sut.waitUntilCanSendMessage()
        }

        let didStart = await flag.waitUntilStarted()
        #expect(didStart, "Observer never subscribed in time")

        Task {
            // Send the next state after a pause.
            try? await Task.sleep(for: .seconds(0.25))
            syncStateSubject.send(.incrementalSyncing(.processPendingEvents))

            // Sending the states again to ensure we don't crash due to a misuse of `continuation.resume()` as it must
            // be called only once.
            // Since we're cancelling the subscription when `DecryptionState` is `.done` `continuation.resume()` should
            // not be called again.
            syncStateSubject.send(.incrementalSyncing(.processPendingEvents))
            syncStateSubject.send(.incrementalSyncing(.processPendingEvents))
        }

        // Then
        let before = Date.now
        await confirmation("sync is done within 500ms") { confirm in
            // When
            await sut.waitUntilCanSendMessage()
            #expect(Date.now.timeIntervalSince(before) < 0.5, "sync duration > 500ms")
            confirm()
        }
    }

    @Test("Wait for decryption to finish (legacy)")
    func waitForDecryptionToFinishLegacy() async {
        // Given
        syncAgent.isSyncV2Enabled = false
        syncAgent.isLive = false

        Task {
            // Notify decryption has finished.
            try? await Task.sleep(for: .seconds(0.25))
            NotificationCenter.default.post(
                name: .didStopDecryptingEventsNotification,
                object: notificationContext
            )
        }

        // Then
        let before = Date.now
        await confirmation("sync is done within 500ms") { confirm in
            // When
            await sut.waitUntilCanSendMessage()
            #expect(Date.now.timeIntervalSince(before) < 0.5, "sync duration > 500ms")
            confirm()
        }
    }

}

// MARK: -

private class MockNotificationContext: NSObject, NotificationContext {}

private actor ObserverFlag {
    private var started = false

    func markStarted() {
        started = true
    }

    func waitUntilStarted(timeout: TimeInterval = 1.0) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !started {
            if Date() > deadline { return false }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return true
    }
}

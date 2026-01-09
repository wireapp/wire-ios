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

class QuickSyncObserverTests {

    private lazy var sut = QuickSyncObserver(
        syncAgent: syncAgent,
        notificationContext: notificationContext
    )

    private let syncAgent = MockSyncAgentProtocol()
    private let notificationContext = MockNotificationContext()

    @Test("Don't wait if app is live")
    func ifAppIsLiveThenDontWait() async {
        // Given
        syncAgent.isSyncV2Enabled = true
        syncAgent.syncStatePublisher = Just(SyncState.liveSyncing).eraseToAnyPublisher()

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

        Task {
            // Send the next state after a pause.
            try? await Task.sleep(for: .seconds(0.25))
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

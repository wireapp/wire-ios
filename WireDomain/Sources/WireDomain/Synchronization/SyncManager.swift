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

import Combine
import Foundation
import WireAPI

protocol SyncManagerProtocol {

    /// The current synchronization state.

    var syncState: SyncState { get }

    /// Fetch user data from the server and store locally.

    func performSlowSync() async throws

    /// Fetch events from the server and process all pending events.

    func performQuickSync() async throws

    /// Stop all syncing activities and prepare to idle.

    func suspend() async throws

}

// Questions / notes:
// - What happens if we call performSlowSync or performQuickSync multiple times?
// - We might need to de-duplicate buffered events to make sure we decrypt and process new events.
// - What should suspend() do if the sync state is not live?

final class SyncManager: SyncManagerProtocol {

    private(set) var syncState: SyncState = .suspended

    private let pushChannel: any PushChannelProtocol
    private var pushChannelToken: AnyCancellable?
    private(set) var bufferedEnvelopes = [UpdateEventEnvelope]()
    
    private let updateEventsRepository: any UpdateEventsRepositoryProtocol
    private let updateEventDecryptor: any UpdateEventDecryptorProtocol
    private let updateEventProcessor: any UpdateEventProcessorProtocol

    init(
        pushChannel: any PushChannelProtocol,
        updateEventsRepository: any UpdateEventsRepositoryProtocol,
        updateEventDecryptor: any UpdateEventDecryptorProtocol,
        updateEventProcessor: any UpdateEventProcessorProtocol
    ) {
        self.pushChannel = pushChannel
        self.updateEventsRepository = updateEventsRepository
        self.updateEventDecryptor = updateEventDecryptor
        self.updateEventProcessor = updateEventProcessor
    }

    func performSlowSync() async throws {
        syncState = .slowSync
        let slowSync = SlowSync()
        try await slowSync.perform()
        try await performQuickSync()
    }

    func performQuickSync() async throws {
        syncState = .quickSync

        // Divert incoming events from the event queue to the push channel,
        // they'll be buffered until we finish quick sync.
        try await openPushChannel()
        try await updateEventsRepository.pullPendingEvents()
        try await processStoredEvents()
        try await processBufferedEvents()

        syncState = .live
    }

    func suspend() async throws {
        try await closePushChannel()
        syncState = .suspended
    }

    // MARK: - Push channel

    private func closePushChannel() async throws {
        try await pushChannel.close()
        self.pushChannelToken = nil
    }

    private func openPushChannel() async throws {
        pushChannelToken = try await pushChannel.open().sink { [weak self]  in
            self?.didReceiveUpdateEventEnvelope($0)
        }
    }

    private func didReceiveUpdateEventEnvelope(_ envelope: UpdateEventEnvelope) {
        guard syncState == .live else {
            bufferedEnvelopes.append(envelope)
            return
        }

        Task {
            let events = try await decryptLiveEvents(in: envelope)
            try await processLiveEvents(events)
        }
    }

    private func decryptLiveEvents(in envelope: UpdateEventEnvelope) async throws -> [UpdateEvent] {
        do {
            return try await updateEventDecryptor.decryptEvents(in: envelope)
        } catch {
            print("failed to decrypt envelope: \(error)")
            throw error
        }
    }

    private func processLiveEvents(_ events: [UpdateEvent]) async throws {
        for event in events {
            do {
                try await updateEventProcessor.processEvent(event)
            } catch {
                print("failed to process event: \(error)")
                throw error
            }
        }
    }

    // MARK: - Event processing

    private func processStoredEvents() async throws {
        let batchSize: UInt = 500

        while true {
            let envelopes = try await updateEventsRepository.fetchNextPendingEvents(limit: batchSize)

            guard !envelopes.isEmpty else {
                break
            }

            for event in envelopes.flatMap(\.events) {
                try await updateEventProcessor.processEvent(event)
            }

            try await updateEventsRepository.deleteNextPendingEvents(limit: batchSize)
        }
    }

    private func processBufferedEvents() async throws {
        // More events may be aded to the buffering while we're processing,
        // so we process one at a time until the buffer is empty.
        while !bufferedEnvelopes.isEmpty {
            let envelope = bufferedEnvelopes.removeFirst()
            let events = try await decryptLiveEvents(in: envelope)
            try await processLiveEvents(events)
        }
    }

}

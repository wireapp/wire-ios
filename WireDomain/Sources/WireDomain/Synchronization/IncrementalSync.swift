//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireAPI
import WireLogging

public struct IncrementalSync: IncrementalSyncProtocol {

    private let selfClientID: String
    private let pushChannelAPI: any PushChannelAPI
    private let updateEventsSync: any PullPendingUpdateEventsSyncProtocol
    private let decryptor: any UpdateEventDecryptorProtocol
    private let store: any UpdateEventsLocalStoreProtocol
    private let processor: any UpdateEventProcessorProtocol
    private let logger = WireLogger.sync

    public init(
        selfClientID: String,
        pushChannelAPI: any PushChannelAPI,
        updateEventsSync: any PullPendingUpdateEventsSyncProtocol,
        decryptor: any UpdateEventDecryptorProtocol,
        store: any UpdateEventsLocalStoreProtocol,
        processor: any UpdateEventProcessorProtocol
    ) {
        self.selfClientID = selfClientID
        self.pushChannelAPI = pushChannelAPI
        self.updateEventsSync = updateEventsSync
        self.decryptor = decryptor
        self.store = store
        self.processor = processor
    }

    public func perform() async throws -> Token {
        logger.debug("performing incremental sync")
        let pushChannel = try await pushChannelAPI.createPushChannel(clientID: selfClientID)
        logger.debug("opening push channel")
        let liveEventStream = try await pushChannel.open()
        try await updateEventsSync.pull()
        try await processStoredEvents()

        let task = Task { @Sendable [logger, decryptor, store, processor] in
            logger.debug("handling live event stream")

            do {
                for try await var envelope in liveEventStream {
                    logger.debug("received live event envelope")

                    // TODO: [WPB-16165] skip if duplicate.

                    do {
                        // Decrypt.
                        logger.debug("decrypting live event envelope")
                        envelope.events = try await decryptor.decryptEvents(in: envelope)
                    } catch {
                        logger.error("failed to decrypt live event envelope: \(String(describing: error))")
                        continue
                    }

                    let index: Int64
                    do {
                        // Store.
                        logger.debug("storing live event envelope")
                        index = try await store.indexOfLastEventEnvelope() + 1
                        try await store.persistEventEnvelope(envelope, index: index)
                    } catch {
                        logger.error("failed to store live event envelope: \(String(describing: error))")
                        continue
                    }

                    // Process.
                    for event in envelope.events {
                        do {
                            logger.debug("processing live event: \(event.name)")
                            try await processor.processEvent(event)
                        } catch {
                            logger.error("failed to process live event: \(String(describing: error))")
                        }
                    }

                    do {
                        // Delete.
                        logger.debug("deleting live event envelope")
                        try await store.deleteEventEnvelope(atIndex: index)
                    } catch {
                        logger.error("failed to delete live event envelope: \(String(describing: error))")
                    }
                }
            } catch {
                logger.warn("live event stream encountered error: \(String(describing: error))")
            }

            logger.debug("live event stream did finish")
        }

        return Token(task: task, closePushChannel: {
            await pushChannel.close()
        })
    }

    private func processStoredEvents() async throws {
        let batchSize: UInt = 500

        while true {
            // If we need to abort, do it before processing the next batch.
            try Task.checkCancellation()

            let envelopes = try await store.fetchStoredEventEnvelopes(limit: batchSize)

            guard !envelopes.isEmpty else {
                break
            }

            logger.debug("fetched \(envelopes.count) stored envelopes for processing")

            for event in envelopes.flatMap(\.events) {
                do {
                    logger.debug("processing pending event: \(event.name)")
                    try await processor.processEvent(event)
                } catch {
                    logger.error("failed to process stored event, dropping: \(error)")
                }
            }

            try await store.deleteNextPendingEvents(limit: batchSize)
        }
    }

    /// A token containing the task that processes live events via the push
    /// channel.
    ///
    /// Retain and use this token to cancel the task and close the push channel,
    /// such as when the application enters the background.

    public struct Token {

        let task: Task<Void, Never>
        let closePushChannel: () async -> Void

        public init(
            task: Task<Void, Never>,
            closePushChannel: @escaping () async -> Void
        ) {
            self.task = task
            self.closePushChannel = closePushChannel
        }

        public func suspend() async {
            task.cancel()
            await closePushChannel()
        }
    }

}

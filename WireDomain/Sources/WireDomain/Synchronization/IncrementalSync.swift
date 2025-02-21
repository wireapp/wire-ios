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

public struct IncrementalSync {

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

    public func perform() async throws -> Task<Void, any Error> {
        logger.debug("performing incremental sync")
        let pushChannel = try await pushChannelAPI.createPushChannel(clientID: selfClientID)
        logger.debug("opening push channel")
        let liveEventStream = try await pushChannel.open()
        try await updateEventsSync.pull()
        try await processStoredEvents()

        return Task { @Sendable [logger, decryptor, store, processor] in
            let jsonEncoder = JSONEncoder()
            for try await var envelope in liveEventStream {
                logger.debug("received live event envelope")
                try Task.checkCancellation()
                // TODO: [WPB-16165] skip if duplicate.

                // Decrypt.
                logger.debug("decrypting live event envelope")
                envelope.events = try await decryptor.decryptEvents(in: envelope)

                // Store.
                logger.debug("storing live event envelope")
                let index = try await store.indexOfLastEventEnvelope() + 1
                try await store.persistEventEnvelope(envelope, index: index)

                // Process.
                for event in envelope.events {
                    logger.debug("processing live event: \(event)")
                    try await processor.processEvent(event)
                }

                // Delete.
                logger.debug("deleting live event envelope")
                try await store.deleteEventEnvelope(atIndex: index)
            }
        }
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
                    logger.debug("processing pending event: \(event)")
                    try await processor.processEvent(event)
                } catch {
                    logger.error("failed to process stored event, dropping: \(error)")
                }
            }

            try await store.deleteNextPendingEvents(limit: batchSize)
        }
    }

}

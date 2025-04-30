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

public struct NewIncrementalSync: IncrementalSyncProtocol {
    public enum Failure: Error {
        case needsInitialSync
    }

    private let selfClientID: String
    private let pushChannelAPI: any PushChannelAPI
    private let decryptor: any UpdateEventDecryptorProtocol
    private let store: any UpdateEventsLocalStoreProtocol
    private let processor: any UpdateEventProcessorProtocol
    private let databaseSaver: any DatabaseSaverProtocol
    private let logger = WireLogger.sync

    public init(
        selfClientID: String,
        pushChannelAPI: any PushChannelAPI,
        decryptor: any UpdateEventDecryptorProtocol,
        store: any UpdateEventsLocalStoreProtocol,
        processor: any UpdateEventProcessorProtocol,
        databaseSaver: any DatabaseSaverProtocol
    ) {
        self.selfClientID = selfClientID
        self.pushChannelAPI = pushChannelAPI
        self.decryptor = decryptor
        self.store = store
        self.processor = processor
        self.databaseSaver = databaseSaver
    }

    public func perform() async throws -> IncrementalSync.Token {
        logger.debug("performing incremental sync")
        let pushChannel = try await pushChannelAPI.createPushChannel(clientID: selfClientID)

        logger.debug("opening new push channel")
        let liveEventStream = try await pushChannel.open()

        let task: Task<Void, Error> = Task { @Sendable [logger, decryptor, store, processor, databaseSaver, pushChannel] in
            logger.debug("handling live event stream")

            do {
                for try await var envelope in liveEventStream {
                    logger.debug("received live event envelope")

                    do {
                        // Decrypt.
                        logger.debug(
                            "decrypting live event envelope",
                            attributes: [.eventEnvelopeID: envelope.id]
                        )
                        envelope.events = try await decryptor.decryptEvents(in: envelope)
                    } catch {
                        logger.error(
                            "failed to decrypt live event envelope: \(String(describing: error))",
                            attributes: [.eventEnvelopeID: envelope.id]
                        )
                        continue
                    }

                    let index: Int64
                    do {
                        // Store.
                        logger.debug(
                            "storing live event envelope",
                            attributes: [.eventEnvelopeID: envelope.id]
                        )
                        index = try await store.indexOfLastEventEnvelope() + 1
                        try await store.persistEventEnvelope(envelope, index: index)

                        if let deliveryTag = envelope.deliveryTag {
                            logger.debug(
                                "ack event envelope",
                                attributes: [.eventEnvelopeID: envelope.id]
                            )
                            try await pushChannel.ack(deliveryTag: deliveryTag, multiple: false)
                        }
                    } catch {
                        logger.error(
                            "failed to store live event envelope: \(String(describing: error))",
                            attributes: [.eventEnvelopeID: envelope.id]
                        )
                        continue
                    }

                    // Process.
                    for event in envelope.events {
                        do {
                            logger.debug(
                                "processing live event: \(event.name)",
                                attributes: [.eventEnvelopeID: envelope.id]
                            )
                            try await processor.processEvent(event)
                        } catch {
                            logger.error(
                                "failed to process live event: \(String(describing: error))",
                                attributes: [.eventEnvelopeID: envelope.id]
                            )
                        }
                    }

                    do {
                        // Delete.
                        logger.debug(
                            "deleting live event envelope",
                            attributes: [.eventEnvelopeID: envelope.id]
                        )
                        try await store.deleteEventEnvelope(atIndex: index)
                    } catch {
                        logger.error(
                            "failed to delete live event envelope: \(String(describing: error))",
                            attributes: [.eventEnvelopeID: envelope.id]
                        )
                    }

                    await store.calculateLastUnreadMessages()

                    do {
                        // Save.
                        try await databaseSaver.save()
                    } catch {
                        logger.error("failed to save database: \(String(describing: error))")
                    }

                }
            } catch PushChannelError.missingEvents {
                // TODO: do slow sync (initial sync)
                throw Failure.needsInitialSync
            } catch {
                logger.warn("v3 live event stream encountered error: \(String(describing: error))")
            }

            logger.debug("live event stream did finish")
        }

        return IncrementalSync.Token(task: task, closePushChannel: {
            await pushChannel.close()
        })
    }
}

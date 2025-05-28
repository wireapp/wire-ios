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

import Combine
import Foundation
import WireAPI
import WireLogging

/// IncrementalSync using new backend API async stream notifications
public struct NewIncrementalSync: LiveSyncProtocol {

    private let selfClientID: String
    private let pushChannelAPI: any NewPushChannelAPI
    private let decryptor: any UpdateEventDecryptorProtocol
    private let store: any UpdateEventsLocalStoreProtocol
    private let processor: any UpdateEventProcessorProtocol
    private let databaseSaver: any DatabaseSaverProtocol
    private let syncStateSubject: CurrentValueSubject<SyncState, Never>
    private let logger = WireLogger.sync
    var delegate: (any LiveSyncDelegate)?

    public init(
        selfClientID: String,
        pushChannelAPI: any NewPushChannelAPI,
        decryptor: any UpdateEventDecryptorProtocol,
        store: any UpdateEventsLocalStoreProtocol,
        processor: any UpdateEventProcessorProtocol,
        databaseSaver: any DatabaseSaverProtocol,
        syncStateSubject: CurrentValueSubject<SyncState, Never>
    ) {
        self.selfClientID = selfClientID
        self.pushChannelAPI = pushChannelAPI
        self.decryptor = decryptor
        self.store = store
        self.processor = processor
        self.databaseSaver = databaseSaver
        self.syncStateSubject = syncStateSubject
    }

    public func perform(acknowledgeFullSync: Bool) async throws -> IncrementalSync.Token {
        logger.debug("performing live sync v3")
        let pushChannel = try await pushChannelAPI.createPushChannel(clientID: selfClientID)

        if acknowledgeFullSync {
            try await pushChannel.ackFullSync()
        }

        logger.debug("opening new push channel v3")
        syncStateSubject.send(.incrementalSyncing(.openPushChannel))
        let liveEventStream = try await pushChannel.open()

        let task = Task { @Sendable [logger, decryptor, store, processor, databaseSaver, syncStateSubject, pushChannel, delegate] in
            logger.debug("handling live event stream v3")
            syncStateSubject.send(.liveSyncing)

            do {
                for try await var element in liveEventStream {
                    logger.debug("received live event envelope v3")
                    switch element {
                    case .upToDate:
                        logger.debug("upToDate event v3")
                        syncStateSubject.send(.idle)
                        delegate?.didFinishSync(sync: self)

                    case .missedEvents:
                        logger.debug("missedEvents event v3")
                        await delegate?.didMissedEvents(sync: self)
                        // TODO: [WPB-17609] insert potential gap message here with messageLocalStore
                        try await pushChannel.ackFullSync()

                    case let .event(enveloppe):
                        var envelope = enveloppe
                        do {
                            // Decrypt.
                            logger.debug(
                                "decrypting live event envelope  v3",
                                attributes: [.eventEnvelopeID: envelope.id]
                            )
                            envelope.events = try await decryptor.decryptEvents(in: envelope)
                        } catch {
                            logger.error(
                                "failed to decrypt live event envelope  v3: \(String(describing: error))",
                                attributes: [.eventEnvelopeID: envelope.id]
                            )
                            continue
                        }

                        let index: Int64
                        do {
                            // Store.
                            logger.debug(
                                "storing live event envelope  v3",
                                attributes: [.eventEnvelopeID: envelope.id]
                            )
                            index = try await store.indexOfLastEventEnvelope() + 1
                            try await store.persistEventEnvelope(envelope, index: index)
                        } catch {
                            logger.error(
                                "failed to store live event envelope v3: \(String(describing: error))",
                                attributes: [.eventEnvelopeID: envelope.id]
                            )
                            continue
                        }

                        // Bump the last event id so we don't refetch it.
                        // there's no events marked as transcient anymore
                        store.storeLastEventID(id: envelope.id)

                        // ACK
                        do {
                            if let deliveryTag = envelope.deliveryTag {
                                logger.debug(
                                    "ack event envelope v3",
                                    attributes: [.eventEnvelopeID: envelope.id]
                                )
                                try await pushChannel.ackEvent(deliveryTag: deliveryTag, multiple: false)
                            }
                        } catch {
                            logger.error(
                                "failed to ack live event envelope v3: \(String(describing: error))",
                                attributes: [.eventEnvelopeID: envelope.id]
                            )

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
                        // finish
                        do {
                            // Delete.
                            logger.debug(
                                "deleting live event envelope",
                                attributes: [.eventEnvelopeID: envelope.id]
                            )
                            try await store.deleteEventEnvelope(atIndex: index)
                        } catch {
                            logger.error(
                                "failed to delete live event envelope v3: \(String(describing: error))",
                                attributes: [.eventEnvelopeID: envelope.id]
                            )
                        }

                        await store.calculateLastUnreadMessages()

                        do {
                            // Save.
                            try await databaseSaver.save()
                        } catch {
                            logger.error("failed to save database v3: \(String(describing: error))")
                        }
                    }

                }

            } catch {
                // if we end up here, the pushChannel is closed
                logger.warn("v3 live event stream encountered error: \(String(describing: error))")
                syncStateSubject.send(.idle)
                delegate?.didFail(sync: self, error: error)
                return
            }

            logger.debug("live event stream did finish v3")
            syncStateSubject.send(.idle)
        }

        return IncrementalSync.Token(task: task, closePushChannel: {
            await pushChannel.close()
        })
    }
}

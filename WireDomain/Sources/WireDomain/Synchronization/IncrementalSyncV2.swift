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

@preconcurrency import Combine
import Foundation
import WireAPI
import WireLogging

/// IncrementalSync using new backend API async stream notifications
public struct IncrementalSyncV2: LiveSyncProtocol {

    private let selfClientID: String
    private let pushChannelAPI: any PushChannelV2API
    private let decryptor: any UpdateEventDecryptorProtocol
    private let store: any UpdateEventsLocalStoreProtocol
    private let processor: any UpdateEventProcessorProtocol
    private let databaseSaver: any DatabaseSaverProtocol
    private let syncStateSubject: CurrentValueSubject<SyncState, Never>
    private let logger = WireLogger.sync
    private let journal: Journal
    weak var delegate: (any LiveSyncDelegate)?

    public init(
        selfClientID: String,
        pushChannelAPI: any PushChannelV2API,
        decryptor: any UpdateEventDecryptorProtocol,
        store: any UpdateEventsLocalStoreProtocol,
        processor: any UpdateEventProcessorProtocol,
        databaseSaver: any DatabaseSaverProtocol,
        syncStateSubject: CurrentValueSubject<SyncState, Never>,
        journal: Journal
    ) {
        self.selfClientID = selfClientID
        self.pushChannelAPI = pushChannelAPI
        self.decryptor = decryptor
        self.store = store
        self.processor = processor
        self.databaseSaver = databaseSaver
        self.syncStateSubject = syncStateSubject
        self.journal = journal
    }

    public func perform() async throws -> IncrementalSync.Token {
        logger.debug("performing live sync v3")
        let pushChannel = try await pushChannelAPI.createPushChannel(clientID: selfClientID)

        logger.debug("opening new push channel v3")
        syncStateSubject.send(.incrementalSyncing(.openPushChannel))
        let liveEventStream = try await pushChannel.open()

        let task = Task { @Sendable [self, pushChannel] in
            await processLiveStream(liveEventStream, pushChannel: pushChannel)
        }

        return IncrementalSync.Token(task: task, closePushChannel: {
            await pushChannel.close()
        })
    }

    private func processLiveStream(
        _ liveEventStream: PushChannelV2.Stream,
        pushChannel: PushChannelV2Protocol
    ) async {
        logger.debug("handling live event stream v3")
        syncStateSubject.send(.incrementalSyncing(.pullPendingEvents))
        do {
            for try await element in liveEventStream {
                logger.debug(
                    "received live element: \(element)",
                    attributes: .syncAttributes(initialSync: false)
                )
                switch element {
                case .upToDate:
                    logger.debug("upToDate event", attributes:  .syncAttributes(initialSync: false))
                    syncStateSubject.send(.liveSyncing(.ongoing))
                    delegate?.isUpToDate(sync: self)

                case .missedEvents:
                    logger.debug("missedEvents event", attributes:  .syncAttributes(initialSync: false))
                    await delegate?.didMissedEvents(sync: self)
                    // TODO: [WPB-17609] insert potential gap message here with messageLocalStore
                    try await pushChannel.acknowledgeFullSync()
                case .syncing:
                    // ignore this event, it gives the number of messages until we're caught up
                    try await pushChannel.acknowledgeMessageCount()
                case let .event(envelope):
                    do {
                        var envelope = envelope
                        envelope.events = try await decryptEnvelope(envelope)

                        let index = try await storeEnvelope(envelope)

                        // TODO: [WPB-17947] handle duplicate events, reacknowledge and move on

                        await acknowledgeEnvelope(envelope, through: pushChannel)

                        await processEnvelope(envelope)

                        // finish
                        await deleteEnvelope(envelope, at: index)
                        await store.calculateLastUnreadMessages()

                        await save()
                    } catch {
                        // in case of thrown errors, we skip to the next event
                        // errors are already logged if needed
                        continue
                    }
                }
            }

        } catch {
            // if we end up here, the pushChannel is closed
            logger.warn("live event stream encountered error: \(String(describing: error))", attributes: .syncAttributes(initialSync: false))
            syncStateSubject.send(.liveSyncing(.finished))
            delegate?.didFail(sync: self, error: error)
            return
        }

        logger.debug("live event stream did finish v3")
        syncStateSubject.send(.liveSyncing(.finished))
    }

    // MARK: - Event Steps

    private func decryptEnvelope(_ envelope: UpdateEventEnvelope) async throws -> [UpdateEvent] {
        do {
            // Decrypt.
            logger.debug(
                "decrypting live event envelope  v3",
                attributes: [.eventEnvelopeID: envelope.id]
            )
            // TODO: [WPB-17703] add batch decryption
            let decryptionEventsResult = try await decryptor.decryptEvents(in: envelope, context: nil)

            let brokenMLSGroupIDs = decryptionEventsResult.brokenMLSGroupIDs
            if !brokenMLSGroupIDs.isEmpty {
                journal.addValues(Set(brokenMLSGroupIDs), for: .brokenMLSGroupIDs)
            }
            return decryptionEventsResult.events
        } catch {
            logger.error(
                "failed to decrypt live event envelope: \(String(describing: error))",
                attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
            )
            throw error
        }
    }

    private func storeEnvelope(_ envelope: UpdateEventEnvelope) async throws -> Int64 {
        let index: Int64
        do {
            // Store.
            logger.debug(
                "storing live event envelope",
                attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
            )
            index = try await store.indexOfLastEventEnvelope() + 1
            try await store.persistEventEnvelope(envelope, index: index)
        } catch {
            logger.error(
                "failed to store live event envelope: \(String(describing: error))",
                attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
            )
            throw error
        }

        return index
    }

    private func acknowledgeEnvelope(
        _ envelope: UpdateEventEnvelope,
        through pushChannel: PushChannelV2Protocol
    ) async {
        do {
            if let deliveryTag = envelope.deliveryTag {
                logger.debug(
                    "ack event envelope",
                    attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
                )
                try await pushChannel.acknowledgeEvent(deliveryTag: deliveryTag, multiple: false)
            }
        } catch {
            logger.error(
                "failed to acknowledge live event envelope: \(String(describing: error))",
                attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
            )
        }
    }

    private func processEnvelope(_ envelope: UpdateEventEnvelope) async {
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
                    attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
                )
            }
        }
    }

    private func deleteEnvelope(_ envelope: UpdateEventEnvelope, at index: Int64) async {
        do {
            // Delete.
            logger.debug(
                "deleting live event envelope",
                attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
            )
            try await store.deleteEventEnvelope(atIndex: index)
        } catch {
            logger.error(
                "failed to delete live event envelope: \(String(describing: error))",
                attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
            )
        }
    }

    private func save() async {
        do {
            // Save.
            try await databaseSaver.save()
        } catch {
            logger.error("failed to save database: \(String(describing: error))", attributes: .syncAttributes(initialSync: false))
        }
    }
}

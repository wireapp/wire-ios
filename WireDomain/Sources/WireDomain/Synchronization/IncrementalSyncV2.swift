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
import WireCoreCrypto
import WireDataModel
import WireLogging
import WireNetwork

/// IncrementalSync using new backend API consumable notifications sync system
public struct IncrementalSyncV2: LiveSyncProtocol {

    enum Failure: Error {
        /// Contains all envelopes that were successfully processed
        case incompleteBatchProcessed(processedEnvelopes: [UpdateEventEnvelope])
    }

    private let selfClientID: String
    private let pullServerTimeSync: any PullServerTimeSyncProtocol
    private let pushChannelAPI: any PushChannelV2API
    private let decryptor: any UpdateEventDecryptorProtocol
    private let updateEventsStore: any UpdateEventsLocalStoreProtocol
    private let messageStore: any MessageLocalStoreProtocol
    private let processor: any UpdateEventProcessorProtocol
    private let databaseSaver: any DatabaseSaverProtocol
    private let coreCryptoProvider: any CoreCryptoProviderProtocol
    private let syncStateSubject: CurrentValueSubject<SyncState, Never>
    private let logger = WireLogger.sync
    private let journal: Journal
    private let syncMarkerGenerator: SyncMarkerGenerator
    private let pushChannelState: PushChannelStateProtocol

    weak var delegate: (any LiveSyncDelegate)?

    public init(
        selfClientID: String,
        pullServerTimeSync: any PullServerTimeSyncProtocol,
        pushChannelAPI: any PushChannelV2API,
        decryptor: any UpdateEventDecryptorProtocol,
        updateEventsStore: any UpdateEventsLocalStoreProtocol,
        messageStore: any MessageLocalStoreProtocol,
        processor: any UpdateEventProcessorProtocol,
        databaseSaver: any DatabaseSaverProtocol,
        syncStateSubject: CurrentValueSubject<SyncState, Never>,
        coreCryptoProvider: any CoreCryptoProviderProtocol,
        journal: Journal,

        pushChannelState: PushChannelStateProtocol,
        syncMarkerGenerator: @escaping SyncMarkerGenerator = { UUID().uuidString }
    ) {
        self.selfClientID = selfClientID
        self.pullServerTimeSync = pullServerTimeSync
        self.pushChannelAPI = pushChannelAPI
        self.decryptor = decryptor
        self.updateEventsStore = updateEventsStore
        self.messageStore = messageStore
        self.processor = processor
        self.databaseSaver = databaseSaver
        self.syncStateSubject = syncStateSubject
        self.coreCryptoProvider = coreCryptoProvider
        self.journal = journal
        self.syncMarkerGenerator = syncMarkerGenerator
        self.pushChannelState = pushChannelState
    }

    public func perform() async throws -> IncrementalSync.Token {
        logger.debug("performing live sync", attributes: .syncAttributes(initialSync: false))

        try await pullServerTimeSync.pull()

        let syncMarker = syncMarkerGenerator()
        let pushChannel = try await pushChannelAPI.createPushChannel(clientID: selfClientID, marker: syncMarker)

        logger.debug("opening new push channel", attributes: .syncAttributes(initialSync: false))
        syncStateSubject.send(.incrementalSyncing(.openPushChannel))

        let liveEventStream: PushChannelV2.Stream
        do {
            liveEventStream = try await pushChannel.open()
            pushChannelState.markAsOpen()
        } catch {
            pushChannelState.markAsClosed()
            throw error
        }

        logger.debug("processing stored update events", attributes: .syncAttributes(initialSync: false))
        syncStateSubject.send(.incrementalSyncing(.processPendingEvents))
        do {
            try await processStoredEvents()
        } catch {
            await pushChannel.close()
            pushChannelState.markAsClosed()
            throw error
        }

        let task = Task { @Sendable [self, pushChannel] in
            await processLiveStream(
                liveEventStream,
                pushChannel: pushChannel,
                syncMarker: syncMarker
            )
        }

        return IncrementalSync.Token(task: task, closePushChannel: {
            await pushChannel.close()
            pushChannelState.markAsClosed()
        })
    }

    /// Process pending events from the event database that were decrypted during the NSE
    private func processStoredEvents() async throws {
        let batchSize: UInt = 500

        while true {
            // If we need to abort, do it before processing the next batch.
            try Task.checkCancellation()

            let envelopesWithObjectIDs = try await updateEventsStore.fetchStoredEventEnvelopes(limit: batchSize)
            let envelopes = envelopesWithObjectIDs.map(\.envelope)
            let envelopesObjectIDs = envelopesWithObjectIDs.map(\.objectID)

            guard !envelopes.isEmpty else {
                break
            }

            logger.debug(
                "fetched \(envelopes.count) stored envelopes for processing",
                attributes: .syncAttributes(initialSync: false)
            )

            for envelope in envelopes {
                for event in envelope.events {
                    do {
                        logger.debug(
                            "processing pending event: \(event.name)",
                            attributes: .syncAttributes(initialSync: false) + [.eventEnvelopeID: envelope.id]
                        )
                        if event.isTypingEvent {
                            // We should only process live typing events, not old stored events
                            // that are no longer relevant.
                            continue
                        }
                        try await processor.processEvent(event)
                    } catch {
                        // TODO: [WPB-10458] review handling errors of processingEvents
                        logger.error(
                            "failed to process stored event, dropping: \(error)",
                            attributes: .syncAttributes(initialSync: false) + [.eventEnvelopeID: envelope.id]
                        )
                    }
                }
            }

            try await updateEventsStore.deleteNextPendingEvents(with: envelopesObjectIDs)
            await updateEventsStore.calculateLastUnreadMessages()

            do {
                try await databaseSaver.save()
            } catch {
                logger.error(
                    "failed to save database: \(String(describing: error))",
                    attributes: .syncAttributes(initialSync: false)
                )
            }
        }
    }

    private func processLiveStream(
        _ liveEventStream: PushChannelV2.Stream,
        pushChannel: PushChannelV2Protocol,
        syncMarker: String
    ) async {
        logger.debug("handling live event stream", attributes: .syncAttributes(initialSync: false))
        syncStateSubject.send(.incrementalSyncing(.receivingLiveEvents))

        do {
            for try await element in liveEventStream {
                switch element {
                case let .syncMarker(id, deliveryTag):

                    try await pushChannel.acknowledgeEvent(deliveryTag: deliveryTag, multiple: false)

                    if id == syncMarker {
                        logger.debug("upToDate event", attributes: .syncAttributes(initialSync: false))
                        syncStateSubject.send(.liveSyncing(.ongoing))
                        await pushChannel.disableBatching(true)
                        delegate?.isUpToDate(sync: self)
                    }
                case .missedEvents:
                    logger.debug("missedEvents event", attributes: .syncAttributes(initialSync: false))
                    await delegate?.didMissedEvents(sync: self)
                    try await messageStore.addPotentialGapSystemMessage()
                    try await pushChannel.acknowledgeFullSync()
                case let .events(envelopes):
                    do {
                        try await processBatch(
                            envelopes: envelopes,
                            pushChannel: pushChannel
                        )

                    } catch {
                        WireLogger.sync.error("event processing failed: \(error)", attributes: .syncAttributes)
                        assertionFailure("event processing failed: \(error)")
                        // TODO: [WPB-10458] review handling errors of processingEvents
                        // in case of thrown errors, we skip to the next event
                        // errors are already logged if needed
                        continue
                    }
                }
            }
        } catch {
            // if we end up here, the pushChannel is closed
            logger.warn(
                "live event stream encountered error: \(String(describing: error))",
                attributes: .syncAttributes(initialSync: false)
            )
            syncStateSubject.send(.liveSyncing(.finished))
            delegate?.didFail(sync: self, error: error)
            return
        }

        logger.debug("live event stream did finish v3")
        syncStateSubject.send(.liveSyncing(.finished))
    }

    // MARK: - Event Steps

    private func processBatch(
        envelopes: [UpdateEventEnvelope],
        pushChannel: PushChannelV2Protocol
    ) async throws {

        var storedEnvelopes: [(UpdateEventEnvelope, Int64)] = []

        // decrypt
        try await coreCryptoProvider.coreCrypto().perform { coreCryptoContext in
            for envelope in envelopes {
                var envelope = envelope
                envelope.events = await decryptEnvelope(envelope, in: coreCryptoContext)

                // store
                let index = try await storeEnvelope(envelope)
                storedEnvelopes.append((envelope, index))
            }
        }

        // ack
        if let lastEnvelope = storedEnvelopes.last?.0 {
            await acknowledgeUntilEnvelope(lastEnvelope, through: pushChannel)
        }

        // process
        var envelopeIdsToDelete = [Int64]()
        for (envelope, index) in storedEnvelopes {
            do {
                try await processEnvelope(envelope)
                envelopeIdsToDelete.append(index)
            } catch {
                logger.critical(
                    "Failed to process envelope: \(error)",
                    attributes: .syncAttributes(initialSync: false) + [.eventEnvelopeID: envelope.id]
                )
                assertionFailure("Failed to process envelope: \(error)")
            }
        }

        // only delete successful processed envelopes
        await deleteEnvelopes(at: envelopeIdsToDelete)
        // TODO: [WPB-10458] save the message db and then event db

        await updateEventsStore.calculateLastUnreadMessages()
        await save()
    }

    private func decryptEnvelope(
        _ envelope: UpdateEventEnvelope,
        in context: CoreCryptoContextProtocol
    ) async -> [UpdateEvent] {
        logger.debug(
            "decrypting live event envelope",
            attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes
        )
        let decryptionEventsResult = await decryptor.decryptEvents(in: envelope, context: context)

        let brokenMLSGroupIDs = decryptionEventsResult.brokenMLSGroupIDs
        if !brokenMLSGroupIDs.isEmpty {
            journal.addValues(Set(brokenMLSGroupIDs), for: .brokenMLSGroupIDs)
        }
        return decryptionEventsResult.events
    }

    private func storeEnvelope(_ envelope: UpdateEventEnvelope) async throws -> Int64 {
        let index: Int64
        do {
            // Store.
            logger.debug(
                "storing live event envelope",
                attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
            )
            index = try await updateEventsStore.indexOfLastEventEnvelope() + 1
            try await updateEventsStore.persistEventEnvelope(envelope, index: index)
        } catch {
            logger.error(
                "failed to store live event envelope: \(String(describing: error))",
                attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
            )
            throw error
        }

        return index
    }

    private func acknowledgeUntilEnvelope(
        _ envelope: UpdateEventEnvelope,
        through pushChannel: PushChannelV2Protocol
    ) async {
        do {
            if let deliveryTag = envelope.deliveryTag {
                logger.debug(
                    "ack event envelope",
                    attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
                )
                try await pushChannel.acknowledgeEvent(deliveryTag: deliveryTag, multiple: true)
            }
        } catch {
            logger.error(
                "failed to acknowledge multiple event envelopes up to: \(String(describing: error))",
                attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
            )
        }
    }

    private func processEnvelope(_ envelope: UpdateEventEnvelope) async throws {
        for event in envelope.events {
            logger.debug(
                "processing live event: \(event.name)",
                attributes: [.eventEnvelopeID: envelope.id]
            )
            try await processor.processEvent(event)
        }
    }

    private func deleteEnvelopes(at indices: [Int64]) async {
        do {
            try await updateEventsStore.deleteEventEnvelopes(at: indices)
        } catch {
            logger.error(
                "failed to delete live event envelopes: \(String(describing: error))",
                attributes: .syncAttributes(initialSync: false)
            )
        }
    }

    private func save() async {
        do {
            // Save.
            try await databaseSaver.save()
        } catch {
            logger.error(
                "failed to save database: \(String(describing: error))",
                attributes: .syncAttributes(initialSync: false)
            )
        }
    }
}

private extension UpdateEvent {

    var isTypingEvent: Bool {
        switch self {
        case .conversation(.typing):
            true
        default:
            false
        }
    }
}

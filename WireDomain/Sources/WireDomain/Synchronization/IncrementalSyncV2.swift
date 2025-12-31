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

public typealias CreatePushChannelStateClosure = () -> PushChannelStateProtocol

/// IncrementalSync using new backend API consumable notifications sync system
public struct IncrementalSyncV2: LiveSyncProtocol {

    public enum Failure: Error, Equatable {
        /// Contains all envelopes that were successfully processed
        case incompleteBatchProcessed(processedEnvelopes: [UpdateEventEnvelope])
        case nsePushChannelAlreadyOpened
        case mainAppPushChannelAlreadyOpened
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
    private let createPushChannelState: CreatePushChannelStateClosure
    private let mlsGroupRepairAgent: MLSGroupRepairAgentProtocol

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
        mlsGroupRepairAgent: MLSGroupRepairAgentProtocol,
        createPushChannelState: @escaping CreatePushChannelStateClosure,
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
        self.mlsGroupRepairAgent = mlsGroupRepairAgent
        self.syncMarkerGenerator = syncMarkerGenerator
        self.createPushChannelState = createPushChannelState
    }

    private var logAttributes: WireLogging.LogAttributes {
        .incrementalSyncV3
    }

    public func perform() async throws -> IncrementalSync.Token {
        logger.debug("performing live sync", attributes: logAttributes)
        try Task.checkCancellation()

        try await pullServerTimeSync.pull()

        // makes sure that the file descriptor within pushChannelState is released when in background
        // so we're not killed by OS
        let pushChannelState = createPushChannelState()
        do {
            try await pushChannelState.markAsOpen()
        } catch let PushChannelState.Failure.alreadyLocked(sameProcess) {
            if !sameProcess {
                throw Failure.nsePushChannelAlreadyOpened
            } else {
                throw Failure.mainAppPushChannelAlreadyOpened
            }
        }

        // notify SyncAgent now to show sync bar,
        // not before as it could result in an infinite sync bar
        delegate?.didStart(sync: self)

        let syncMarker = syncMarkerGenerator()

        let pushChannel: PushChannelV2Protocol
        do {
            syncStateSubject.send(.incrementalSyncing(.createPushChannel))
            pushChannel = try await pushChannelAPI.createPushChannel(clientID: selfClientID, marker: syncMarker)
        } catch {
            await pushChannelState.markAsClosed()
            throw error
        }

        logger.debug("creating push channel with marker \(syncMarker)", attributes: logAttributes)
        syncStateSubject.send(.incrementalSyncing(.openPushChannel))

        let liveEventStream: PushChannelV2.Stream
        do {
            liveEventStream = try await pushChannel.open()
        } catch {
            await pushChannelState.markAsClosed()
            throw error
        }

        logger.debug("processing stored update events", attributes: logAttributes)
        syncStateSubject.send(.incrementalSyncing(.processPendingEvents))
        do {
            try await processStoredEvents()
        } catch {
            await pushChannel.close()
            await pushChannelState.markAsClosed()
            throw error
        }

        await mlsGroupRepairAgent.repairConversations()

        let task = Task { @Sendable [self] in
            logger.debug("handling live event stream", attributes: logAttributes)
            syncStateSubject.send(.liveSyncing(.ongoing))

            do {
                // because we might be interrupted when in background, we wrap the sync in an expiringActivity that will
                // cancel the task (not keeping any file lock in suspend mode)
                try await withExpiringActivity(reason: "processLiveStream IncrementalSyncV2") {
                    await processLiveStream(
                        liveEventStream,
                        pushChannel: pushChannel,
                        syncMarker: syncMarker
                    )

                    WireLogger.sync.debug("Live stream ended, close push channel", attributes: logAttributes)
                    await pushChannel.close()
                    await pushChannelState.markAsClosed()
                }
            } catch {
                // if we expire, close everything
                WireLogger.sync.debug(
                    "Error while processing live stream, close push channel",
                    attributes: logAttributes
                )
                await pushChannel.close()
                await pushChannelState.markAsClosed()
            }
        }

        return IncrementalSync.Token(task: task, closePushChannel: {
            await pushChannel.close()
            await pushChannelState.markAsClosed()
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
                attributes: logAttributes
            )

            for envelope in envelopes {
                for event in envelope.events {
                    do {
                        logger.debug(
                            "processing pending event: \(event.name)",
                            attributes: logAttributes + [.eventEnvelopeID: envelope.id]
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
                            attributes: logAttributes + [.eventEnvelopeID: envelope.id]
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
                    attributes: logAttributes
                )
            }
        }
    }

    private func processLiveStream(
        _ liveEventStream: PushChannelV2.Stream,
        pushChannel: PushChannelV2Protocol,
        syncMarker: String
    ) async {
        logger.debug("handling live event stream", attributes: logAttributes)
        syncStateSubject.send(.incrementalSyncing(.receivingLiveEvents))

        do {
            for try await element in liveEventStream {
                switch element {
                case let .syncMarker(id, deliveryTag):

                    logger.debug(
                        "marker \(id) - deliveryTag \(deliveryTag)",
                        attributes: logAttributes
                    )
                    try await pushChannel.acknowledgeEvent(deliveryTag: deliveryTag, multiple: false)

                    if id == syncMarker {
                        logger.debug("upToDate event", attributes: logAttributes)
                        syncStateSubject.send(.liveSyncing(.ongoing))
                        if DeveloperFlag.disablePushChannelBatching.isOn {
                            await pushChannel.disableBatching(true)
                        } else {
                            WireLogger.sync.warn("keep batching enabled", attributes: logAttributes)
                        }
                        delegate?.isUpToDate(sync: self)
                    }
                case .missedEvents:
                    logger.debug("missedEvents event", attributes: logAttributes)
                    await delegate?.didMissedEvents(sync: self)
                    try await messageStore.addPotentialGapSystemMessage()
                    try await pushChannel.acknowledgeFullSync()
                case let .events(envelopes):
                    do {
                        try await processBatch(
                            envelopes: envelopes,
                            pushChannel: pushChannel
                        )
                    } catch let error as CancellationError {
                        // we cancelled processing Events, as a safety,
                        // reopen the websocket to get the events
                        throw error
                    } catch {
                        WireLogger.sync.error("event processing failed: \(error)", attributes: logAttributes)
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
                attributes: logAttributes
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

                try Task.checkCancellation()

                // store
                let index = try await storeEnvelope(envelope)
                storedEnvelopes.append((envelope, index))
                try Task.checkCancellation()
            }
        }

        // ack
        if let lastEnvelope = storedEnvelopes.last?.0 {
            await acknowledgeUntilEnvelope(lastEnvelope, through: pushChannel, batchSize: envelopes.count)
        }
        try Task.checkCancellation()

        // process
        var envelopeIdsToDelete = [Int64]()
        for (envelope, index) in storedEnvelopes {
            do {
                try await processEnvelope(envelope)
                envelopeIdsToDelete.append(index)
            } catch {
                logger.critical(
                    "Failed to process envelope: \(error)",
                    attributes: logAttributes + [.eventEnvelopeID: envelope.id]
                )
                assertionFailure("Failed to process envelope: \(error)")
            }
        }

        // save message db first then
        await updateEventsStore.calculateLastUnreadMessages()
        await save()

        // only delete successful processed envelopes
        await deleteEnvelopes(at: envelopeIdsToDelete)
    }

    private func decryptEnvelope(
        _ envelope: UpdateEventEnvelope,
        in context: CoreCryptoContextProtocol
    ) async -> [UpdateEvent] {
        logger.debug(
            "decrypting live event envelope",
            attributes: [.eventEnvelopeID: envelope.id] + logAttributes
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
                attributes: [.eventEnvelopeID: envelope.id] + logAttributes
            )
            index = try await updateEventsStore.indexOfLastEventEnvelope() + 1
            try await updateEventsStore.persistEventEnvelope(envelope, index: index)
        } catch {
            logger.error(
                "failed to store live event envelope: \(String(describing: error))",
                attributes: [.eventEnvelopeID: envelope.id] + logAttributes
            )
            throw error
        }

        return index
    }

    private func acknowledgeUntilEnvelope(
        _ envelope: UpdateEventEnvelope,
        through pushChannel: PushChannelV2Protocol,
        batchSize: Int
    ) async {
        do {
            if let deliveryTag = envelope.deliveryTag {
                logger.debug(
                    "ack event envelope",
                    attributes: [.eventEnvelopeID: envelope.id, .ackMultipleEventsCount: batchSize] +
                        logAttributes
                )
                try await pushChannel.acknowledgeEvent(deliveryTag: deliveryTag, multiple: true)
            }
        } catch {
            logger.error(
                "failed to acknowledge multiple event envelopes up to: \(String(describing: error))",
                attributes: [.eventEnvelopeID: envelope.id] + logAttributes
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
                attributes: logAttributes
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
                attributes: logAttributes
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

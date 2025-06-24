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

    private let selfClientID: String
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
    weak var delegate: (any LiveSyncDelegate)?

    public init(
        selfClientID: String,
        pushChannelAPI: any PushChannelV2API,
        decryptor: any UpdateEventDecryptorProtocol,
        updateEventsStore: any UpdateEventsLocalStoreProtocol,
        messageStore: any MessageLocalStoreProtocol,
        processor: any UpdateEventProcessorProtocol,
        databaseSaver: any DatabaseSaverProtocol,
        syncStateSubject: CurrentValueSubject<SyncState, Never>,
        coreCryptoProvider: any CoreCryptoProviderProtocol,
        journal: Journal
    ) {
        self.selfClientID = selfClientID
        self.pushChannelAPI = pushChannelAPI
        self.decryptor = decryptor
        self.updateEventsStore = updateEventsStore
        self.messageStore = messageStore
        self.processor = processor
        self.databaseSaver = databaseSaver
        self.syncStateSubject = syncStateSubject
        self.coreCryptoProvider = coreCryptoProvider
        self.journal = journal
    }

    public func perform() async throws -> IncrementalSync.Token {
        logger.debug("performing live sync", attributes: .syncAttributes(initialSync: false))
        let pushChannel = try await pushChannelAPI.createPushChannel(clientID: selfClientID)

        logger.debug("opening new push channel", attributes: .syncAttributes(initialSync: false))
        syncStateSubject.send(.incrementalSyncing(.openPushChannel))
        let liveEventStream = try await pushChannel.open()

        logger.debug("processing stored update events", attributes: .syncAttributes(initialSync: false))
        syncStateSubject.send(.incrementalSyncing(.processPendingEvents))
        let processedEnvelopeIDs: Set<UUID>
        do {
            processedEnvelopeIDs = try await processStoredEvents()
        } catch {
            await pushChannel.close()
            throw error
        }

        let task = Task { @Sendable [self, pushChannel, processedEnvelopeIDs] in
            await processLiveStream(
                liveEventStream,
                pushChannel: pushChannel,
                processedEnvelopeIDs: processedEnvelopeIDs
            )
        }

        return IncrementalSync.Token(task: task, closePushChannel: {
            await pushChannel.close()
        })
    }

    /// Process pending events from the event database that were decrypted during the NSE
    private func processStoredEvents() async throws -> Set<UUID> {
        let batchSize: UInt = 500
        var processedEnvelopeIDs = Set<UUID>()

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
                        try await processor.processEvent(event)
                    } catch {
                        logger.error(
                            "failed to process stored event, dropping: \(error)",
                            attributes: .syncAttributes(initialSync: false) + [.eventEnvelopeID: envelope.id]
                        )
                    }
                }
            }

            processedEnvelopeIDs.formUnion(envelopes.map(\.id))
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

        return processedEnvelopeIDs
    }

    private func processLiveStream(
        _ liveEventStream: PushChannelV2.Stream,
        pushChannel: PushChannelV2Protocol,
        processedEnvelopeIDs: Set<UUID>
    ) async {
        logger.debug("handling live event stream", attributes: .syncAttributes(initialSync: false))
        syncStateSubject.send(.incrementalSyncing(.receivingLiveEvents))

        do {
            for try await element in liveEventStream {
                logger.debug(
                    "received live element: \(element)",
                    attributes: .syncAttributes(initialSync: false)
                )
                switch element {
                case .upToDate:
                    logger.debug("upToDate event", attributes: .syncAttributes(initialSync: false))
                    syncStateSubject.send(.liveSyncing(.ongoing))
                    delegate?.isUpToDate(sync: self)
                case .missedEvents:
                    logger.debug("missedEvents event", attributes: .syncAttributes(initialSync: false))
                    await delegate?.didMissedEvents(sync: self)
                    try await messageStore.addPotentialGapSystemMessage()
                    try await pushChannel.acknowledgeFullSync()
                case .syncing:
                    // ignore this event, it gives the number of messages until we're caught up
                    try await pushChannel.acknowledgeMessageCount()
                case let .events(envelopes):

                    do {
                        try await processEnvelopes(
                            envelopes,
                            pushChannel: pushChannel,
                            processedEnvelopeIDs: processedEnvelopeIDs
                        )
                    } catch {
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

    private func processEnvelopes(
        _ envelopes: [UpdateEventEnvelope],
        pushChannel: PushChannelV2Protocol,
        processedEnvelopeIDs: Set<UUID>
    ) async throws {
        var lastEnvelope: UpdateEventEnvelope?
        try await coreCryptoProvider.coreCrypto().perform { coreCryptoContext in
            for envelope in envelopes {
                if processedEnvelopeIDs.contains(envelope.id) {
                    logger.debug(
                        "live event already processed, skipping...",
                        attributes: .syncAttributes(initialSync: false) + [.eventEnvelopeID: envelope.id]
                    )
                    // TODO: [WPB-17947] handle duplicate events, reacknowledge and move on
                    // will need to store the deliveryTag...
                    continue
                }

                var envelope = envelope
                envelope.events = try await decryptEnvelope(envelope, in: coreCryptoContext)

                await processEnvelope(envelope)

                lastEnvelope = envelope
            }
        }

        await updateEventsStore.calculateLastUnreadMessages()
        await save()
        if let lastEnvelope {
            await acknowledgeUntilEnvelope(lastEnvelope, through: pushChannel)
        }
    }

    private func decryptEnvelope(
        _ envelope: UpdateEventEnvelope,
        in context: CoreCryptoContextProtocol
    ) async throws -> [UpdateEvent] {
        do {
            // Decrypt.
            logger.debug(
                "decrypting live event envelope  v3",
                attributes: [.eventEnvelopeID: envelope.id]
            )
            let decryptionEventsResult = try await decryptor.decryptEvents(in: envelope, context: context)

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

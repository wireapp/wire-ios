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
import Foundation
import WireDataModel
import WireLogging
import WireNetwork
import WireSystem
import WireUtilities

public struct IncrementalSync: IncrementalSyncProtocol {

    public enum Failure: Error {
        case missedEvents
        case databaseLocked
    }

    private let selfClientID: String
    private let pushChannelAPI: any PushChannelAPI
    private let updateEventsSync: any PullPendingUpdateEventsSyncProtocol
    private let decryptor: any UpdateEventDecryptorProtocol
    private let updateEventsStore: any UpdateEventsLocalStoreProtocol
    private let messageStore: any MessageLocalStoreProtocol
    private let processor: any UpdateEventProcessorProtocol
    private let databaseSaver: any DatabaseSaverProtocol
    private let liveBrokenGroupSubject: PassthroughSubject<Set<String>, Never>
    private let syncStateSubject: CurrentValueSubject<SyncState, Never>
    private let logger = WireLogger.sync
    private let journal: Journal
    private let mlsGroupRepairAgent: MLSGroupRepairAgentProtocol
    private let earService: EARServiceInterface

    public init(
        selfClientID: String,
        pushChannelAPI: any PushChannelAPI,
        updateEventsSync: any PullPendingUpdateEventsSyncProtocol,
        decryptor: any UpdateEventDecryptorProtocol,
        updateEventsStore: any UpdateEventsLocalStoreProtocol,
        messageStore: any MessageLocalStoreProtocol,
        processor: any UpdateEventProcessorProtocol,
        databaseSaver: any DatabaseSaverProtocol,
        syncStateSubject: CurrentValueSubject<SyncState, Never>,
        liveBrokenGroupSubject: PassthroughSubject<Set<String>, Never>,
        journal: Journal,
        mlsGroupRepairAgent: MLSGroupRepairAgentProtocol,
        earService: EARServiceInterface
    ) {
        self.selfClientID = selfClientID
        self.pushChannelAPI = pushChannelAPI
        self.updateEventsSync = updateEventsSync
        self.decryptor = decryptor
        self.updateEventsStore = updateEventsStore
        self.messageStore = messageStore
        self.processor = processor
        self.databaseSaver = databaseSaver
        self.syncStateSubject = syncStateSubject
        self.liveBrokenGroupSubject = liveBrokenGroupSubject
        self.journal = journal
        self.mlsGroupRepairAgent = mlsGroupRepairAgent
        self.earService = earService
    }

    public func perform() async throws -> Token {
        try await perform(
            appState: await UIApplication.shared.applicationState
        )
    }

    func perform(appState: UIApplication.State) async throws -> Token {
        let inBackground = appState == .background

        // Abort sync if we're in foreground and database is locked
        if !inBackground, earService.isLocked {
            logger.info(
                "not starting incremental sync: database is locked",
                attributes: .incrementalSyncV2,
                .safePublic
            )
            throw Failure.databaseLocked
        }

        // Process only background events is EAR is enabled and we're in the background
        let backgroundAccessibleOnly = earService.isEAREnabled && inBackground
        
        return try await internalPerform(backgroundAccessibleOnly: backgroundAccessibleOnly)
    }

    private func internalPerform(backgroundAccessibleOnly: Bool) async throws -> Token {
        try await logger.measureTime(
            label: "new incremental sync",
            attributes: .incrementalSyncV2
        ) {

            // Fetch keys (will return nil if EAR is disabled)
            let publicKeys = try earService.fetchPublicKeys()
            let privateKeys = try earService.fetchPrivateKeys(
                includingPrimary: !backgroundAccessibleOnly
            )

            syncStateSubject.send(.incrementalSyncing(.createPushChannel))
            let pushChannel = try await pushChannelAPI.createPushChannel(clientID: selfClientID)

            logger.debug("opening push channel", attributes: .incrementalSyncV2)
            syncStateSubject.send(.incrementalSyncing(.openPushChannel))

            let liveEventStream = try await pushChannel.open()

            let processedEnvelopeIDs: Set<UUID>
            do {
                logger.info("pulling pending update events", attributes: .incrementalSyncV2, .safePublic)
                syncStateSubject.send(.incrementalSyncing(.pullPendingEvents))
                try await updateEventsSync.pull(publicKeys: publicKeys)

                logger.info(
                    "processing stored update events",
                    attributes: .incrementalSyncV2, .safePublic
                )
                syncStateSubject.send(.incrementalSyncing(.processPendingEvents))

                processedEnvelopeIDs = try await processStoredEvents(
                    privateKeys: privateKeys,
                    backgroundAccessibleOnly: backgroundAccessibleOnly
                )
            } catch {
                func tearDown() async {
                    logger.info(
                        "incremental sync interrupted, tearing down...",
                        attributes: .incrementalSyncV2, .safePublic
                    )
                    await pushChannel.close()
                }

                switch error {
                case let apiError as UpdateEventsAPIError:
                    switch apiError {
                    case .notFound, .invalidParameters:
                        // nullifying the last event ID since we missed events and we want to
                        // reset with a full sync (initial + incremental)
                        updateEventsStore.resetLastEventID()
                        try await messageStore.addPotentialGapSystemMessage()
                        await tearDown()
                        throw Failure.missedEvents
                    default:
                        await tearDown()
                        throw error
                    }
                default:
                    await tearDown()
                    throw error
                }
            }

            await mlsGroupRepairAgent.repairConversations()

            let liveEventTask = Task { @Sendable [self] in
                logger.info("handling live event stream", attributes: .incrementalSyncV2, .safePublic)
                syncStateSubject.send(.liveSyncing(.ongoing))

                do {
                    // because we might be interrupted when in background, we wrap the sync in an expiringActivity that
                    // will cancel the task - not keeping any db operation (sqlite file opened) in suspend mode
                    try await withExpiringActivity(reason: "processLiveStream IncrementalSync") {
                        await processLiveEvents(
                            liveEventStream: liveEventStream,
                            processedEnvelopeIDs: processedEnvelopeIDs,
                            publicKeys: publicKeys,
                            backgroundAccessibleOnly: backgroundAccessibleOnly
                        )
                    }
                } catch {
                    // if we expire, close everything
                    WireLogger.sync.debug(
                        "Error while processing live stream, close push channel",
                        attributes: .incrementalSyncV2
                    )
                    await pushChannel.close()
                }

                logger.debug("live event stream did finish", attributes: .incrementalSyncV2)
                syncStateSubject.send(.liveSyncing(.finished))
            }

            return Token(task: liveEventTask, closePushChannel: {
                await pushChannel.close()
            })
        }
    }

    private func processLiveEvents(
        liveEventStream: AsyncThrowingStream<UpdateEventEnvelope, any Error>,
        processedEnvelopeIDs: Set<UUID>,
        publicKeys: EARPublicKeys?,
        backgroundAccessibleOnly: Bool
    ) async {
        do {
            for try await var envelope in liveEventStream {
                logger.debug(
                    "received live event envelope",
                    attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id]
                )

                if processedEnvelopeIDs.contains(envelope.id) {
                    logger.debug(
                        "live event already processed, skipping...",
                        attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id]
                    )
                    continue
                }

                if DeveloperFlag.ignoreIncomingEvents.isOn {
                    logger.warn(
                        "ignore incoming events",
                        attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id]
                    )
                    continue
                }

                // Decrypt.
                logger.debug(
                    "decrypting live event envelope",
                    attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id]
                )

                let decryptionEventsResult = await decryptor.decryptEvents(in: envelope, context: nil)

                envelope.events = decryptionEventsResult.events

                let brokenMLSGroupIDs = decryptionEventsResult.brokenMLSGroupIDs
                if !brokenMLSGroupIDs.isEmpty {
                    journal.addValues(brokenMLSGroupIDs, for: .brokenMLSGroupIDs)
                    liveBrokenGroupSubject.send(brokenMLSGroupIDs)
                }

                let index: Int64
                do {
                    // Store.
                    logger.debug(
                        "storing live event envelope",
                        attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id]
                    )
                    index = try await updateEventsStore.indexOfLastEventEnvelope() + 1
                    try await updateEventsStore.persistEventEnvelope(envelope, index: index, publicKeys: publicKeys)
                } catch {
                    logger.error(
                        "failed to store live event envelope: \(String(describing: error))",
                        attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id]
                    )
                    continue
                }

                // Bump the last event id so we don't refetch it.
                if !envelope.isTransient {
                    logger.debug(
                        "updating last event id",
                        attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id]
                    )
                    updateEventsStore.storeLastEventID(id: envelope.id)
                }

                // Process.
                await processLiveEventEnvelope(
                    envelope: envelope,
                    index: index,
                    publicKeys: publicKeys,
                    backgroundAccessibleOnly: backgroundAccessibleOnly
                )

                do {
                    // Save.
                    try await databaseSaver.save()
                } catch {
                    logger.error("failed to save database: \(String(describing: error))")
                }

            }

        } catch {
            logger.warn("live event stream encountered error: \(String(describing: error))")
        }
    }

    private func processLiveEventEnvelope(
        envelope: UpdateEventEnvelope,
        index: Int64,
        publicKeys: EARPublicKeys?,
        backgroundAccessibleOnly: Bool
    ) async {
        // If we're processing events in the background, and the event is not accessible: skip it.
        //
        // If we don't skip it, we may end up processing events that require access to the database key (e.g: messages).
        // But the database key is only accessible once the app is unlocked.
        guard !backgroundAccessibleOnly || (backgroundAccessibleOnly && envelope.isBackgroundAccessible) else {
            logger.info(
                "skipping processing of live event envelope: not accessible in the background",
                attributes: .safePublic,
                .incrementalSyncV2 + [.eventEnvelopeID: envelope.id] // Can it be safePublic?
            )
            return
        }

        for event in envelope.events {
            do {
                logger.debug(
                    "processing live event: \(event.name)",
                    attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id, .eventType: event.name]
                )
                try await processor.processEvent(event)
            } catch {
                logger.error(
                    "failed to process live event: \(String(describing: error))",
                    attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id, .eventType: event.name]
                )
            }
        }

        do {
            // Delete.
            logger.debug(
                "deleting live event envelope",
                attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id]
            )
            try await updateEventsStore.deleteEventEnvelope(atIndex: index)
        } catch {
            logger.error(
                "failed to delete live event envelope: \(String(describing: error))",
                attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id]
            )
        }

        await updateEventsStore.calculateLastUnreadMessages()
    }

    private func processStoredEvents(
        privateKeys: EARPrivateKeys?,
        backgroundAccessibleOnly: Bool
    ) async throws -> Set<UUID> {
        let batchSize: UInt = 500
        var processedEnvelopeIDs = Set<UUID>()

        while true {
            // If we need to abort, do it before processing the next batch.
            try Task.checkCancellation()

            let envelopesWithObjectIDs = try await updateEventsStore.fetchStoredEventEnvelopes(
                limit: batchSize,
                privateKeys: privateKeys,
                backgroundAccessibleOnly: backgroundAccessibleOnly
            )
            let envelopes = envelopesWithObjectIDs.map(\.envelope)
            let envelopesObjectIDs = envelopesWithObjectIDs.map(\.objectID)

            guard !envelopes.isEmpty else {
                break
            }

            logger.debug(
                "fetched \(envelopes.count) stored envelopes for processing",
                attributes: .incrementalSyncV2
            )

            for envelope in envelopes {
                for event in envelope.events {
                    do {
                        logger.debug(
                            "processing pending event: \(event.name)",
                            attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id]
                        )
                        try await processor.processEvent(event)
                    } catch {
                        logger.error(
                            "failed to process stored event, dropping: \(error)",
                            attributes: .incrementalSyncV2 + [.eventEnvelopeID: envelope.id]
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
                    attributes: .incrementalSyncV2
                )
            }
        }

        return processedEnvelopeIDs
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

extension IncrementalSyncV1: SyncMigratorProtocol {
    
    // TODO: [WPB-23558] Support EAR in incremental sync v2
    public func migrateFromIncrementalSyncV1() async throws {
        guard !earService.isLocked else {
            throw Failure.databaseLocked
        }
        
        logger.debug("pulling pending update events", attributes: .incrementalSyncV2)
        syncStateSubject.send(.incrementalSyncing(.pullPendingEvents))
        try await updateEventsSync.pull(publicKeys: try earService.fetchPublicKeys())

        logger.debug("processing stored update events", attributes: .incrementalSyncV2)
        let privateKeys = try earService.fetchPrivateKeys(includingPrimary: true)
        _ = try await processStoredEvents(
            privateKeys: privateKeys,
            backgroundAccessibleOnly: false
        )
    }
}

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

import CoreData
import Foundation
import WireAPI
import WireDataModel
import WireLogging
import WireSystem

protocol SyncManagerProtocol {

    /// Pulls and stores all required objects for the database to be initially up-to-date.

    func performSlowSync() async throws

    /// Fetch events from the server and process all pending events.

    func performQuickSync() async throws

    /// Stop all syncing activities and prepare to idle.

    func suspend() async throws

}

final class SyncManager: SyncManagerProtocol {

    enum Failure: Error {
        case failedToPerformSlowSync(Error)
    }

    // MARK: - Logs

    private enum SyncPhaseName: String {
        case pullingLastUpdateEventID
        case pullingSelfTeam
        case pullingSelfTeamRoles
        case pullingSelfTeamMembers
        case pullingConnections
        case pullingKnownUsers
        case pullingConversations
        case pullingSelfUser
        case pullingSelfLegalholdInfo
        case pullingConversationLabels
        case pullingFeatureConfigs
        case pullingMLSBackendStatus
        case pushingSupportedProtocols
        case resolvingOneOnOneConversations
        case pullPendingEvents // quick sync
    }

    // MARK: - Properties

    private(set) var syncState: SyncState = .suspended
    private var isSuspending = false

    // MARK: - Repositories

    private let updateEventsRepository: any UpdateEventsRepositoryProtocol
    private let teamRepository: any TeamRepositoryProtocol
    private let connectionsRepository: any ConnectionsRepositoryProtocol
    private let conversationsRepository: any ConversationRepositoryProtocol
    private let userRepository: any UserRepositoryProtocol
    private let conversationLabelsRepository: any ConversationLabelsRepositoryProtocol
    private let featureConfigsRepository: any FeatureConfigRepositoryProtocol
    private let backendConfigRepository: any BackendConfigRepositoryProtocol
    private let pushSupportedProtocolsUseCase: any PushSupportedProtocolsUseCaseProtocol
    private let mlsProvider: MLSProvider
    private let context: NSManagedObjectContext
    private let syncTimeTracker = SyncTimeTracker()

    // MARK: - Update event processor

    private let updateEventProcessor: any UpdateEventProcessorProtocol

    // MARK: - Object lifecycle

    init(
        updateEventsRepository: any UpdateEventsRepositoryProtocol,
        teamRepository: any TeamRepositoryProtocol,
        connectionsRepository: any ConnectionsRepositoryProtocol,
        conversationsRepository: any ConversationRepositoryProtocol,
        userRepository: any UserRepositoryProtocol,
        conversationLabelsRepository: any ConversationLabelsRepositoryProtocol,
        featureConfigsRepository: any FeatureConfigRepositoryProtocol,
        backendConfigRepository: any BackendConfigRepositoryProtocol,
        updateEventProcessor: any UpdateEventProcessorProtocol,
        pushSupportedProtocolsUseCase: any PushSupportedProtocolsUseCaseProtocol,
        mlsProvider: MLSProvider,
        context: NSManagedObjectContext
    ) {
        self.updateEventsRepository = updateEventsRepository
        self.teamRepository = teamRepository
        self.connectionsRepository = connectionsRepository
        self.conversationsRepository = conversationsRepository
        self.userRepository = userRepository
        self.conversationLabelsRepository = conversationLabelsRepository
        self.featureConfigsRepository = featureConfigsRepository
        self.backendConfigRepository = backendConfigRepository
        self.updateEventProcessor = updateEventProcessor
        self.pushSupportedProtocolsUseCase = pushSupportedProtocolsUseCase
        self.mlsProvider = mlsProvider
        self.context = context
    }

    func performSlowSync() async throws {
        do {
            syncTimeTracker.reset()

            logSyncPhaseStarted(for: .pullingLastUpdateEventID)
            try await updateEventsRepository.pullLastEventID()
            logSyncPhaseCompleted(for: .pullingLastUpdateEventID)

            logSyncPhaseStarted(for: .pullingSelfTeam)
            try await teamRepository.pullSelfTeam()
            logSyncPhaseCompleted(for: .pullingSelfTeam)

            logSyncPhaseStarted(for: .pullingSelfTeamRoles)
            try await teamRepository.pullSelfTeamRoles()
            logSyncPhaseCompleted(for: .pullingSelfTeamRoles)

            logSyncPhaseStarted(for: .pullingSelfTeamMembers)
            try await teamRepository.pullSelfTeamMembers()
            logSyncPhaseCompleted(for: .pullingSelfTeamMembers)

            logSyncPhaseStarted(for: .pullingConnections)
            try await connectionsRepository.pullConnections()
            logSyncPhaseCompleted(for: .pullingConnections)

            logSyncPhaseStarted(for: .pullingConversations)
            try await conversationsRepository.pullConversations()
            logSyncPhaseCompleted(for: .pullingConversations)

            logSyncPhaseStarted(for: .pullingKnownUsers)
            try await userRepository.pullKnownUsers()
            logSyncPhaseCompleted(for: .pullingKnownUsers)

            logSyncPhaseStarted(for: .pullingSelfUser)
            try await userRepository.pullSelfUser()
            logSyncPhaseCompleted(for: .pullingSelfUser)

            logSyncPhaseStarted(for: .pullingSelfLegalholdInfo)
            try await teamRepository.pullSelfLegalholdInfo()
            logSyncPhaseCompleted(for: .pullingSelfLegalholdInfo)

            logSyncPhaseStarted(for: .pullingConversationLabels)
            try await conversationLabelsRepository.pullConversationLabels()
            logSyncPhaseCompleted(for: .pullingConversationLabels)

            logSyncPhaseStarted(for: .pullingFeatureConfigs)
            try await featureConfigsRepository.pullFeatureConfigs()
            logSyncPhaseCompleted(for: .pullingFeatureConfigs)

            logSyncPhaseStarted(for: .pullingMLSBackendStatus)
            await backendConfigRepository.pullMLSBackendStatus()
            logSyncPhaseCompleted(for: .pullingMLSBackendStatus)

            logSyncPhaseStarted(for: .pushingSupportedProtocols)
            try await pushSupportedProtocolsUseCase.invoke()
            logSyncPhaseCompleted(for: .pushingSupportedProtocols)

            logSyncPhaseStarted(for: .resolvingOneOnOneConversations)
            let oneOnOneResolver = makeOneOnOneResolver()
            try await oneOnOneResolver.resolveAllOneOnOneConversations()
            logSyncPhaseCompleted(for: .resolvingOneOnOneConversations, completedAllPhases: true)

        } catch {
            throw Failure.failedToPerformSlowSync(error)
        }
    }

    private func makeOneOnOneResolver() -> OneOnOneResolverProtocol {
        OneOnOneResolver(
            context: context,
            userRepository: userRepository,
            conversationsRepository: conversationsRepository,
            mlsProvider: mlsProvider
        )
    }

    func performQuickSync() async throws {
        if case .quickSync = syncState {
            return
        }

        WireLogger.sync.info("performing quick sync")

        // Opens the push channel, but events are buffered.
        let liveEventsStream = try await updateEventsRepository.startBufferingLiveEvents()

        let quickSyncTask = Task {
            try await updateEventsRepository.pullPendingEvents()
            try await processStoredEvents()
        }

        do {
            syncState = .quickSync(quickSyncTask)

            syncTimeTracker.reset()

            logSyncPhaseStarted(for: .pullPendingEvents)

            try await quickSyncTask.value

            logSyncPhaseCompleted(
                for: .pullPendingEvents,
                completedAllPhases: true
            )

        } catch {
            try await suspend()
            throw error
        }

        let liveTask = Task {
            do {
                for try await envelope in liveEventsStream {
                    WireLogger.sync.info(
                        "received live event",
                        attributes: [.eventEnvelopeID: envelope.id]
                    )
                    try Task.checkCancellation()
                    await processLiveEvents(in: envelope)
                }
            } catch is CancellationError {
                WireLogger.sync.info("live task was cancelled")
            } catch {
                WireLogger.sync.error("live task encountered error: \(error)")
                try await suspend()
                throw error
            }
        }

        syncState = .live(liveTask)
    }

    func suspend() async throws {
        if case .suspended = syncState {
            return
        }

        guard !isSuspending else {
            return
        }

        WireLogger.sync.info("suspending")

        isSuspending = true
        await closePushChannel()
        ongoingTask?.cancel()
        syncState = .suspended
        isSuspending = false
    }

    private var ongoingTask: Task<Void, Swift.Error>? {
        switch syncState {
        case let .quickSync(task):
            task
        default:
            nil
        }
    }

    // MARK: - Live events

    private func closePushChannel() async {
        await updateEventsRepository.stopReceivingLiveEvents()
    }

    private func processLiveEvents(in envelope: UpdateEventEnvelope) async {
        for event in envelope.events {
            do {
                try await updateEventProcessor.processEvent(event)
            } catch {
                WireLogger.sync.error("failed to process live event, dropping: \(error)")
            }
        }

        if !envelope.isTransient {
            updateEventsRepository.storeLastEventEnvelopeID(envelope.id)
        }
    }

    // MARK: - Event processing

    private func processStoredEvents() async throws {
        let batchSize: UInt = 500

        while true {
            // If we need to abort, do it before processing the next batch.
            try Task.checkCancellation()

            let envelopes = try await updateEventsRepository.fetchNextPendingEvents(limit: batchSize)

            guard !envelopes.isEmpty else {
                break
            }

            WireLogger.sync.debug("fetched \(envelopes.count) stored envelopes for processing")

            for event in envelopes.flatMap(\.events) {
                do {
                    try await updateEventProcessor.processEvent(event)
                } catch {
                    WireLogger.sync.error("failed to process stored event, dropping: \(error)")
                }
            }

            try await updateEventsRepository.deleteNextPendingEvents(limit: batchSize)
        }
    }

    private func logSyncPhaseStarted(
        for phase: SyncPhaseName
    ) {
        let syncType = phase != .pullPendingEvents ? "slow sync" : "quick sync"
        let attributes: LogAttributes = [
            .syncType: syncType,
            .syncSystem: "new",
            .syncPhase: phase.rawValue,
            .public: true
        ]

        WireLogger.sync.info("Started sync phase", attributes: attributes)
    }

    private func logSyncPhaseCompleted(
        for phase: SyncPhaseName,
        completedAllPhases: Bool = false
    ) {
        let syncType = phase != .pullPendingEvents ? "slow sync" : "quick sync"
        let currentTime = Date.now
        let duration = currentTime.timeIntervalSince(syncTimeTracker.phaseStartTime)
        let message = "Completed sync phase"
        let logAttributes: LogAttributes = [
            .syncType: syncType,
            .duration: String(duration),
            .syncSystem: "new",
            .syncPhase: phase.rawValue,
            .public: true
        ]

        WireLogger.sync.info(message, attributes: logAttributes)

        syncTimeTracker.addPhaseDuration(duration)
        syncTimeTracker.resetStartTime() // reset for next sync phase

        if completedAllPhases {
            let message = "Completed \(syncType)"
            let syncTotalDuration = syncTimeTracker.totalSyncDuration()
            let logAttributes: LogAttributes = [
                .syncType: syncType,
                .syncSystem: "new",
                .duration: String(syncTotalDuration),
                .public: true
            ]

            WireLogger.sync.info(message, attributes: logAttributes)
            syncTimeTracker.reset() // Sync is completed and logged, resetting tracked time values
        }
    }

}

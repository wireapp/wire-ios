//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireSystem

protocol SyncManagerProtocol {

    /// Pulls and stores all required objects for the database to be initially up-to-date.

    func performSlowSync() async throws

    /// Fetch events from the server and process all pending events.

    func performQuickSync() async throws

    /// Stop all syncing activities and prepare to idle.

    func suspend() async throws

}

public struct MLSProvider {
    let service: any MLSServiceInterface
    let isMLSEnabled: Bool

    public init(
        service: any MLSServiceInterface,
        isMLSEnabled: Bool
    ) {
        self.service = service
        self.isMLSEnabled = isMLSEnabled
    }
}

final class SyncManager: SyncManagerProtocol {

    enum Error: Swift.Error {
        case failedToPerformSlowSync(Swift.Error)
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
    private let pushSupportedProtocolsUseCase: any PushSupportedProtocolsUseCaseProtocol
    private let mlsProvider: MLSProvider
    private let context: NSManagedObjectContext

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
        self.updateEventProcessor = updateEventProcessor
        self.pushSupportedProtocolsUseCase = pushSupportedProtocolsUseCase
        self.mlsProvider = mlsProvider
        self.context = context
    }

    func performSlowSync() async throws {
        do {
            try await updateEventsRepository.pullLastEventID()
            try await teamRepository.pullSelfTeam()
            try await teamRepository.pullSelfTeamRoles()
            try await teamRepository.pullSelfTeamMembers()
            try await connectionsRepository.pullConnections()
            try await conversationsRepository.pullConversations()
            try await userRepository.pullKnownUsers()
            try await userRepository.pullSelfUser()
            try await teamRepository.pullSelfLegalholdInfo()
            try await conversationLabelsRepository.pullConversationLabels()
            try await featureConfigsRepository.pullFeatureConfigs()
            try await pushSupportedProtocolsUseCase.invoke()
            let oneOnOneResolver = makeOneOnOneResolver()
            try await oneOnOneResolver.invoke()
        } catch {
            throw Error.failedToPerformSlowSync(error)
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
            try await quickSyncTask.value
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
        case .quickSync(let task):
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

}

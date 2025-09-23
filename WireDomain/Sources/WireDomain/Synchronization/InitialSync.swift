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
import WireLogging

public struct InitialSync: InitialSyncProtocol {

    private let pullLastUpdateEventIDSync: any PullLastUpdateEventIDSyncProtocol
    private let pullResourcesSync: any PullResourcesSyncProtocol
    private let pushSupportedProtocolsUseCase: any PushSupportedProtocolsUseCaseProtocol
    private let oneOnOneResolver: any OneOnOneResolverProtocol
    private let syncStateSubject: CurrentValueSubject<SyncState, Never>

    private let logger = WireLogger.sync

    public init(
        pullLastUpdateEventIDSync: any PullLastUpdateEventIDSyncProtocol,
        pullResourcesSync: any PullResourcesSyncProtocol,
        pushSupportedProtocolsUseCase: any PushSupportedProtocolsUseCaseProtocol,
        oneOnOneResolver: any OneOnOneResolverProtocol,
        syncStateSubject: CurrentValueSubject<SyncState, Never>
    ) {
        self.pullLastUpdateEventIDSync = pullLastUpdateEventIDSync
        self.pullResourcesSync = pullResourcesSync
        self.pushSupportedProtocolsUseCase = pushSupportedProtocolsUseCase
        self.oneOnOneResolver = oneOnOneResolver
        self.syncStateSubject = syncStateSubject
    }

    public func perform(skipPullingLastUpdateEventID: Bool) async throws {
        try await logger.measureTime(
            label: "new initial sync",
            attributes: .initialSync
        ) {
            if !skipPullingLastUpdateEventID {
                try await pullLastUpdateEventID()
            }
            try await pullResources()
            try await pushSupportedProtocols()
            try await resolveOneOnOneConversations()
        }
    }

    private func pullLastUpdateEventID() async throws {
        let phase = "pulling last update event id"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                syncStateSubject.send(.initialSyncing(.pullLastEventID))
                try await pullLastUpdateEventIDSync.pull()
            } catch {
                throw Failure(phase: phase, reason: error)
            }
        }
    }

    private func pullResources() async throws {
        try await logger.measureTime(label: "pull resources") {
            do {
                syncStateSubject.send(.initialSyncing(.pullResources))
                try await pullResourcesSync.pull()
            } catch {
                throw Failure(phase: "perform resource sync", reason: error)
            }
        }
    }

    private func pushSupportedProtocols() async throws {
        let phase = "push supported protocols"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                syncStateSubject.send(.initialSyncing(.pushSupportedProtocols))
                try await pushSupportedProtocolsUseCase.invoke()
            } catch {
                throw Failure(phase: phase, reason: error)
            }
        }
    }

    private func resolveOneOnOneConversations() async throws {
        let phase = "resolve one on one conversations"

        try await logger.measureTime(
            label: "sync phase",
            attributes: .initialSyncAttributes(phase)
        ) {
            do {
                syncStateSubject.send(.initialSyncing(.resolveOneOnOneConversations))
                try await oneOnOneResolver.resolveAllOneOnOneConversations()
            } catch {
                throw Failure(phase: phase, reason: error)
            }
        }
    }

}

extension InitialSync {

    struct Failure: Error {

        let phase: String
        let reason: any Error

        var description: String {
            "Failed to peform full sync phase '\(phase)': \(reason)"
        }

    }

}

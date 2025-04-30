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
import WireLogging

public struct InitialSync: InitialSyncProtocol {

    private let pullLastUpdateEventIDSync: any PullLastUpdateEventIDSyncProtocol
    private let pullResourcesSync: any PullResourcesSyncProtocol
    private let pushSupportedProtocolsUseCase: any PushSupportedProtocolsUseCaseProtocol
    private let oneOnOneResolver: any OneOnOneResolverProtocol

    private let logger = WireLogger(tag: "initial-sync")

    public init(
        pullLastUpdateEventIDSync: any PullLastUpdateEventIDSyncProtocol,
        pullResourcesSync: any PullResourcesSyncProtocol,
        pushSupportedProtocolsUseCase: any PushSupportedProtocolsUseCaseProtocol,
        oneOnOneResolver: any OneOnOneResolverProtocol
    ) {
        self.pullLastUpdateEventIDSync = pullLastUpdateEventIDSync
        self.pullResourcesSync = pullResourcesSync
        self.pushSupportedProtocolsUseCase = pushSupportedProtocolsUseCase
        self.oneOnOneResolver = oneOnOneResolver
    }

    public func perform(skipPullingLastUpdateEventID: Bool) async throws {
        try await log(
            label: "new initial sync",
            attributes: .newInitialSyncDidStartAttributes()
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
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("pulling last update event id")
        ) {
            do {
                try await pullLastUpdateEventIDSync.pull()
            } catch {
                throw Failure(phase: "pull last update event id", reason: error)
            }
        }
    }

    private func pullResources() async throws {
        do {
            logger.debug("pulling resources")
            try await pullResourcesSync.pull()
        } catch {
            throw Failure(phase: "perform resource sync", reason: error)
        }
    }

    private func pushSupportedProtocols() async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("push supported protocols")
        ) {
            do {
                try await pushSupportedProtocolsUseCase.invoke()
            } catch {
                throw Failure(phase: "push supported protocols", reason: error)
            }
        }
    }

    private func resolveOneOnOneConversations() async throws {
        try await log(
            label: "sync phase",
            attributes: .newInitialSyncPhaseAttributes("resolve one on one conversations")
        ) {
            do {
                try await oneOnOneResolver.resolveAllOneOnOneConversations()
            } catch {
                throw Failure(phase: "resolve one on one conversations", reason: error)
            }
        }
    }
    
    private func log(
        label: String,
        attributes: LogAttributes,
        block: () async throws -> Void
    ) async throws  {
        let startMessage = "did start \(label)"
        logger.info(startMessage, attributes: attributes)
        let start = Date.now
        try await block()
        let durationInSeconds = start.timeIntervalSinceNow.magnitude
        var updatedAttributes = attributes
        updatedAttributes[.duration] = String(format: "%.2f", durationInSeconds)
        let completedMessage = "did complete \(label)"
        logger.info(completedMessage, attributes: updatedAttributes)
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

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

import Foundation

public protocol MigrateConversationToMLSUseCaseProtocol {

    /// Migrates one team group conversation from Proteus or mixed mode to MLS.
    ///
    /// Calling this method for an MLS conversation succeeds without performing any work.
    func invoke(
        conversationID: QualifiedID,
        syncContext: NSManagedObjectContext
    ) async throws

}

public final class MigrateConversationToMLSUseCase: MigrateConversationToMLSUseCaseProtocol {

    public enum Failure: Error, Equatable {
        case conversationNotFound
        case unsupportedConversation
        case missingMLSService
        case missingMLSGroupID
    }

    private let actionsProvider: any MLSActionsProviderProtocol

    public convenience init() {
        self.init(actionsProvider: MLSActionsProvider())
    }

    init(actionsProvider: any MLSActionsProviderProtocol) {
        self.actionsProvider = actionsProvider
    }

    public func invoke(
        conversationID: QualifiedID,
        syncContext: NSManagedObjectContext
    ) async throws {
        let isSyncContext = await syncContext.perform { syncContext.zm_isSyncContext }
        precondition(isSyncContext, "use case should only be accessed on the sync context")

        switch try await messageProtocol(for: conversationID, in: syncContext) {
        case .mls:
            return

        case .mixed:
            try await finaliseMigration(conversationID: conversationID, syncContext: syncContext)

        case .proteus:
            try await startMigration(conversationID: conversationID, syncContext: syncContext)
            try await finaliseMigration(conversationID: conversationID, syncContext: syncContext)
        }
    }

    private func messageProtocol(
        for conversationID: QualifiedID,
        in context: NSManagedObjectContext
    ) async throws -> MessageProtocol {
        try await context.perform {
            guard let conversation = ZMConversation.fetch(
                with: conversationID.uuid,
                domain: conversationID.domain,
                in: context
            ) else {
                throw Failure.conversationNotFound
            }

            let selfUser = ZMUser.selfUser(in: context)
            guard conversation.conversationType == .group,
                  conversation.teamRemoteIdentifier == selfUser.teamIdentifier
            else {
                throw Failure.unsupportedConversation
            }

            return conversation.messageProtocol
        }
    }

    private func startMigration(
        conversationID: QualifiedID,
        syncContext: NSManagedObjectContext
    ) async throws {
        try await updateConversationProtocol(
            conversationID: conversationID,
            to: .mixed,
            syncContext: syncContext
        )

        let (mlsService, groupID, members) = try await syncContext.perform {
            guard let conversation = ZMConversation.fetch(
                with: conversationID.uuid,
                domain: conversationID.domain,
                in: syncContext
            ) else {
                throw Failure.conversationNotFound
            }

            guard let mlsService = syncContext.mlsService else {
                throw Failure.missingMLSService
            }

            guard let groupID = conversation.mlsGroupID else {
                throw Failure.missingMLSGroupID
            }

            let members = conversation.localParticipants.map {
                MLSUser(from: $0, localDomain: mlsService.localDomain)
            }

            return (mlsService, groupID, members)
        }

        _ = try await mlsService.establishGroup(
            for: groupID,
            with: members,
            removalKeys: nil
        )
    }

    private func finaliseMigration(
        conversationID: QualifiedID,
        syncContext: NSManagedObjectContext
    ) async throws {
        let (mlsService, groupID) = try await syncContext.perform {
            guard let conversation = ZMConversation.fetch(
                with: conversationID.uuid,
                domain: conversationID.domain,
                in: syncContext
            ) else {
                throw Failure.conversationNotFound
            }

            guard let mlsService = syncContext.mlsService else {
                throw Failure.missingMLSService
            }

            guard let groupID = conversation.mlsGroupID else {
                throw Failure.missingMLSGroupID
            }

            return (mlsService, groupID)
        }

        if try await !mlsService.conversationExists(groupID: groupID) {
            try await mlsService.joinGroup(with: groupID)
        }

        try await updateConversationProtocol(
            conversationID: conversationID,
            to: .mls,
            syncContext: syncContext
        )
    }

    private func updateConversationProtocol(
        conversationID: QualifiedID,
        to messageProtocol: MessageProtocol,
        syncContext: NSManagedObjectContext
    ) async throws {
        try await actionsProvider.updateConversationProtocol(
            qualifiedID: conversationID,
            messageProtocol: messageProtocol,
            context: syncContext.notificationContext
        )

        try await actionsProvider.syncConversation(
            qualifiedID: conversationID,
            context: syncContext.notificationContext
        )
    }

}

extension MigrateConversationToMLSUseCase.Failure: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .conversationNotFound:
            "The conversation could not be found."
        case .unsupportedConversation:
            "Only team group conversations can be migrated."
        case .missingMLSService:
            "The MLS service is unavailable."
        case .missingMLSGroupID:
            "The conversation does not have an MLS group ID."
        }
    }

}

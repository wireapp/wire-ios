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
import WireCallingDomain
import WireDataModel
import WireDomain
import WireFoundation
import WireSyncEngine

/// Bridges `WireDomain`'s `ConversationRepositoryProtocol` into `WireCallingDomain`'s
/// `MeetingConversationRepositoryProtocol`, so the meetings feature can pull meeting
/// conversations and add or remove participants (including MLS group establishment)
/// without depending on `WireDomain` directly.
struct MeetingConversationRepositoryBridge: MeetingConversationRepositoryProtocol, @unchecked Sendable {

    let conversationRepository: any ConversationRepositoryProtocol
    let contextProvider: any ContextProvider
    let participantsService: any ConversationParticipantsServiceInterface

    func pullConversation(id: UUID, domain: String) async throws {
        try await conversationRepository.pullConversation(id: id, domain: domain)
    }

    func addParticipants(
        _ participants: [MeetingMember],
        to conversationID: WireCallingDomain.QualifiedID
    ) async throws {
        guard !participants.isEmpty else { return }

        guard let conversation = await conversationRepository.fetchConversation(
            id: conversationID.id,
            domain: conversationID.domain
        ) else { return }

        let objectID = conversation.objectID
        let syncContext = contextProvider.syncContext

        let (mlsGroupID, isGroupEstablished) = await syncContext.perform {
            guard
                let conv = ZMConversation.existingObject(for: objectID, in: syncContext),
                conv.messageProtocol == .mls
            else { return (nil as MLSGroupID?, false) }
            return (conv.mlsGroupID, conv.mlsStatus == .ready)
        }

        guard let mlsGroupID else { return }

        if isGroupEstablished {
            // The group already exists (the meeting is being edited), so the
            // participants are added with a regular add-members commit.
            try await updateParticipants(participants, in: objectID, syncContext: syncContext) {
                try await participantsService.addParticipants($0, to: $1)
            }
        } else {
            try await addMLSParticipants(
                participants,
                to: mlsGroupID,
                conversationObjectID: objectID,
                syncContext: syncContext,
                mlsService: syncContext.performAndWait { syncContext.mlsService }
            )
        }
    }

    func removeParticipants(
        _ participants: [MeetingMember],
        from conversationID: WireCallingDomain.QualifiedID
    ) async throws {
        guard !participants.isEmpty else { return }

        guard let conversation = await conversationRepository.fetchConversation(
            id: conversationID.id,
            domain: conversationID.domain
        ) else { return }

        try await updateParticipants(
            participants,
            in: conversation.objectID,
            syncContext: contextProvider.syncContext
        ) { users, conversation in
            for user in users {
                try await participantsService.removeParticipant(user, from: conversation)
            }
        }
    }

    func leaveConversation(id conversationID: WireCallingDomain.QualifiedID) async throws {
        let syncContext = contextProvider.syncContext
        let resolved = await syncContext.perform {
            let conversation = ZMConversation.fetch(
                with: conversationID.id,
                domain: conversationID.domain,
                in: syncContext
            )
            let selfUser = ZMUser.selfUser(in: syncContext)
            return (
                conversation: conversation,
                selfUser: selfUser,
                isMeeting: conversation?.isMeeting == true,
                hasSelfUserID: selfUser.qualifiedID != nil
            )
        }

        guard
            let conversation = resolved.conversation,
            resolved.isMeeting,
            resolved.hasSelfUserID
        else {
            throw ConversationRemoveParticipantError.invalidOperation
        }

        do {
            try await participantsService.removeParticipant(resolved.selfUser, from: conversation)
        } catch ConversationRemoveParticipantError.conversationNotFound {
            // The current user already left, so the requested state exists.
        }
    }

    func setConversationName(
        _ name: String,
        for conversationID: WireCallingDomain.QualifiedID
    ) async throws {
        guard let conversation = await conversationRepository.fetchConversation(
            id: conversationID.id,
            domain: conversationID.domain
        ) else { return }

        let objectID = conversation.objectID
        // The name must be changed on the view context: only view context
        // saves update `keysThatHaveLocalModifications`, which is what the
        // request strategy uses to push the new name to the backend.
        // Note that this is the regular conversation-rename pipeline, so it
        // also inserts a "... renamed the conversation" system message.
        let viewContext = contextProvider.viewContext

        await viewContext.perform {
            guard
                let conv = ZMConversation.existingObject(for: objectID, in: viewContext),
                conv.userDefinedName != name
            else { return }
            conv.userDefinedName = name
            _ = viewContext.saveOrRollback()
        }
    }

    /// Resolves the meeting members and the conversation into their managed
    /// objects on the sync context and hands them to `operation`. Members
    /// unknown to the local store are skipped.
    private func updateParticipants(
        _ participants: [MeetingMember],
        in conversationObjectID: NSManagedObjectID,
        syncContext: NSManagedObjectContext,
        operation: ([ZMUser], ZMConversation) async throws -> Void
    ) async throws {
        let (users, conversation) = await syncContext.perform { () -> ([ZMUser], ZMConversation?) in
            let users = participants.compactMap { member in
                ZMUser.fetch(
                    with: member.qualifiedID.id,
                    domain: member.qualifiedID.domain,
                    in: syncContext
                )
            }
            let conversation: ZMConversation? = ZMConversation.existingObject(
                for: conversationObjectID,
                in: syncContext
            )
            return (users, conversation)
        }

        guard let conversation, !users.isEmpty else { return }

        try await operation(users, conversation)
    }

    // Establishes the local CoreCrypto group and adds all users in one commit.
    // Using establishGroup (not createGroup + addMembers separately) avoids the
    // mls-client-mismatch 409, which happens when the self user's other devices
    // aren't included in the initial group state before a separate add commit.
    private func addMLSParticipants(
        _ participants: [MeetingMember],
        to mlsGroupID: MLSGroupID,
        conversationObjectID objectID: NSManagedObjectID,
        syncContext: NSManagedObjectContext,
        mlsService: (any MLSServiceInterface)?
    ) async throws {
        guard let mlsService else { return }

        let mlsUsers = participants.map { member in
            MLSUser(id: member.qualifiedID.id, domain: member.qualifiedID.domain)
        }

        let ciphersuite = try await mlsService.establishGroup(
            for: mlsGroupID,
            with: mlsUsers,
            removalKeys: nil
        )

        await syncContext.perform {
            guard let conv = ZMConversation.existingObject(for: objectID, in: syncContext) else { return }
            conv.mlsStatus = .ready
            conv.ciphersuite = ciphersuite
            _ = syncContext.saveOrRollback()
        }
    }

}

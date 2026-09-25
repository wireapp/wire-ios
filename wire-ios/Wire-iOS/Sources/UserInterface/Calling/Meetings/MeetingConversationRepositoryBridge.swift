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

/// Bridges `WireDomain`'s `ConversationRepository` into `WireCallingDomain`'s
/// `MeetingConversationRepositoryProtocol`, so the meetings feature can pull meeting
/// conversations and add or remove participants (including MLS group establishment)
/// without depending on `WireDomain` directly.
struct MeetingConversationRepositoryBridge: MeetingConversationRepositoryProtocol, @unchecked Sendable {

    let conversationRepository: ConversationRepository
    let contextProvider: any ContextProvider
    let participantsService: any ConversationParticipantsServiceInterface
    let isNetworkAvailable: @MainActor () -> Bool

    func pullConversation(id: UUID, domain: String) async throws {
        try await conversationRepository.pullConversation(id: id, domain: domain)
    }

    func addParticipants(
        _ participants: [MeetingMember],
        to conversationID: WireCallingDomain.QualifiedID
    ) async throws {
        guard let conversation = await conversationRepository.fetchConversation(
            id: conversationID.id,
            domain: conversationID.domain
        ) else { throw MLSService.MLSGroupCreationError.failedToCreateGroup }

        let objectID = conversation.objectID
        let syncContext = contextProvider.syncContext

        let (mlsGroupID, isGroupEstablished) = await syncContext.perform {
            guard
                let conv = ZMConversation.existingObject(for: objectID, in: syncContext),
                conv.messageProtocol == .mls
            else { return (nil as MLSGroupID?, false) }
            return (conv.mlsGroupID, conv.mlsStatus == .ready)
        }

        guard let mlsGroupID else { throw MLSService.MLSGroupCreationError.failedToCreateGroup }

        if isGroupEstablished {
            guard !participants.isEmpty else { return }
            // The group already exists (the meeting is being edited), so the
            // participants are added with a regular add-members commit.
            try await updateParticipants(participants, in: objectID, syncContext: syncContext) { users, conversation in
                try await participantsService.addParticipants(users, to: conversation)
                let (failedParticipants, isGroupReady) = await syncContext.perform {
                    let currentIDs = Set(conversation.localParticipants.compactMap(\.qualifiedID))
                    let failedParticipants = participants.filter {
                        !currentIDs.contains(WireDataModel.QualifiedID(
                            uuid: $0.qualifiedID.id,
                            domain: $0.qualifiedID.domain
                        ))
                    }
                    let isGroupReady = !conversation.isDeleted && conversation.mlsGroupID == mlsGroupID &&
                        conversation.mlsStatus == .ready
                    return (failedParticipants, isGroupReady)
                }
                guard isGroupReady else {
                    throw MeetingParticipantsError.failedToSetUpParticipants(failedParticipants)
                }
                if !failedParticipants.isEmpty {
                    throw MeetingParticipantsError.failedToAddParticipants(failedParticipants)
                }
            }
        } else {
            // The group must be established even with no extra participants
            // (a solo "Meet Now" instant meeting): without this, the
            // conversation's MLS group never gets created, and starting the
            // call later fails silently when it tries to set up the
            // conference against a non-existent parent group.
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
        ) else { throw ConversationRemoveParticipantError.conversationNotFound }

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
        guard await isNetworkAvailable() else { throw URLError(.notConnectedToInternet) }

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
        ) else { throw MLSService.MLSGroupCreationError.failedToCreateGroup }

        let objectID = conversation.objectID
        // The name must be changed on the view context: only view context
        // saves update `keysThatHaveLocalModifications`, which is what the
        // request strategy uses to push the new name to the backend.
        // Note that this is the regular conversation-rename pipeline, so it
        // also inserts a "... renamed the conversation" system message.
        let viewContext = contextProvider.viewContext

        try await viewContext.perform {
            guard let conv = ZMConversation.existingObject(for: objectID, in: viewContext) else {
                throw MLSService.MLSGroupCreationError.failedToCreateGroup
            }
            guard conv.userDefinedName != name else { return }
            conv.userDefinedName = name
            guard viewContext.saveOrRollback() else { throw MLSService.MLSGroupCreationError.failedToCreateGroup }
        }
    }

    func updateConversationName(
        _ name: String,
        for conversationID: WireCallingDomain.QualifiedID
    ) async throws {
        let syncContext = contextProvider.syncContext
        let isMeeting = try await syncContext.perform {
            guard let conversation = ZMConversation.fetch(
                with: conversationID.id,
                domain: conversationID.domain,
                in: syncContext
            ) else {
                throw ConversationRemoveParticipantError.conversationNotFound
            }
            return conversation.isMeeting
        }

        guard isMeeting else { return }

        try await conversationRepository.renameConversation(
            WireDataModel.QualifiedID(uuid: conversationID.id, domain: conversationID.domain),
            to: name
        )
    }

    /// Resolves the meeting members and the conversation into their managed
    /// objects on the sync context and hands them to `operation`.
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

        guard let conversation else { throw ConversationRemoveParticipantError.conversationNotFound }
        guard users.count == participants.count, !users.isEmpty else {
            throw ConversationRemoveParticipantError.invalidOperation
        }

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
        guard let mlsService else { throw MLSService.MLSGroupCreationError.failedToCreateGroup }

        let mlsUsers = participants.map { member in
            MLSUser(id: member.qualifiedID.id, domain: member.qualifiedID.domain)
        }

        let ciphersuite: MLSCipherSuite
        var failedParticipants: [MeetingMember] = []
        do {
            ciphersuite = try await mlsService.establishGroup(
                for: mlsGroupID,
                with: mlsUsers,
                removalKeys: nil
            )
        } catch let error as MLSService.MLSAddMembersError {
            guard case let .failedToClaimKeyPackages(failedUsers) = error else { throw error }
            guard !participants.isEmpty else { throw error }
            guard !failedUsers.isEmpty, failedUsers.allSatisfy({ mlsUsers.contains($0) }) else {
                throw MeetingParticipantsError.failedToSetUpParticipants(participants)
            }

            failedParticipants = zip(participants, mlsUsers).compactMap { participant, user in
                failedUsers.contains(user) ? participant : nil
            }
            // Failed establishment wipes the group, so recreate it with the eligible invitees and host devices.
            do {
                ciphersuite = try await mlsService.establishGroup(
                    for: mlsGroupID,
                    with: mlsUsers.filter { !failedUsers.contains($0) },
                    removalKeys: nil
                )
            } catch {
                throw MeetingParticipantsError.failedToSetUpParticipants(
                    participants,
                    reasons: participantFailureReasons(for: error, participants: participants)
                )
            }
        } catch let error as SendMLSMessageFailure {
            switch error {
            case .nonFederatingDomains, .unreachableDomains:
                guard !participants.isEmpty else { throw error }
                throw MeetingParticipantsError.failedToSetUpParticipants(
                    participants,
                    reasons: participantFailureReasons(for: error, participants: participants)
                )
            default:
                throw error
            }
        }

        let isGroupReady = await syncContext.perform {
            guard let conv = ZMConversation.existingObject(for: objectID, in: syncContext) else { return false }
            conv.mlsStatus = .ready
            conv.ciphersuite = ciphersuite
            return syncContext.saveOrRollback()
        }

        guard isGroupReady else {
            if !failedParticipants.isEmpty {
                throw MeetingParticipantsError.failedToSetUpParticipants(failedParticipants)
            }
            throw MLSService.MLSGroupCreationError.failedToCreateGroup
        }
        if !failedParticipants.isEmpty {
            throw MeetingParticipantsError.failedToAddParticipants(failedParticipants)
        }
    }

    private func participantFailureReasons(
        for error: Error,
        participants: [MeetingMember]
    ) -> [WireCallingDomain.QualifiedID: MeetingParticipantFailureReason] {
        var reasons: [WireCallingDomain.QualifiedID: MeetingParticipantFailureReason] = [:]
        for participant in participants {
            let id = participant.qualifiedID
            switch error {
            case let SendMLSMessageFailure.nonFederatingDomains(domains) where domains.contains(id.domain):
                reasons[id] = .nonFederatingBackends
            case let SendMLSMessageFailure.unreachableDomains(domains) where domains.contains(id.domain):
                reasons[id] = .offlineBackend(domain: id.domain)
            default:
                break
            }
        }
        return reasons
    }

}

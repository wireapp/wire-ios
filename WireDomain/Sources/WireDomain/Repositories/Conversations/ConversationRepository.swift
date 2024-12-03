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

import Foundation
import WireAPI
import WireDataModel

// sourcery: AutoMockable
/// Facilitate access to conversations related domain objects.
public protocol ConversationRepositoryProtocol {

    /// Fetches and persists a conversation with a given ID.
    /// - Parameters:
    ///     - id: The ID of the conversation.
    ///     - domain: The domain of the conversation.

    func pullConversation(
        id: UUID,
        domain: String
    ) async throws

    /// Fetches a conversation locally.
    /// - Parameters:
    ///     - id: The ID of the conversation.
    ///     - domain: The domain of the conversation if any.
    /// - returns: The `ZMConversation` found locally.

    func fetchConversation(
        id: UUID,
        domain: String?
    ) async -> ZMConversation?

    /// Stores a conversation locally.
    /// - Parameters:
    ///     - conversation: The conversation to update or create locally.
    ///     - timestamp: The date the conversation was created or last modified.

    func storeConversation(
        _ conversation: WireAPI.Conversation,
        timestamp: Date
    ) async

    /// Fetches or creates a conversation locally.
    /// - parameter id: The ID of the conversation.
    /// - parameter domain: The domain of the conversation if any.
    ///
    /// - returns: The `ZMConversation` found or created locally.

    func fetchOrCreateConversation(
        id: UUID,
        domain: String?
    ) async -> ZMConversation

    /// Fetches and persists all conversations

    func pullConversations() async throws

    /// Pulls and stores a MLS one to one conversation locally.
    ///
    /// - parameters:
    ///     - userID: The user ID.
    ///     - userDomain: The user domain.
    ///
    /// - returns : The MLS group ID.

    func pullMLSOneToOneConversation(
        userID: String,
        userDomain: String
    ) async throws -> String

    /// Fetches a MLS conversation locally.
    ///
    /// - parameters:
    ///     - groupID: The MLS group ID.
    ///
    /// - returns : A MLS conversation.

    func fetchMLSConversation(
        groupID: String
    ) async -> ZMConversation?

    /// Deletes a conversation locally.
    /// - Parameters:
    ///     - id: The ID of the conversation.
    ///     - domain: The domain of the conversation if any.

    func deleteConversation(
        id: UUID,
        domain: String?
    ) async throws

    /// Removes a given user from all group conversations.
    ///
    /// - parameters:
    ///     - participantID: The user ID.
    ///     - participantDomain: The user domain.
    ///     - date: The date the user was removed from the conversations.

    func removeParticipantFromAllGroupConversations(
        participantID: UUID,
        participantDomain: String?,
        removedAt date: Date
    ) async throws

    /// Adds a participant or updates its role in a conversation.
    ///
    /// - Parameters:
    ///     - participantID: The participant ID.
    ///     - participantDomain: The participant domain if any.
    ///     - participantRole: The role of the user.
    ///     - conversationID: The conversation ID.
    ///     - conversationDomain: The conversation domain if any.
    ///
    /// If user is already part of the conversation, its role will be updated.
    /// If not, user will be added to the conversation.

    func addOrUpdateParticipant(
        participantID: UUID,
        participantDomain: String?,
        participantRole: String,
        conversationID: UUID,
        conversationDomain: String?
    ) async

    /// Adds new participants to a conversation.
    /// - Parameters:
    ///     - newParticipants: The id, domain and role of the new participant.
    ///     - sender: The user who added the participants.
    ///     - date: The date the participants were added.
    ///     - conversationID: The conversation ID.
    ///     - conversationDomain: The conversation domain.

    func addParticipants(
        _ participants: [(id: UUID, domain: String?, role: String?)],
        sender: (id: UUID, domain: String?),
        date: Date,
        conversationID: UUID,
        conversationDomain: String
    ) async throws

    /// Removes members from a conversation, deletes membership and wipe MLS group if needed.
    ///
    /// - Parameters:
    ///     - userIDs: The users to remove.
    ///     - conversation: The conversation the removed users are part of.
    ///     - initiatedBy: The user (sender) that initiated that removal.
    ///     - date: The date the members were removed.
    ///     - reason: The reason the members were removed.

    func removeMembers(
        _ userIDs: Set<UserID>,
        from conversation: ConversationID,
        initiatedBy sender: UserID,
        at date: Date,
        reason: ConversationMemberLeaveReason
    ) async throws

    /// Updates the conversation name locally.
    /// - Parameters:
    ///     - newName: The new name for the conversation.
    ///     - conversationID: The conversation ID.
    ///     - conversationDomain: The conversation domain.
    ///     - senderID: The user ID.
    ///     - senderDomain: The user domain.
    ///     - date: The date the conversation name was updated.

    func updateConversationName(
        newName: String,
        conversationID: UUID,
        conversationDomain: String?,
        senderID: UUID,
        senderDomain: String?,
        date: Date
    ) async

    /// Fetches the guest link for a given conversation.
    /// - parameter conversationID: The conversation id.
    /// - returns: The guest link.

    func fetchConversationGuestLink(
        conversationID: String
    ) async throws -> String?
}

public final class ConversationRepository: ConversationRepositoryProtocol {

    public struct BackendInfo {
        let domain: String
        let isFederationEnabled: Bool
        let isMLSEnabled: Bool
    }

    // MARK: - Properties

    private let conversationsAPI: any ConversationsAPI
    private let conversationsLocalStore: any ConversationLocalStoreProtocol
    private let userRepository: any UserRepositoryProtocol
    private let teamRepository: any TeamRepositoryProtocol
    private let messageRepository: any MessageRepositoryProtocol
    private let backendInfo: BackendInfo
    private let mlsProvider: MLSProvider

    // MARK: - Object lifecycle

    public init(
        conversationsAPI: any ConversationsAPI,
        conversationsLocalStore: any ConversationLocalStoreProtocol,
        userRepository: any UserRepositoryProtocol,
        teamRepository: any TeamRepositoryProtocol,
        messageRepository: any MessageRepositoryProtocol,
        backendInfo: BackendInfo,
        mlsProvider: MLSProvider
    ) {
        self.conversationsAPI = conversationsAPI
        self.conversationsLocalStore = conversationsLocalStore
        self.userRepository = userRepository
        self.teamRepository = teamRepository
        self.messageRepository = messageRepository
        self.backendInfo = backendInfo
        self.mlsProvider = mlsProvider
    }

    // MARK: - Public

    public func fetchConversationGuestLink(
        conversationID: String
    ) async throws -> String? {

        do {
            return try await conversationsAPI.getConversationGuestLink(
                conversationID: conversationID
            )

        } catch {
            throw ConversationRepositoryError.failedToFetchGuestLink(error)
        }

    }

    public func pullConversation(id: UUID, domain: String) async throws {
        let qualifiedID = WireAPI.QualifiedID(uuid: id, domain: domain)
        let conversationList = try await conversationsAPI.getConversations(
            for: [qualifiedID]
        )

        guard let conversation = conversationList.found.first else {
            throw ConversationRepositoryError.conversationNotFound
        }

        await conversationsLocalStore.storeConversation(
            conversation,
            timestamp: .now,
            isFederationEnabled: backendInfo.isFederationEnabled,
            isMLSEnabled: backendInfo.isMLSEnabled
        )
    }

    public func fetchConversation(
        id: UUID,
        domain: String?
    ) async -> ZMConversation? {
        await conversationsLocalStore.fetchConversation(
            id: id,
            domain: domain
        )
    }

    public func fetchOrCreateConversation(
        id: UUID,
        domain: String?
    ) async -> ZMConversation {
        await conversationsLocalStore.fetchOrCreateConversation(
            id: id,
            domain: domain
        )
    }

    public func storeConversation(
        _ conversation: WireAPI.Conversation,
        timestamp: Date
    ) async {
        await conversationsLocalStore.storeConversation(
            conversation,
            timestamp: timestamp,
            isFederationEnabled: backendInfo.isFederationEnabled,
            isMLSEnabled: backendInfo.isMLSEnabled
        )
    }

    public func pullConversations() async throws {
        var qualifiedIds: [WireAPI.QualifiedID]

        if let result =
            try? await conversationsAPI
                .getLegacyConversationIdentifiers() {  // only for api v0 (see `ConversationsAPIV0` method comment)
            let uuids = try await result.reduce(into: [UUID]()) { partialResult, uuids in
                partialResult.append(contentsOf: uuids)
            }
            qualifiedIds = uuids.map {
                WireAPI.QualifiedID(uuid: $0, domain: backendInfo.domain)
            }
        } else {
            // fallback to api versions > v0.
            let ids = try await conversationsAPI.getConversationIdentifiers()
            qualifiedIds = try await ids.reduce(into: [WireAPI.QualifiedID]()) { partialResult, uuids in
                partialResult.append(contentsOf: uuids)
            }
        }

        let conversationList = try await conversationsAPI.getConversations(
            for: qualifiedIds
        )

        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            let foundConversations = conversationList.found
            let missingConversationsQualifiedIds = conversationList.notFound
            let failedConversationsQualifiedIds = conversationList.failed

            for conversation in foundConversations {
                taskGroup.addTask { [self] in
                    await storeConversation(
                        conversation,
                        timestamp: .now
                    )
                }
            }

            for id in missingConversationsQualifiedIds {
                taskGroup.addTask { [self] in
                    await conversationsLocalStore.storeConversation(
                        needsBackendUpdate: true,
                        qualifiedId: id
                    )
                }
            }

            for id in failedConversationsQualifiedIds {
                taskGroup.addTask { [self] in
                    await conversationsLocalStore.storeFailedConversation(
                        withQualifiedId: id
                    )
                }
            }
        }
    }

    public func pullMLSOneToOneConversation(
        userID: String,
        userDomain: String
    ) async throws -> String {
        let mlsConversation =
            try await conversationsAPI.getMLSOneToOneConversation(
                userID: userID,
                in: userDomain
            )

        guard let mlsGroupID = mlsConversation.mlsGroupID else {
            throw ConversationRepositoryError.mlsConversationShouldHaveAGroupID
        }

        await conversationsLocalStore.storeConversation(
            mlsConversation,
            timestamp: .now,
            isFederationEnabled: backendInfo.isFederationEnabled,
            isMLSEnabled: backendInfo.isMLSEnabled
        )

        return mlsGroupID
    }

    public func fetchMLSConversation(
        groupID: String
    ) async -> ZMConversation? {
        guard let mlsGroupID = MLSGroupID(base64Encoded: groupID) else {
            return nil
        }

        return await conversationsLocalStore.fetchMLSConversation(
            groupID: mlsGroupID
        )
    }

    public func removeParticipantFromAllGroupConversations(
        participantID: UUID,
        participantDomain: String?,
        removedAt date: Date
    ) async throws {

        try await conversationsLocalStore.removeParticipantFromAllGroupConversations(
            participantID: participantID,
            participantDomain: participantDomain,
            date: date
        )
    }

    public func updateConversationName(
        newName: String,
        conversationID: UUID,
        conversationDomain: String?,
        senderID: UUID,
        senderDomain: String?,
        date: Date
    ) async {

        let conversation = await fetchOrCreateConversation(
            id: conversationID,
            domain: conversationDomain
        )

        let currentConversationName = await conversationsLocalStore.conversationName(conversation: conversation)

        if currentConversationName != newName {
            let messageType = MessageType.conversationNameChanged(
                newName: newName,
                sender: (senderID, senderDomain),
                date: date
            )

            await messageRepository.addMessageToConversation(
                messageType: messageType,
                conversationID: conversationID,
                conversationDomain: conversationDomain
            )
        }

        await conversationsLocalStore.storeConversation(
            newName: newName,
            conversation: conversation
        )

    }

    public func deleteConversation(
        id: UUID,
        domain: String?
    ) async throws {
        guard
            let conversation = await fetchConversation(
                id: id,
                domain: domain
            )
        else {
            return WireLogger.conversation.warn(
                "Cannot delete a conversation that doesn't exist locally: \(id.safeForLoggingDescription)"
            )
        }

        let isMLSConversation = await conversationsLocalStore.isMLSConversation(
            conversation
        )

        if isMLSConversation {
            let mlsGroupID = await conversationsLocalStore.mlsGroupID(
                for: conversation
            )

            if let mlsGroupID {
                try await conversationsLocalStore.wipeMLSGroup(
                    groupID: mlsGroupID
                )
            }

            await conversationsLocalStore.deleteConversation(
                conversation
            )

        } else {
            await conversationsLocalStore.deleteConversation(
                conversation
            )
        }
    }

    public func addOrUpdateParticipant(
        participantID: UUID,
        participantDomain: String?,
        participantRole: String,
        conversationID: UUID,
        conversationDomain: String?
    ) async {
        let participant = await userRepository.fetchOrCreateUser(
            id: participantID,
            domain: participantDomain
        )

        let conversation = await fetchOrCreateConversation(
            id: conversationID,
            domain: conversationDomain
        )

        await conversationsLocalStore.addOrUpdateParticipant(
            participant,
            withRole: participantRole,
            in: conversation
        )
    }

    public func addParticipants(
        _ participants: [(id: UUID, domain: String?, role: String?)],
        sender: (id: UUID, domain: String?),
        date: Date,
        conversationID: UUID,
        conversationDomain: String
    ) async throws {
        let conversation = await fetchConversation(
            id: conversationID,
            domain: conversationDomain
        )

        if conversation == nil {
            // Sync conversation
            try await pullConversation(
                id: conversationID,
                domain: conversationDomain
            )
        }

        try await conversationsLocalStore.addParticipants(
            participants,
            addedBy: sender,
            atDate: date,
            conversation: (conversationID, conversationDomain)
        )
    }

    public func removeMembers(
        _ userIDs: Set<UserID>,
        from conversation: ConversationID,
        initiatedBy sender: UserID,
        at date: Date,
        reason: ConversationMemberLeaveReason
    ) async throws {
        let conversationID = conversation.uuid
        let conversationDomain = conversation.domain
        let senderID = sender.uuid
        let senderDomain = sender.domain
        let removedUserIDs = userIDs

        let conversation =
            await conversationsLocalStore.fetchOrCreateConversation(
                id: conversationID,
                domain: conversationDomain
            )

        let removedUsers = await getRemovedUsers(from: removedUserIDs)
        let participants = await conversationsLocalStore.localParticipants(
            in: conversation
        )

        let sender = try await userRepository.fetchUser(
            id: senderID,
            domain: senderDomain
        )

        if !participants.isDisjoint(with: removedUsers) {
            await addSystemMessage(
                conversationID: conversationID,
                conversationDomain: conversationDomain,
                senderID: senderID,
                senderDomain: senderDomain,
                date: date,
                removedUsers: removedUserIDs,
                reason: reason
            )
        }

        let isSelfUserRemoved = await isSelfUserRemoved(in: removedUserIDs)
        let messageProtocol = await conversationsLocalStore.messageProtocol(
            for: conversation
        )

        await conversationsLocalStore
            .removeParticipantsAndUpdateConversationState(
                conversation: conversation,
                users: Set(removedUsers),
                initiatingUser: sender
            )

        let isMLSEnabled = mlsProvider.isMLSEnabled
        let mlsService = mlsProvider.service

        if isMLSEnabled {
            let mlsGroupID = await conversationsLocalStore.mlsGroupID(
                for: conversation
            )

            if isSelfUserRemoved, let mlsGroupID,
               messageProtocol.isOne(of: .mls, .mixed) {
                try await mlsService.wipeGroup(mlsGroupID)
            }
        }

        guard reason == .userDeleted else {
            return
        }

        await deleteMembership(for: removedUserIDs, time: date)
    }

    // MARK: - Private

    private func addSystemMessage(
        conversationID: UUID,
        conversationDomain: String?,
        senderID: UUID,
        senderDomain: String?,
        date: Date,
        removedUsers: Set<UserID>,
        reason: ConversationMemberLeaveReason
    ) async {
        var systemMessageType: MessageType = switch reason {
        case .userDeleted, .userLeft:
            .teamMemberRemoved(
                member: (senderID, senderDomain),
                date: date
            )
        case .userRemoved:
            .participantsRemoved(
                participants: removedUsers.map { ($0.uuid, $0.domain) },
                sender: (senderID, senderDomain),
                date: date
            )
        }

        await messageRepository.addMessageToConversation(
            messageType: systemMessageType,
            conversationID: conversationID,
            conversationDomain: conversationDomain
        )
    }

    private func getRemovedUsers(
        from userIDs: Set<UserID>
    ) async -> [WireDataModel.ZMUser] {
        await withTaskGroup(of: WireDataModel.ZMUser.self) { taskGroup in
            for userID in userIDs {
                taskGroup.addTask { [self] in
                    await userRepository.fetchOrCreateUser(
                        id: userID.uuid,
                        domain: userID.domain
                    )
                }
            }

            var users: [WireDataModel.ZMUser] = []

            for await user in taskGroup {
                users.append(user)
            }

            return users
        }
    }

    private func isSelfUserRemoved(
        in removedUsersIDs: Set<UserID>
    ) async -> Bool {
        await withTaskGroup(of: Bool.self) { taskGroup in
            for removedUserID in removedUsersIDs {
                taskGroup.addTask { [self] in
                    do {
                        return try await userRepository.isSelfUser(
                            id: removedUserID.uuid,
                            domain: removedUserID.domain
                        )

                    } catch {
                        return false
                    }
                }
            }

            return await taskGroup.contains(true)
        }
    }

    private func deleteMembership(
        for userIDs: Set<UserID>,
        time: Date
    ) async {
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for userID in userIDs {
                taskGroup.addTask { [self] in
                    do {
                        try await teamRepository.deleteMembership(
                            userID: userID.uuid,
                            domain: userID.domain,
                            date: time
                        )
                    } catch {
                        WireLogger.eventProcessing.error(
                            "Unable to delete member with id: \(userID.uuid.safeForLoggingDescription)"
                        )
                    }
                }
            }
        }
    }
}

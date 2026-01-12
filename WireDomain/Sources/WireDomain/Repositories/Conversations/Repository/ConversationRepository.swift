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
import WireDataModel
import WireLogging
import WireNetwork

public final class ConversationRepository: ConversationRepositoryProtocol {

    // MARK: - Properties

    private let conversationsAPI: any ConversationsAPI
    private let conversationsLocalStore: any ConversationLocalStoreProtocol
    private let userLocalStore: any UserLocalStoreProtocol
    private let teamRepository: any TeamRepositoryProtocol
    private let messageRepository: any MessageRepositoryProtocol
    private let localDomain: String
    private let isFederationEnabled: Bool
    private let isMLSEnabled: Bool
    private let mlsProvider: MLSProvider

    // MARK: - Object lifecycle

    public init(
        conversationsAPI: any ConversationsAPI,
        conversationsLocalStore: any ConversationLocalStoreProtocol,
        userLocalStore: any UserLocalStoreProtocol,
        teamRepository: any TeamRepositoryProtocol,
        messageRepository: any MessageRepositoryProtocol,
        localDomain: String,
        isFederationEnabled: Bool,
        isMLSEnabled: Bool,
        mlsProvider: MLSProvider
    ) {
        self.conversationsAPI = conversationsAPI
        self.conversationsLocalStore = conversationsLocalStore
        self.userLocalStore = userLocalStore
        self.teamRepository = teamRepository
        self.messageRepository = messageRepository
        self.localDomain = localDomain
        self.isFederationEnabled = isFederationEnabled
        self.isMLSEnabled = isMLSEnabled
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
        let qualifiedID = WireNetwork.QualifiedID(id: id, domain: domain)
        let conversationList = try await conversationsAPI.getConversations(
            for: [qualifiedID]
        )

        
        
        if let conversation = conversationList.found.first {
            await conversationsLocalStore.storeConversation(
                conversation.toDomainModel(),
                timestamp: .now,
                isFederationEnabled: isFederationEnabled,
                isMLSEnabled: isMLSEnabled
            )
        } else if conversationList.notFound.contains(qualifiedID) {
            throw ConversationRepositoryError.conversationNotFound
        } else {
            throw ConversationRepositoryError.conversationFailed
        }

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
        _ conversation: Conversation,
        timestamp: Date
    ) async {
        await conversationsLocalStore.storeConversation(
            conversation,
            timestamp: timestamp,
            isFederationEnabled: isFederationEnabled,
            isMLSEnabled: isMLSEnabled
        )
    }

    public func pullMLSOneToOneConversation(
        userID: String,
        userDomain: String
    ) async throws -> (String, MLSPublicKeys?) {
        let (mlsConversation, mlsPublicKeys) =
            try await conversationsAPI.getMLSOneToOneConversation(
                userID: userID,
                in: userDomain
            )

        guard let mlsGroupID = mlsConversation.mlsGroupID else {
            throw ConversationRepositoryError.mlsConversationShouldHaveAGroupID
        }

        await conversationsLocalStore.storeConversation(
            mlsConversation.toDomainModel(),
            timestamp: .now,
            isFederationEnabled: isFederationEnabled,
            isMLSEnabled: isMLSEnabled
        )

        return (mlsGroupID, mlsPublicKeys)
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
            let messageType = SystemMessageType.conversationNameChanged(
                newName: newName,
                sender: (senderID, senderDomain),
                date: date
            )

            await messageRepository.addSystemMessage(
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

        let mlsConversationInfo = await conversationsLocalStore.mlsConversationInfo(
            conversation: conversation
        )

        let mlsGroupID = mlsConversationInfo?.mlsGroupID

        if let mlsGroupID {

            try await conversationsLocalStore.wipeMLSGroup(groupID: mlsGroupID)

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
        let participant = await userLocalStore.fetchOrCreateUser(
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
        let conversationID = conversation.id
        let conversationDomain = conversation.domain
        let senderID = sender.id
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

        let sender = try await userLocalStore.fetchUser(
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

            let mlsConversationInfo = await conversationsLocalStore.mlsConversationInfo(
                conversation: conversation
            )

            let mlsGroupID = mlsConversationInfo?.mlsGroupID

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

    public func isSelfAnActiveMember(
        in groupID: MLSGroupID
    ) async -> Bool {
        nonisolated(unsafe) var isSelfAnActiveMember = false
        await conversationsLocalStore.execute(identifier: groupID) { conversation, _ in
            isSelfAnActiveMember = conversation?.isSelfAnActiveMember ?? false
        }
        return isSelfAnActiveMember
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
        let systemMessageType: SystemMessageType = switch reason {
        case .userDeleted:
            .teamMemberRemoved(
                member: (senderID, senderDomain),
                date: date
            )
        case .userRemoved, .userLeft:
            .participantsRemoved(
                participants: removedUsers.map { ($0.id, $0.domain) },
                sender: (senderID, senderDomain),
                date: date
            )
        }

        await messageRepository.addSystemMessage(
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
                    await userLocalStore.fetchOrCreateUser(
                        id: userID.id,
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
                        let (_, isSelfUser) = try await userLocalStore.isSelfUser(
                            id: removedUserID.id,
                            domain: removedUserID.domain
                        )
                        return isSelfUser
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
                            userID: userID.id,
                            domain: userID.domain,
                            date: time
                        )
                    } catch {
                        WireLogger.eventProcessing.error(
                            "Unable to delete member with id: \(userID.id.safeForLoggingDescription)"
                        )
                    }
                }
            }
        }
    }
}

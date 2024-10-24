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

    /// Fetches a conversation locally.
    /// - Parameters:
    ///     - id: The ID of the conversation.
    ///     - domain: The domain of the conversation if any.
    /// - returns: The `ZMConversation` found locally.

    func fetchConversation(
        with id: UUID,
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
        with id: UUID,
        domain: String?
    ) async -> ZMConversation

    /// Fetches and persists all conversations

    func pullConversations() async throws

    /// Pulls and stores a MLS one to one conversation locally.
    ///
    /// - parameters:
    ///     - userID: The user ID.
    ///     - domain: The user domain.
    ///
    /// - returns : The MLS group ID.

    func pullMLSOneToOneConversation(
        userID: String,
        domain: String
    ) async throws -> String

    /// Fetches a MLS conversation locally.
    ///
    /// - parameters:
    ///     - groupID: The MLS group ID.
    ///
    /// - returns : A MLS conversation.

    func fetchMLSConversation(
        with groupID: String
    ) async -> ZMConversation?

    /// Removes a given user from all group conversations.
    ///
    /// - parameters:
    ///     - user: The user to remove from the conversations.
    ///     - removalDate: The date the user was removed from the conversations.

    func removeUserFromAllGroupConversations(
        user: ZMUser,
        removalDate: Date
    ) async

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

    /// Adds a system message to a given conversation.
    /// - parameters:
    ///     - message: The system message to add.
    ///     - conversation: The conversation to add the system message to.

    func addSystemMessage(
        _ message: SystemMessage,
        to conversation: ZMConversation
    ) async
}

public final class ConversationRepository: ConversationRepositoryProtocol {

    public struct BackendInfo {
        let domain: String
        let isFederationEnabled: Bool
    }

    // MARK: - Properties

    private let conversationsAPI: any ConversationsAPI
    private let conversationsLocalStore: any ConversationLocalStoreProtocol
    private let userRepository: any UserRepositoryProtocol
    private let teamRepository: any TeamRepositoryProtocol
    private let backendInfo: BackendInfo
    private let mlsProvider: MLSProvider

    // MARK: - Object lifecycle

    public init(
        conversationsAPI: any ConversationsAPI,
        conversationsLocalStore: any ConversationLocalStoreProtocol,
        userRepository: any UserRepositoryProtocol,
        teamRepository: any TeamRepositoryProtocol,
        backendInfo: BackendInfo,
        mlsProvider: MLSProvider
    ) {
        self.conversationsAPI = conversationsAPI
        self.conversationsLocalStore = conversationsLocalStore
        self.userRepository = userRepository
        self.teamRepository = teamRepository
        self.backendInfo = backendInfo
        self.mlsProvider = mlsProvider
    }

    // MARK: - Public

    public func fetchConversation(
        with id: UUID,
        domain: String?
    ) async -> ZMConversation? {
        await conversationsLocalStore.fetchConversation(
            with: id,
            domain: domain
        )
    }
    
    public func fetchOrCreateConversation(
        with id: UUID,
        domain: String?
    ) async -> ZMConversation {
        await conversationsLocalStore.fetchOrCreateConversation(
            with: id,
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
            isFederationEnabled: backendInfo.isFederationEnabled
        )
    }

    public func pullConversations() async throws {
        var qualifiedIds: [WireAPI.QualifiedID]

        if let result = try? await conversationsAPI.getLegacyConversationIdentifiers() { /// only for api v0 (see `ConversationsAPIV0` method comment)
            let uuids = try await result.reduce(into: [UUID]()) { partialResult, uuids in
                partialResult.append(contentsOf: uuids)
            }
            qualifiedIds = uuids.map { WireAPI.QualifiedID(uuid: $0, domain: backendInfo.domain) }
        } else {
            /// fallback to api versions > v0.
            let ids = try await conversationsAPI.getConversationIdentifiers()
            qualifiedIds = try await ids.reduce(into: [WireAPI.QualifiedID]()) { partialResult, uuids in
                partialResult.append(contentsOf: uuids)
            }
        }

        let conversationList = try await conversationsAPI.getConversations(for: qualifiedIds)

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
                    await conversationsLocalStore.storeConversationNeedsBackendUpdate(
                        true,
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
        domain: String
    ) async throws -> String {
        let mlsConversation = try await conversationsAPI.getMLSOneToOneConversation(
            userID: userID,
            in: domain
        )

        guard let mlsGroupID = mlsConversation.mlsGroupID else {
            throw ConversationRepositoryError.mlsConversationShouldHaveAGroupID
        }

        await conversationsLocalStore.storeConversation(
            mlsConversation,
            timestamp: .now,
            isFederationEnabled: backendInfo.isFederationEnabled
        )

        return mlsGroupID
    }

    public func fetchMLSConversation(
        with groupID: String
    ) async -> ZMConversation? {
        guard let mlsGroupID = MLSGroupID(base64Encoded: groupID) else {
            return nil
        }

        return await conversationsLocalStore.fetchMLSConversation(
            with: mlsGroupID
        )
    }

    public func removeUserFromAllGroupConversations(
        user: ZMUser,
        removalDate: Date
    ) async {
        await conversationsLocalStore.removeUserFromAllGroupConversations(
            user: user,
            removalDate: removalDate
        )
    }

    public func removeMembers(
        _ userIDs: Set<UserID>,
        from conversation: ConversationID,
        initiatedBy sender: UserID,
        at time: Date,
        reason: ConversationMemberLeaveReason
    ) async throws {
        let id = conversation.uuid
        let domain = conversation.domain
        let removedUserIDs = userIDs

        let conversation = await conversationsLocalStore.fetchOrCreateConversation(
            with: id,
            domain: domain
        )

        let removedUsers = await getRemovedUsers(from: removedUserIDs)
        let participants = await conversationsLocalStore.getParticipants(from: conversation)

        let sender = try await userRepository.fetchUser(
            with: sender.uuid,
            domain: sender.domain
        )

        if !participants.isDisjoint(with: removedUsers) {
            let systemMessage = SystemMessage(
                type: reason.toDomainModel(),
                sender: sender,
                timestamp: time
            )

            await addSystemMessage(systemMessage, to: conversation)
        }

        let isSelfUserRemoved = await isSelfUserRemoved(in: removedUserIDs)
        let messageProtocol = await conversationsLocalStore.getMessageProtocol(from: conversation)

        await conversationsLocalStore.removeParticipantsAndUpdateConversationState(
            conversation: conversation,
            users: Set(removedUsers),
            initiatingUser: sender
        )

        let isMLSEnabled = mlsProvider.isMLSEnabled
        let mlsService = mlsProvider.service

        if isMLSEnabled {
            let mlsGroupID = await conversationsLocalStore.fetchMLSGroupID(for: conversation)
            if isSelfUserRemoved, let mlsGroupID, messageProtocol.isOne(of: .mls, .mixed) {
                try await mlsService.wipeGroup(mlsGroupID)
            }
        }

        guard reason == .userDeleted else {
            return
        }

        await deleteMembership(for: removedUserIDs, time: time)
    }

    public func addSystemMessage(
        _ message: SystemMessage,
        to conversation: ZMConversation
    ) async {
        await conversationsLocalStore.addSystemMessage(
            message,
            to: conversation
        )
    }

    // MARK: - Private

    private func getRemovedUsers(from userIDs: Set<UserID>) async -> [WireDataModel.ZMUser] {
        await withTaskGroup(of: WireDataModel.ZMUser.self) { taskGroup in
            for userID in userIDs {
                taskGroup.addTask { [self] in
                    await userRepository.fetchOrCreateUser(
                        with: userID.uuid,
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

    private func isSelfUserRemoved(in removedUsersIDs: Set<UserID>) async -> Bool {
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

    private func deleteMembership(for userIDs: Set<UserID>, time: Date) async {
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for userID in userIDs {
                taskGroup.addTask { [self] in
                    do {
                        try await teamRepository.deleteMembership(
                            for: userID.uuid,
                            domain: userID.domain,
                            at: time
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

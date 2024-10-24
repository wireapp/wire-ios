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
        for userID: String,
        domain: String
    ) async throws -> String

    /// Fetches or creates a conversation locally.
    /// - Parameters:
    ///     - id: The conversation ID.
    ///     - domain: The conversation domain if any.
    /// - Returns: The `ZMConversation` found or created locally.

    func fetchOrCreateConversation(
        with id: UUID,
        domain: String?
    ) async -> ZMConversation

    /// Fetches a MLS conversation locally.
    ///
    /// - parameters:
    ///     - groupID: The MLS group ID.
    ///
    /// - returns : A MLS conversation.

    func fetchMLSConversation(
        with groupID: String
    ) async -> ZMConversation?

    /// Removes a given user from all conversations.
    ///
    /// - parameters:
    ///     - participantID: The user ID.
    ///     - participantDomain: The user domain.
    ///     - date: The date the user was removed from the conversations.

    func removeParticipantFromAllConversations(
        participantID: UUID,
        participantDomain: String?,
        removedAt date: Date
    ) async throws

    /// Adds a participant to a conversation.
    /// - Parameters:
    ///     - conversationID: The conversation ID.
    ///     - conversationDomain: The conversation domain if any.
    ///     - participantID: The participant ID.
    ///     - participantDomain: The participant domain if any.
    ///     - participantRole: The role of the user.

    func addParticipantToConversation(
        conversationID: UUID,
        conversationDomain: String?,
        participantID: UUID,
        participantDomain: String?,
        participantRole: String
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
    private let backendInfo: BackendInfo

    // MARK: - Object lifecycle

    public init(
        conversationsAPI: any ConversationsAPI,
        conversationsLocalStore: any ConversationLocalStoreProtocol,
        userRepository: any UserRepositoryProtocol,
        backendInfo: BackendInfo
    ) {
        self.conversationsAPI = conversationsAPI
        self.conversationsLocalStore = conversationsLocalStore
        self.userRepository = userRepository
        self.backendInfo = backendInfo
    }

    // MARK: - Public

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
                    await conversationsLocalStore.storeConversation(
                        conversation,
                        isFederationEnabled: backendInfo.isFederationEnabled
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
        for userID: String,
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

    public func fetchOrCreateConversation(
        with id: UUID,
        domain: String?
    ) async -> ZMConversation {
        await conversationsLocalStore.fetchOrCreateConversation(
            with: id,
            domain: domain
        )
    }

    public func removeParticipantFromAllConversations(
        participantID: UUID,
        participantDomain: String?,
        removedAt date: Date
    ) async throws {
        let user = try await userRepository.fetchUser(
            with: participantID,
            domain: participantDomain
        )

        await conversationsLocalStore.removeParticipantFromAllConversations(
            user: user,
            date: date
        )
    }

    public func addParticipantToConversation(
        conversationID: UUID,
        conversationDomain: String?,
        participantID: UUID,
        participantDomain: String?,
        participantRole: String
    ) async {
        let participant = userRepository.fetchOrCreateUser(
            with: participantID,
            domain: participantDomain
        )

        let conversation = await fetchOrCreateConversation(
            with: conversationID,
            domain: conversationDomain
        )

        await conversationsLocalStore.addParticipant(
            participant,
            withRole: participantRole,
            to: conversation
        )
    }

}

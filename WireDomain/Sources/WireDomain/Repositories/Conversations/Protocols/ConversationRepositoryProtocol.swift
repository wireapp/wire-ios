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
import WireNetwork

// sourcery: AutoMockable
/// Facilitate access to conversations related domain objects.
public protocol ConversationRepositoryProtocol: Sendable {

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
        _ conversation: WireDomain.Conversation,
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
    ) async throws -> (String, MLSPublicKeys?)

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

    /// Checks if selfUser is still in a given conversation
    /// - Parameter groupID: mlsGroupID of the conversation
    /// - Returns: true if selfUser belongs to the conversation, false otherwise
    func isSelfAnActiveMember(
        in groupID: WireDataModel.MLSGroupID
    ) async -> Bool
}

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
//import WireLogging

// sourcery: AutoMockable
/// A local store dedicated to conversations.
/// The store uses the injected context to perform `CoreData` operations on conversations objects.
///
/// Conversations can have different types with specific actions for each one of them.
///
/// Check out some of the private methods in `ConversationLocalStore` for a general context.
///
/// Check out the Confluence page for full details
/// [here](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/20514628/Conversations)
public protocol ConversationLocalStoreProtocol {
    associatedtype ConversationEntity: ConversationEntityProtocol
    associatedtype UserEntity: UserEntityProtocol

    /// Fetches or creates a conversation locally.
    /// - parameter id: The ID of the conversation.
    /// - parameter domain: The domain of the conversation if any.
    ///
    /// - returns: The `ConversationEntity` found or created locally.

    func fetchOrCreateConversation(
        id: UUID,
        domain: String?
    ) async -> ConversationEntity

    /// Stores a given conversation locally.
    /// - Parameter conversation: The conversation to store locally.
    /// - Parameter timestamp: The date the conversation was created or last modified.
    /// - Parameter isFederationEnabled: A flag indicating whether a `Federation` is enabled.

    func storeConversation(
        _ conversation: Conversation,
        timestamp: Date,
        isFederationEnabled: Bool,
        isMLSEnabled: Bool
    ) async

    /// Stores a flag indicating whether a conversation requires an update from backend.
    /// - Parameter needsBackendUpdate: A flag indicated whether the qualified conversation needs to be updated from
    /// backend.
    /// - Parameter conversationID: The conversation ID.
    /// - Parameter conversationDomain: The conversation domain.

    func storeConversation(
        needsBackendUpdate: Bool,
        conversationID: UUID,
        conversationDomain: String
    ) async

    /// Stores a given failed conversation locally.
    /// - Parameter conversationID: The conversation ID.
    /// - Parameter conversationDomain: The conversation domain.

    func storeFailedConversation(
        conversationID: UUID,
        conversationDomain: String
    ) async

    /// Fetches a MLS conversation locally.
    ///
    /// - parameters:
    ///     - groupID: The MLS group ID.
    ///
    /// - returns : A MLS conversation.

    func fetchMLSConversation(
        groupID: WireDataModel.MLSGroupID
    ) async -> ConversationEntity?

    /// Fetches a conversation locally.
    /// - Parameters:
    ///     - id: The ID of the conversation.
    ///     - domain: The domain of the conversation if any.
    /// - returns: The `ConversationEntity` found locally.

    func fetchConversation(
        id: UUID,
        domain: String?
    ) async -> ConversationEntity?

    /// Wipes MLS group conversation.
    /// - parameter id: The MLS group ID.

    func wipeMLSGroup(
        groupID: WireDataModel.MLSGroupID
    ) async throws

    /// Removes a given user from all group conversations.
    ///
    /// - parameters:
    ///     - participantID: The ID of the participant to remove.
    ///     - participantDomain: The domain of the participant.
    ///     - date: The date the user was removed from the conversations.

    func removeParticipantFromAllGroupConversations(
        participantID: UUID,
        participantDomain: String?,
        date: Date
    ) async throws

    /// Adds a participant or updates its role in a conversation.
    ///
    /// - Parameters:
    ///     - user: The user to add or update.
    ///     - role: The role of the user.
    ///     - conversation: The conversation the user is part of.
    ///
    /// If user is already part of the conversation, its role will be updated.
    /// If not, user will be added to the conversation.

    func addOrUpdateParticipant(
        _ user: UserEntity,
        withRole role: String,
        in conversation: ConversationEntity
    ) async

    /// Adds new participants to a conversation.
    /// - Parameters:
    ///     - newParticipants: The id, domain and role of the new participant.
    ///     - sender: The user who added the participants.
    ///     - date: The date the participants were added.
    ///     - conversation: The conversation to add the participants to.

    func addParticipants(
        _ participants: [(id: UUID, domain: String?, role: String?)],
        addedBy sender: (id: UUID, domain: String?),
        atDate date: Date,
        conversation: (id: UUID, domain: String)
    ) async throws

    /// Updates the member muted and archived status.
    /// - Parameters:
    ///     - mutedStatusInfo: The mute status and reference date.
    ///     - archivedStatusInfo: The archived status and reference date.
    ///     - localConversation: The conversation to update statuses for.

    func updateMemberStatus(
        mutedStatusInfo: (status: Int?, referenceDate: Date?),
        archivedStatusInfo: (status: Bool?, referenceDate: Date?),
        for localConversation: ConversationEntity
    ) async

    /// Updates access modes and roles to conversation.
    /// - Parameters:
    ///     - accessModes: The access modes to update (how users can join a conversation).
    ///     - accessRoles: The access roles to update (which users are allowed to be participants in a conversation).
    ///
    /// See `ConversationAccessMode` and `ConversationAccessRole`

    func updateAccesses(
        for conversation: ConversationEntity,
        accessModes: [String],
        accessRoles: [String]
    ) async

    /// Get message protocol from a conversation
    /// - parameter conversation: The conversation to get the message protocol from.
    /// - returns: The message protocol used for that conversation.

    func messageProtocol(
        for conversation: ConversationEntity
    ) async -> WireDataModel.MessageProtocol

    /// Stores a flag indicating whether a conversation has read receipts enabled.
    /// - parameters:
    ///     - hasReadReceiptsEnabled: A flag indicating whether the conversation has read receipts enabled.
    ///     - conversation: The conversation to update the flag for.

    func storeConversation(
        hasReadReceiptsEnabled: Bool,
        for conversation: ConversationEntity
    ) async

    /// Indicates whether a given conversation is read-only.
    /// - parameter conversation: The conversation to check the flag for.
    /// - returns: Whether the conversation is read-only.

    func isConversationForcedReadOnly(
        _ conversation: ConversationEntity
    ) async -> Bool

    /// Removes participants from conversation and updates conversation state.
    /// - Parameters:
    ///     - conversation: The conversation to remove the participants from.
    ///     - users: The users to remove.
    ///     - initiatingUser: The user that initiated the removal.

    func removeParticipantsAndUpdateConversationState(
        conversation: ConversationEntity,
        users: Set<ZMUser>,
        initiatingUser: ZMUser
    ) async

    /// The conversation active message destruction timeout value.
    /// - Parameters:
    ///     - conversation: The conversation to get the message destruction timeout value from.
    /// - returns: A `MessageDestructionTimeoutValue` object.

    func conversationMessageDestructionTimeout(
        _ conversation: ConversationEntity
    ) async -> MessageDestructionTimeoutValue

    /// Stores a message destruction timeout value.
    /// - parameters:
    ///     - timeoutValue: The message destruction timeout value.
    ///     - conversation: The conversation to update the value for.

    func storeConversation(
        timeoutValue: Double,
        for conversation: ConversationEntity
    ) async
    /// Fetches or creates a role locally.
    /// - Parameters:
    ///     - role: The role name to fetch or create.
    ///     - conversation: The given conversation.
    /// - Returns: A role created or fetched locally.

    func fetchOrCreateRole(
        _ role: String,
        in conversation: ConversationEntity
    ) async -> Role

    /// Fetches local participants from a conversation.
    /// - parameter conversation: The related conversation.
    /// - returns: A list of participants.

    func localParticipants(
        in conversation: ConversationEntity
    ) async -> Set<ZMUser>

    /// Whether the conversation is a group conversation.
    /// - parameter conversation: The given conversation.
    /// - returns: A flag indicating whether the conversation is a group one.

    func isGroupConversation(
        _ conversation: ConversationEntity
    ) async -> Bool

    /// Deletes a conversation locally.
    /// - Parameters:
    ///     - conversation: The conversation to delete.

    func deleteConversation(
        _ conversation: ConversationEntity
    ) async

    /// Stores a flag indicating whether a conversation is deleted remotely.
    /// - Parameter isDeletedRemotely: A flag indicating whether the conversation is deleted remotely.
    /// - Parameter conversation: The conversation to update the `isDeletedRemotely` flag for.

    func storeConversation(
        isDeletedRemotely: Bool,
        conversation: ConversationEntity
    ) async

    /// Fetches the MLS conversation info (given conversation is MLS one)
    /// - parameter conversation: The conversation to fetch the the MLS info for.
    /// - returns: The MLS conversation group ID (if conversation is MLS) and whether the conversation is MLS ready.
    ///
    /// MLS conversations should always have a group ID hence this method returns nil if conversation doesn't have a MLS
    /// group ID.

    func mlsConversationInfo(
        conversation: ConversationEntity
    ) async -> (mlsGroupID: MLSGroupID, isMLSReady: Bool)?

    /// Commits pending proposals for a given conversation.
    /// - Parameter conversation: The conversation to update the `date` flag for.
    /// - Parameter date: The date to update.
    /// - Parameter commitDelay: The commit delay.

    func commitPendingProposals(
        conversation: ConversationEntity,
        date: Date,
        commitDelay: UInt64
    ) async

    func updateSecurityLevelAfterReceivingMessage(
        conversation: ConversationEntity,
        genericMessage: GenericMessage,
        date: Date
    ) async

    func addParticipantIfNeeded(
        participantID: UUID,
        participantDomain: String?,
        in conversation: ConversationEntity,
        date: Date
    ) async

    /// Updates last read message timestamp.
    /// - Parameters:
    ///     - lastReadMessage: The last read message protobuf object.
    ///     - conversation: The conversation the message is derived from.
    ///

    func updateLastReadMessageTimestamp(
        _ lastReadMessage: LastRead,
        in conversation: ConversationEntity
    ) async

    /// Updates cleared message timestamp.
    /// - Parameters:
    ///     - clearedMessage: The cleared message protobuf object.
    ///     - conversation: The conversation the message is derived from.
    ///

    func updateClearedMessageTimestamp(
        _ clearedMessage: Cleared,
        in conversation: ConversationEntity
    ) async

    /// Sends a notification using the main context informing typing users
    /// have been updated for a given conversation.
    /// - Parameters:
    ///     - conversationID: The conversation managed object ID.
    ///     - usersID: The updated typing users managed object IDs.

    func updateTypingUsers(
        conversationID: NSManagedObjectID,
        usersID: Set<NSManagedObjectID>
    ) async

    /// Obtain permanent stored object IDs.
    /// - Parameters:
    ///     - user: The user to get the permanent managed object ID for.
    ///     - conversation: The conversation to get the permanent managed object ID for.

    func obtainPermanentIDs(
        user: ZMUser,
        conversation: ConversationEntity
    )

    /// Fetches the current conversation name
    /// - parameter conversation: The conversation to fetch the name for.
    /// - returns: The conversation name

    func conversationName(
        conversation: ConversationEntity
    ) async -> String?

    /// Updates the conversation name.
    /// - Parameters:
    ///     - newName: The new name for the conversation.
    ///     - conversation: The conversation to update the name for.

    func storeConversation(
        newName: String,
        conversation: ConversationEntity
    ) async

    /// Updates or creates a MLS group locally.
    /// - Parameters:
    ///     - groupID: The MLS group ID.

    func updateOrCreateMLSGroup(
        groupID: MLSGroupID
    ) async

    /// Stores the conversation MLS group ID and marks the mls status as ready.
    /// - Parameters:
    ///     - mlsGroupID: The MLS group ID related to the conversation.
    ///     - conversation: The conversation to update the properties for.

    func storeMLSConversationEstablished(
        mlsGroupID: MLSGroupID,
        conversation: ConversationEntity
    ) async

    /// Fetches the other user qualified id (not self user) in a 1:1 conversation.
    /// - Parameters:
    ///     - conversation: The 1:1 conversation self and other user should be part of.
    /// - returns: The other user `QualifiedID`.

    func fetchOtherUserIDInOneOnOneConversation(
        conversation: ConversationEntity
    ) async -> WireDataModel.QualifiedID?

}

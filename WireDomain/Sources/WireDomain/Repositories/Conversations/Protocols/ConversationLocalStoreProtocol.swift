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
import GenericMessageProtocol
import WireDataModel

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

    func qualifiedID(for conversation: ZMConversation) async -> QualifiedID?

    /// Fetches or creates a conversation locally.
    /// - parameter id: The ID of the conversation.
    /// - parameter domain: The domain of the conversation if any.
    ///
    /// - returns: The `ZMConversation` found or created locally.

    func fetchOrCreateConversation(
        id: UUID,
        domain: String?
    ) async -> ZMConversation

    /// Stores a given conversation locally.
    /// - Parameter conversation: The conversation to store locally.
    /// - Parameter timestamp: The date the conversation was created or last modified.
    /// - Parameter isFederationEnabled: A flag indicating whether a `Federation` is enabled.

    func storeConversation(
        _ conversation: WireDomain.Conversation,
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

    func createMLSConversation(
        conversationID: UUID,
        conversationDomain: String?,
        mlsGroupID: MLSGroupID
    ) async

    func fetchAllMLSConversations(domain: String?) async throws -> [ZMConversation]

    /// Fetches a MLS conversation locally.
    ///
    /// - parameters:
    ///     - groupID: The MLS group ID.
    ///
    /// - returns : A MLS conversation.

    func fetchMLSConversation(
        groupID: WireDataModel.MLSGroupID
    ) async -> ZMConversation?

    /// Fetches a conversation locally.
    /// - Parameters:
    ///     - id: The ID of the conversation.
    ///     - domain: The domain of the conversation if any.
    /// - returns: The `ZMConversation` found locally.

    func fetchConversation(
        id: UUID,
        domain: String?
    ) async -> ZMConversation?

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
        _ user: ZMUser,
        withRole role: String,
        in conversation: ZMConversation
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
        for localConversation: ZMConversation
    ) async

    /// Updates access modes and roles to conversation.
    /// - Parameters:
    ///     - accessModes: The access modes to update (how users can join a conversation).
    ///     - accessRoles: The access roles to update (which users are allowed to be participants in a conversation).
    ///
    /// See `ConversationAccessMode` and `ConversationAccessRole`

    func updateAccesses(
        for conversation: ZMConversation,
        accessModes: [String],
        accessRoles: [String]
    ) async

    /// Get message protocol from a conversation
    /// - parameter conversation: The conversation to get the message protocol from.
    /// - returns: The message protocol used for that conversation.

    func messageProtocol(
        for conversation: ZMConversation
    ) async -> WireDataModel.MessageProtocol

    /// Stores a flag indicating whether a conversation has read receipts enabled.
    /// - parameters:
    ///     - hasReadReceiptsEnabled: A flag indicating whether the conversation has read receipts enabled.
    ///     - conversation: The conversation to update the flag for.

    func storeConversation(
        hasReadReceiptsEnabled: Bool,
        for conversation: ZMConversation
    ) async

    /// Indicates whether a given conversation is read-only.
    /// - parameter conversation: The conversation to check the flag for.
    /// - returns: Whether the conversation is read-only.

    func isConversationForcedReadOnly(
        _ conversation: ZMConversation
    ) async -> Bool

    /// Removes participants from conversation and updates conversation state.
    /// - Parameters:
    ///     - conversation: The conversation to remove the participants from.
    ///     - users: The users to remove.
    ///     - initiatingUser: The user that initiated the removal.

    func removeParticipantsAndUpdateConversationState(
        conversation: ZMConversation,
        users: Set<ZMUser>,
        initiatingUser: ZMUser
    ) async

    /// The conversation active message destruction timeout value.
    /// - Parameters:
    ///     - conversation: The conversation to get the message destruction timeout value from.
    /// - returns: A `MessageDestructionTimeoutValue` object.

    func conversationMessageDestructionTimeout(
        _ conversation: ZMConversation
    ) async -> MessageDestructionTimeoutValue

    /// Stores a message destruction timeout value.
    /// - parameters:
    ///     - timeoutValue: The message destruction timeout value.
    ///     - conversation: The conversation to update the value for.

    func storeConversation(
        timeoutValue: Double,
        for conversation: ZMConversation
    ) async
    /// Fetches or creates a role locally.
    /// - Parameters:
    ///     - role: The role name to fetch or create.
    ///     - conversation: The given conversation.
    /// - Returns: A role created or fetched locally.

    func fetchOrCreateRole(
        _ role: String,
        in conversation: ZMConversation
    ) async -> Role

    /// Fetches local participants from a conversation.
    /// - parameter conversation: The related conversation.
    /// - returns: A list of participants.

    func localParticipants(
        in conversation: ZMConversation
    ) async -> Set<ZMUser>

    /// Whether the conversation is a group conversation.
    /// - parameter conversation: The given conversation.
    /// - returns: A flag indicating whether the conversation is a group one.

    func isGroupConversation(
        _ conversation: ZMConversation
    ) async -> Bool

    func isSelfConversation(
        _ conversation: ZMConversation
    ) async -> Bool

    /// Deletes a conversation locally.
    /// - Parameters:
    ///     - conversation: The conversation to delete.

    func deleteConversation(
        _ conversation: ZMConversation
    ) async

    /// Stores a flag indicating whether a conversation is deleted remotely.
    /// - Parameter isDeletedRemotely: A flag indicating whether the conversation is deleted remotely.
    /// - Parameter conversation: The conversation to update the `isDeletedRemotely` flag for.

    func storeConversation(
        isDeletedRemotely: Bool,
        conversation: ZMConversation
    ) async

    /// Fetches the MLS conversation info (given conversation is MLS one)
    /// - parameter conversation: The conversation to fetch the the MLS info for.
    /// - returns: The MLS conversation group ID (if conversation is MLS) and whether the conversation is MLS ready.
    ///
    /// MLS conversations should always have a group ID hence this method returns nil if conversation doesn't have a MLS
    /// group ID.

    func mlsConversationInfo(
        conversation: ZMConversation
    ) async -> (mlsGroupID: MLSGroupID, isMLSReady: Bool)?

    /// Commits pending proposals for a given conversation.
    /// - Parameter date: The date to update.
    /// - Parameter conversation: The conversation to update the `date` flag for.
    /// - Parameter commitDelay: The commit delay.

    func updateCommitPendingProposal(
        date: Date,
        for conversation: ZMConversation,
        commitDelay: UInt64
    ) async

    func updateSecurityLevelAfterReceivingMessage(
        conversation: ZMConversation,
        genericMessage: GenericMessage,
        date: Date
    ) async

    func addParticipantIfNeeded(
        participantID: UUID,
        participantDomain: String?,
        in conversation: ZMConversation,
        date: Date
    ) async

    /// Updates last read message timestamp.
    /// - Parameters:
    ///     - lastReadMessage: The last read message protobuf object.
    ///     - conversation: The conversation the message is derived from.
    ///

    func updateLastReadMessageTimestamp(
        _ lastReadMessage: LastRead,
        in conversation: ZMConversation
    ) async

    /// Updates cleared message timestamp.
    /// - Parameters:
    ///     - clearedMessage: The cleared message protobuf object.
    ///     - conversation: The conversation the message is derived from.
    ///

    func updateClearedMessageTimestamp(
        _ clearedMessage: Cleared,
        in conversation: ZMConversation
    ) async

    /// Obtain permanent stored object IDs.
    /// - Parameters:
    ///     - user: The user to get the permanent managed object ID for.
    ///     - conversation: The conversation to get the permanent managed object ID for.

    func obtainPermanentIDs(
        user: ZMUser,
        conversation: ZMConversation
    ) async

    /// Fetches the current conversation name
    /// - parameter conversation: The conversation to fetch the name for.
    /// - returns: The conversation name

    func conversationName(
        conversation: ZMConversation
    ) async -> String?

    /// Updates the conversation name.
    /// - Parameters:
    ///     - newName: The new name for the conversation.
    ///     - conversation: The conversation to update the name for.

    func storeConversation(
        newName: String,
        conversation: ZMConversation
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
        conversation: ZMConversation
    ) async

    /// Stores new conversation MLS group ID and marks it as 'pendingJoin'
    /// - Parameters:
    ///   - newMLSGroupID: The new generated MLS group ID
    ///   - conversation: The conversation to update the properties for.
    func storeMLSConversationPendingJoinAfterReset(
        newMLSGroupID: MLSGroupID,
        conversation: ZMConversation
    ) async

    /// Fetches the other user qualified id (not self user) in a 1:1 conversation.
    /// - Parameters:
    ///     - conversation: The 1:1 conversation self and other user should be part of.
    /// - returns: The other user `QualifiedID`.

    func fetchOtherUserIDInOneOnOneConversation(
        conversation: ZMConversation
    ) async -> WireDataModel.QualifiedID?

    func name(
        for conversation: ZMConversation
    ) async -> String?

    func shouldHideNotification() async -> Bool

    func isMessageSilenced(
        _ message: GenericMessage,
        senderID: UUID?,
        conversation: ZMConversation
    ) async -> Bool

    func conversationMutedMessageTypesIncludingAvailability(
        _ conversation: ZMConversation
    ) async -> MutedMessageTypes

    func lastReadServerTimestamp(
        _ conversation: ZMConversation
    ) async -> Date?

    func conversationNeedsBackendUpdate(
        _ conversation: ZMConversation
    ) async -> Bool

    func increaseUnreadCount(
        for conversation: ZMConversation
    ) async

    func decreaseUnreadCount(
        for conversation: ZMConversation
    ) async

    func increaseUnreadSelfMentionCount(
        for conversation: ZMConversation
    ) async

    func increaseUnreadSelfReplyCount(
        for conversation: ZMConversation
    ) async

    func unreadConversationCount() async -> UInt

    /// Stores the private conversation (aka channel) permission locally.
    /// - Parameters
    ///     - permission: The new permission value (`admins` or `everyone`)

    func storeConversation(
        permission: WireDomain.Conversation.ChannelPermission,
        conversation: ZMConversation
    ) async

    /// Stores the conversation history depth (for channels only) locally.
    /// - Parameters
    ///     - historyDepth: The history depth (one day, one week, four weeks..)

    func storeConversation(
        historyDepth: String,
        conversationID: UUID,
        conversationDomain: String?
    ) async throws

    func fetchServerTimeDelta() async -> TimeInterval

}

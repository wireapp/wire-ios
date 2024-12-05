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

import CoreData
import WireAPI
import WireDataModel

// sourcery: AutoMockable
/// A local store dedicated to conversations.
/// The store uses the injected context to perform `CoreData` operations on conversations objects.
///
/// Conversations can have different types with specific actions for each one of them.
///
/// Check out some of the private methods in `ConversationLocalStore` for a general context.
///
/// Check out the Confluence page for full details [here](https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/20514628/Conversations)
public protocol ConversationLocalStoreProtocol {

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
        _ conversation: WireAPI.Conversation,
        timestamp: Date,
        isFederationEnabled: Bool
    ) async

    /// Stores a flag indicating whether a conversation requires an update from backend.
    /// - Parameter needsBackendUpdate: A flag indicated whether the qualified conversation needs to be updated from backend.
    /// - Parameter qualifiedId: The conversation qualified ID.

    func storeConversation(
        needsBackendUpdate: Bool,
        qualifiedId: WireAPI.QualifiedID
    ) async

    /// Stores a given failed conversation locally.
    /// - Parameter qualifiedId: The conversation qualified ID.

    func storeFailedConversation(
        withQualifiedId qualifiedId: WireAPI.QualifiedID
    ) async

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
    ///     - user: The user to remove from the conversations.
    ///     - date: The date the user was removed from the conversations.

    func removeParticipantFromAllGroupConversations(
        user: ZMUser,
        date: Date
    ) async

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
    ///     - conversation: The conversation to add the participants

    func addParticipants(
        _ participants: [(id: UUID, domain: String?, role: String?)],
        addedBy sender: (id: UUID, domain: String?),
        atDate date: Date,
        to conversation: ZMConversation
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

    /// Adds a system message to a given conversation.
    /// - parameters:
    ///     - message: The system message to add.
    ///     - conversation: The conversation to add the system message to.

    func addSystemMessage(
        _ message: SystemMessage,
        to conversation: ZMConversation
    ) async

    /// Retrieves conversation muted message types
    /// - parameter conversation: The conversation to get the muted message types for.
    /// - returns: The muted message types.

    func conversationMutedMessageTypes(
        _ conversation: ZMConversation
    ) async -> MutedMessageTypes

    /// Stores a flag indicating whether a conversation is archived.
    /// - parameters:
    ///     - isArchived: Indicates whether the conversation is archived.
    ///     - conversation: The conversation to set the `isArchived` flag for.

    func storeConversation(
        isArchived: Bool,
        for conversation: ZMConversation
    ) async

    /// Indicates whether a conversation is archived.
    /// - parameter conversation: The conversation to check the `isArchived` flag for.
    /// - returns: A flag indicating whether the conversation is archived.

    func isConversationArchived(
        _ conversation: ZMConversation
    ) async -> Bool

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
    /// MLS conversations should always have a group ID hence this method returns nil if conversation doesn't have a MLS group ID.

    func mlsConversationInfo(
        conversation: ZMConversation
    ) async -> (mlsGroupID: MLSGroupID, isMLSReady: Bool)?

    /// Commits pending proposals for a given conversation.
    /// - Parameter conversation: The conversation to update the `date` flag for.
    /// - Parameter date: The date to update.
    /// - Parameter commitDelay: The commit delay.

    func commitPendingProposals(
        conversation: ZMConversation,
        date: Date,
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
}

public final class ConversationLocalStore: ConversationLocalStoreProtocol {

    enum Error: Swift.Error {
        case noBackendConversationID
    }

    // MARK: - Properties

    let context: NSManagedObjectContext
    let mlsService: any MLSServiceInterface
    let eventProcessingLogger = WireLogger.eventProcessing
    let mlsLogger = WireLogger.mls
    let updateEventLogger = WireLogger.updateEvent
    let userLocalStore: any UserLocalStoreProtocol

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        mlsService: any MLSServiceInterface,
        userLocalStore: any UserLocalStoreProtocol
    ) {
        self.context = context
        self.mlsService = mlsService
        self.userLocalStore = userLocalStore
    }

    // MARK: - Public
    
    public func updateLastReadMessageTimestamp(
        _ lastReadMessage: LastRead,
        in conversation: ZMConversation
    ) async {
        await context.perform { [context] in
            guard conversation.isSelfConversation else {
                return
            }

            ZMConversation.updateConversation(
                withLastReadFromSelfConversation: lastReadMessage,
                in: context
            )
        }
    }

    public func updateClearedMessageTimestamp(
        _ clearedMessage: Cleared,
        in conversation: ZMConversation
    ) async {
        await context.perform { [context] in
            guard conversation.isSelfConversation else {
                return
            }

            ZMConversation.updateConversation(
                withClearedFromSelfConversation: clearedMessage,
                in: context
            )
        }
    }
    
    public func mlsConversationInfo(
        conversation: ZMConversation
    ) async -> (mlsGroupID: MLSGroupID, isMLSReady: Bool)? {
        
        await context.perform {
            guard let mlsGroupID = conversation.mlsGroupID else {
                return nil
            }

            return (mlsGroupID, conversation.mlsStatus == .ready)
        }
        
    }

    public func updateMemberStatus(
        mutedStatusInfo: (status: Int?, referenceDate: Date?),
        archivedStatusInfo: (status: Bool?, referenceDate: Date?),
        for localConversation: ZMConversation
    ) async {
        await context.perform {
            let mutedStatus = mutedStatusInfo.status
            let mutedReference = mutedStatusInfo.referenceDate

            if let mutedStatus, let mutedReference {
                localConversation.updateMutedStatus(
                    status: Int32(mutedStatus),
                    referenceDate: mutedReference
                )
            }

            let archivedStatus = archivedStatusInfo.status
            let archivedReference = archivedStatusInfo.referenceDate

            if let archivedStatus, let archivedReference {
                localConversation.updateArchivedStatus(
                    archived: archivedStatus,
                    referenceDate: archivedReference
                )
            }
        }
    }

    public func fetchConversation(
        id: UUID,
        domain: String?
    ) async -> ZMConversation? {
        await context.perform { [context] in
            ZMConversation.fetch(
                with: id,
                domain: domain,
                in: context
            )
        }
    }

    public func fetchOrCreateConversation(
        id: UUID,
        domain: String?
    ) async -> ZMConversation {
        await context.perform { [context] in
            ZMConversation.fetchOrCreate(
                with: id,
                domain: domain,
                in: context
            )
        }
    }

    public func addOrUpdateParticipant(
        _ user: ZMUser,
        withRole role: String,
        in conversation: ZMConversation
    ) async {
        let role = await fetchOrCreateRole(role, in: conversation)

        await context.perform {
            // If user is already part of the conversation, its role will be updated.
            // If not, user will be added to the conversation.
            conversation.addParticipantAndUpdateConversationState(
                user: user,
                role: role
            )
        }
    }

    public func addParticipants(
        _ participants: [(id: UUID, domain: String?, role: String?)],
        addedBy sender: (id: UUID, domain: String?),
        atDate date: Date,
        to conversation: ZMConversation
    ) async throws {
        typealias UserAndRole = (user: ZMUser, role: Role?)

        let usersAndRoles = await withTaskGroup(of: UserAndRole?.self) { taskGroup in
            for newParticipant in participants {
                taskGroup.addTask { [self] in
                    let user = await userLocalStore.fetchOrCreateUser(
                        id: newParticipant.id,
                        domain: newParticipant.domain
                    )

                    if let participantRole = newParticipant.role {
                        let role = await fetchOrCreateRole(
                            participantRole,
                            in: conversation
                        )

                        return (user, role)
                    }

                    return (user, nil)
                }
            }

            var usersAndRoles: [UserAndRole?] = []

            for await userAndRole in taskGroup {
                usersAndRoles.append(userAndRole)
            }

            return usersAndRoles.compactMap { $0 }
        }

        let users = Set(usersAndRoles.map(\.user))
        let existingUsers = await localParticipants(
            in: conversation
        )
        let newUsers = users.subtracting(existingUsers)

        if !newUsers.isEmpty, await isGroupConversation(conversation) {
            let sender = try await userLocalStore.fetchUser(
                id: sender.id,
                domain: sender.domain
            )

            let systemMessage = SystemMessage(
                type: .participantsAdded,
                sender: sender,
                users: newUsers,
                clients: nil,
                timestamp: date
            )

            await addSystemMessage(systemMessage, to: conversation)
        }

        await context.perform {
            conversation.addParticipantsAndUpdateConversationState(
                usersAndRoles: usersAndRoles
            )
        }
    }

    public func addSystemMessage(
        _ message: SystemMessage,
        to conversation: ZMConversation
    ) async {
        await context.perform { [context] in
            let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: context)
            systemMessage.systemMessageType = message.type
            systemMessage.sender = message.sender
            systemMessage.users = message.users ?? Set()
            systemMessage.addedUsers = message.addedUsers
            systemMessage.clients = message.clients ?? Set()
            systemMessage.serverTimestamp = message.timestamp

            if let duration = message.duration {
                systemMessage.duration = duration
            }

            if let messageTimer = message.messageTimer {
                systemMessage.messageTimer = NSNumber(value: messageTimer)
            }

            systemMessage.relevantForConversationStatus = message.relevantForStatus
            systemMessage.participantsRemovedReason = message.removedReason
            systemMessage.domains = message.domains

            conversation.append(systemMessage)
        }
    }

    public func storeConversation(
        _ conversation: WireAPI.Conversation,
        timestamp: Date,
        isFederationEnabled: Bool
    ) async {
        guard let conversationType = conversation.type else {
            return
        }

        Flow.createGroup.checkpoint(
            description: "create ZMConversation of type \(conversationType))"
        )

        guard let id = conversation.id ?? conversation.qualifiedID?.uuid else {
            if conversationType == .group {
                Flow.createGroup.fail(
                    Error.noBackendConversationID
                )
            }

            eventProcessingLogger.error(
                "Missing conversationID in \(conversationType) conversation payload, aborting..."
            )

            return
        }

        switch conversationType {
        case .group:
            await updateOrCreateGroupConversation(
                remoteConversation: conversation,
                remoteConversationID: id,
                serverTimestamp: timestamp,
                isFederationEnabled: isFederationEnabled
            )

        case .`self`:
            await updateOrCreateSelfConversation(
                remoteConversation: conversation,
                remoteConversationID: id,
                serverTimestamp: timestamp,
                isFederationEnabled: isFederationEnabled
            )

        case .connection:
            /// Conversations are of type `connection` while the connection
            /// is pending.
            await updateOrCreateConnectionConversation(
                remoteConversation: conversation,
                remoteConversationID: id,
                serverTimestamp: timestamp,
                isFederationEnabled: isFederationEnabled
            )

        case .oneOnOne:
            /// Conversations are of type `oneOnOne` when the connection
            /// is accepted.
            await updateOrCreateOneToOneConversation(
                remoteConversation: conversation,
                remoteConversationID: id,
                serverTimestamp: timestamp,
                isFederationEnabled: isFederationEnabled
            )
        }
    }

    public func storeConversation(
        needsBackendUpdate: Bool,
        qualifiedId: WireAPI.QualifiedID
    ) async {
        await context.perform { [context] in
            let conversation = ZMConversation.fetch(
                with: qualifiedId.uuid,
                domain: qualifiedId.domain,
                in: context
            )

            conversation?.needsToBeUpdatedFromBackend = needsBackendUpdate
        }
    }

    public func storeFailedConversation(
        withQualifiedId qualifiedId: WireAPI.QualifiedID
    ) async {
        let conversation = await fetchOrCreateConversation(
            id: qualifiedId.uuid,
            domain: qualifiedId.domain
        )

        await context.perform {
            conversation.isPendingMetadataRefresh = true
            conversation.needsToBeUpdatedFromBackend = true
        }
    }

    public func fetchMLSConversation(
        groupID: WireDataModel.MLSGroupID
    ) async -> ZMConversation? {
        await context.perform { [context] in
            ZMConversation.fetch(
                with: groupID,
                in: context
            )
        }
    }

    public func isConversationArchived(
        _ conversation: ZMConversation
    ) async -> Bool {
        await context.perform {
            conversation.isArchived
        }
    }

    public func isConversationForcedReadOnly(
        _ conversation: ZMConversation
    ) async -> Bool {
        await context.perform {
            conversation.isForcedReadOnly
        }
    }

    public func commitPendingProposals(
        conversation: ZMConversation,
        date: Date,
        commitDelay: UInt64
    ) async {
        let scheduledDate = date + TimeInterval(commitDelay)

        await context.perform {
            conversation.commitPendingProposalDate = scheduledDate
        }

        mlsService.commitPendingProposalsIfNeeded()
    }

    public func updateSecurityLevelAfterReceivingMessage(
        conversation: ZMConversation,
        genericMessage: GenericMessage,
        date: Date
    ) async {
        // Update the legal hold state in the conversation
        await context.perform {
            conversation.updateSecurityLevelIfNeededAfterReceiving(
                message: genericMessage,
                timestamp: date
            )
        }
    }

    public func addParticipantIfNeeded(
        participantID: UUID,
        participantDomain: String?,
        in conversation: ZMConversation,
        date: Date
    ) async {
        guard let participant = try? await userLocalStore.fetchUser(
            id: participantID,
            domain: participantDomain
        ) else {
            return
        }

        await context.perform {
            conversation.addParticipantAndSystemMessageIfMissing(
                participant,
                date: date
            )
        }
    }

    public func conversationMutedMessageTypes(
        _ conversation: ZMConversation
    ) async -> MutedMessageTypes {
        await context.perform {
            conversation.mutedMessageTypes
        }
    }

    public func storeConversation(
        isArchived: Bool,
        for conversation: ZMConversation
    ) async {
        await context.perform {
            conversation.isArchived = isArchived
        }
    }

    public func storeConversation(
        hasReadReceiptsEnabled: Bool,
        for conversation: ZMConversation
    ) async {
        await context.perform {
            conversation.hasReadReceiptsEnabled = hasReadReceiptsEnabled
        }
    }

    public func messageProtocol(
        for conversation: ZMConversation
    ) async -> WireDataModel.MessageProtocol {
        await context.perform {
            conversation.messageProtocol
        }
    }

    public func isGroupConversation(
        _ conversation: ZMConversation
    ) async -> Bool {
        await context.perform {
            conversation.conversationType == .group
        }
    }

    public func removeParticipantFromAllGroupConversations(
        user: ZMUser,
        date: Date
    ) async {
        let allGroupConversations = await context.perform {
            let allGroupConversations: [ZMConversation] = user.participantRoles.compactMap {
                guard $0.conversation?.conversationType == .group else {
                    return nil
                }

                return $0.conversation
            }

            return allGroupConversations
        }

        for conversation in allGroupConversations {
            let (userTeam, isTeamMember) = await context.perform {
                (user.team, user.isTeamMember)
            }

            let teamConversation = await context.perform {
                conversation.team
            }

            if isTeamMember, teamConversation == userTeam {
                let systemMessage = SystemMessage(
                    type: .teamMemberLeave,
                    sender: user,
                    users: [user],
                    timestamp: date
                )

                await addSystemMessage(systemMessage, to: conversation)

            } else {
                let systemMessage = SystemMessage(
                    type: .participantsRemoved,
                    sender: user,
                    users: [user],
                    timestamp: date
                )

                await addSystemMessage(systemMessage, to: conversation)
            }

            await context.perform {
                conversation.removeParticipantAndUpdateConversationState(
                    user: user,
                    initiatingUser: user
                )
            }
        }
    }

    public func fetchOrCreateRole(
        _ role: String,
        in conversation: ZMConversation
    ) async -> Role {
        await context.perform { [context] in
            Role.fetchOrCreateRole(
                with: role,
                teamOrConversation: TeamOrConversation.matching(conversation),
                in: context
            )
        }
    }

    public func updateAccesses(
        for conversation: ZMConversation,
        accessModes: [String],
        accessRoles: [String]
    ) async {
        await context.perform { [context] in
            conversation.accessModeStrings = accessModes
            conversation.accessRoleStringsV2 = accessRoles

            context.saveOrRollback()
        }
    }

    public func deleteConversation(_ conversation: ZMConversation) async {
        await storeConversation(
            isDeletedRemotely: true,
            conversation: conversation
        )
    }

    public func wipeMLSGroup(groupID: MLSGroupID) async throws {
        try await mlsService.wipeGroup(groupID)
    }

    public func storeConversation(
        isDeletedRemotely: Bool,
        conversation: ZMConversation
    ) async {
        await context.perform {
            conversation.isDeletedRemotely = isDeletedRemotely
        }
    }

    public func removeParticipantsAndUpdateConversationState(
        conversation: ZMConversation,
        users: Set<ZMUser>,
        initiatingUser: ZMUser
    ) async {
        await context.perform {
            conversation.removeParticipantsAndUpdateConversationState(
                users: users,
                initiatingUser: initiatingUser
            )
        }
    }

    public func localParticipants(
        in conversation: ZMConversation
    ) async -> Set<ZMUser> {
        await context.perform {
            conversation.localParticipants
        }
    }

    // MARK: - Private

    /// Updates or creates a conversation of type `connection` locally.
    ///
    /// See <doc:conversations> and <doc:federation> for more information.
    ///
    /// - Parameter remoteConversation: The conversation object received from backend.
    /// - Parameter removeConversationID: The conversation ID received from backend.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateConnectionConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID,
        serverTimestamp: Date,
        isFederationEnabled: Bool
    ) async {
        let conversation = await fetchOrCreateConversation(
            id: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        )

        await context.perform { [self] in
            conversation.conversationType = .connection

            commonUpdate(
                from: remoteConversation,
                for: conversation,
                serverTimestamp: serverTimestamp,
                isFederationEnabled: isFederationEnabled
            )

            assignMessageProtocol(
                from: remoteConversation,
                for: conversation
            )

            updateConversationStatus(
                from: remoteConversation,
                for: conversation
            )

            conversation.needsToBeUpdatedFromBackend = false
            conversation.isPendingInitialFetch = false
        }

        guard let selfMember = remoteConversation.members?.selfMember else {
            return
        }

        let mutedStatusInfo = (selfMember.mutedStatus, selfMember.mutedReference)
        let archivedStatusInfo = (selfMember.archived, selfMember.archivedReference)

        await updateMemberStatus(
            mutedStatusInfo: mutedStatusInfo,
            archivedStatusInfo: archivedStatusInfo,
            for: conversation
        )
    }

    /// Updates or creates a conversation of type `self` locally.
    ///
    /// See <doc:conversations> and <doc:federation> for more information.
    ///
    /// - Parameter remoteConversation: The conversation object received from backend.
    /// - Parameter removeConversationID: The conversation ID received from backend.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateSelfConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID,
        serverTimestamp: Date,
        isFederationEnabled: Bool
    ) async {
        let conversation = await fetchOrCreateConversation(
            id: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        )

        let mlsGroupID = await context.perform {
            conversation.mlsGroupID
        }

        await context.perform { [self] in
            conversation.conversationType = .`self`
            conversation.isPendingMetadataRefresh = false

            commonUpdate(
                from: remoteConversation,
                for: conversation,
                serverTimestamp: serverTimestamp,
                isFederationEnabled: isFederationEnabled
            )

            updateMessageProtocol(
                from: remoteConversation,
                for: conversation
            )

            conversation.isPendingInitialFetch = false
            conversation.needsToBeUpdatedFromBackend = false
        }

        if mlsGroupID != nil {
            do {
                try await createOrJoinSelfConversation(from: conversation)
            } catch {
                mlsLogger.error(
                    "createOrJoinSelfConversation threw error: \(String(reflecting: error))"
                )
            }
        }
    }

    /// Updates or creates a conversation of type `group` locally.
    ///
    /// See <doc:conversations> and <doc:federation> for more information.
    ///
    /// - Parameter remoteConversation: The conversation object received from backend.
    /// - Parameter removeConversationID: The conversation ID received from backend.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateGroupConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID,
        serverTimestamp: Date,
        isFederationEnabled: Bool
    ) async {
        var isInitialFetch = false

        let conversation = await fetchOrCreateConversation(
            id: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        )

        await context.perform { [self] in
            isInitialFetch = conversation.isPendingInitialFetch

            conversation.conversationType = .group
            conversation.remoteIdentifier = remoteConversationID
            conversation.isPendingMetadataRefresh = false
            conversation.isPendingInitialFetch = false

            commonUpdate(
                from: remoteConversation,
                for: conversation,
                serverTimestamp: serverTimestamp,
                isFederationEnabled: isFederationEnabled
            )

            updateConversationStatus(
                from: remoteConversation,
                for: conversation
            )

            if isInitialFetch {
                assignMessageProtocol(
                    from: remoteConversation,
                    for: conversation
                )
            } else {
                updateMessageProtocol(
                    from: remoteConversation,
                    for: conversation
                )
            }

            Flow.createGroup.checkpoint(
                description: "conversation created remote id: \(conversation.remoteIdentifier?.safeForLoggingDescription ?? "<nil>")"
            )
        }

        if let selfMember = remoteConversation.members?.selfMember {
            let mutedStatusInfo = (selfMember.mutedStatus, selfMember.mutedReference)
            let archivedStatusInfo = (selfMember.archived, selfMember.archivedReference)

            await updateMemberStatus(
                mutedStatusInfo: mutedStatusInfo,
                archivedStatusInfo: archivedStatusInfo,
                for: conversation
            )
        }

        await updateMLSStatus(from: remoteConversation, for: conversation)

        await context.perform { [self] in
            if isInitialFetch {
                /// we just got a new conversation, we display new conversation header
                conversation.appendNewConversationSystemMessage(
                    at: .distantPast,
                    users: conversation.localParticipants
                )

                /// Slow synced conversations should be considered read from the start
                conversation.lastReadServerTimeStamp = conversation.lastModifiedDate

                Flow.createGroup.checkpoint(
                    description: "new system message for conversation inserted"
                )
            }

            /// If we discover this group is actually a fake one on one,
            /// then we should link the one on one user.
            linkOneOnOneUserIfNeeded(for: conversation)
        }
    }

    /// Updates or creates a conversation of type `1:1` locally.
    ///
    /// See <doc:conversations> and <doc:federation> for more information.
    ///
    /// - Parameter remoteConversation: The conversation object received from backend.
    /// - Parameter removeConversationID: The conversation ID received from backend.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateOneToOneConversation(
        remoteConversation: WireAPI.Conversation,
        remoteConversationID: UUID,
        serverTimestamp: Date,
        isFederationEnabled: Bool
    ) async {
        guard let conversationTypeRawValue = remoteConversation.type?.rawValue else {
            return
        }

        let conversation = await fetchOrCreateConversation(
            id: remoteConversationID,
            domain: remoteConversation.qualifiedID?.domain
        )

        await context.perform { [self] in
            let conversationType = BackendConversationType.clientConversationType(
                rawValue: conversationTypeRawValue
            )

            if conversation.oneOnOneUser?.connection?.status == .sent {
                conversation.conversationType = .connection
            } else {
                conversation.conversationType = conversationType
            }

            assignMessageProtocol(
                from: remoteConversation,
                for: conversation
            )

            commonUpdate(
                from: remoteConversation,
                for: conversation,
                serverTimestamp: serverTimestamp,
                isFederationEnabled: isFederationEnabled
            )

            linkOneOnOneUserIfNeeded(for: conversation)

            conversation.needsToBeUpdatedFromBackend = false
            conversation.isPendingInitialFetch = false

            updateConversationStatus(
                from: remoteConversation,
                for: conversation
            )

            if let otherUser = conversation.localParticipantsExcludingSelf.first {
                conversation.isPendingMetadataRefresh = otherUser.isPendingMetadataRefresh
            }
        }

        guard let selfMember = remoteConversation.members?.selfMember else {
            return
        }

        let mutedStatusInfo = (selfMember.mutedStatus, selfMember.mutedReference)
        let archivedStatusInfo = (selfMember.archived, selfMember.archivedReference)

        await updateMemberStatus(
            mutedStatusInfo: mutedStatusInfo,
            archivedStatusInfo: archivedStatusInfo,
            for: conversation
        )
    }

    /// A common update method for all conversations received, no matter the type of the conversation.
    ///
    /// - Parameter remoteConversation: The conversation object received from backend.
    /// - Parameter localConversation: The local conversation to update.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.
    /// - Parameter serverTimestamp: The date the conversation was created/updated.

    private func commonUpdate(
        from remoteConversation: WireAPI.Conversation,
        for localConversation: ZMConversation,
        serverTimestamp: Date,
        isFederationEnabled: Bool
    ) {
        updateAttributes(
            from: remoteConversation,
            for: localConversation,
            isFederationEnabled: isFederationEnabled
        )

        updateMetadata(
            from: remoteConversation,
            for: localConversation
        )

        updateMembers(
            from: remoteConversation,
            for: localConversation
        )

        updateConversationTimestamps(
            for: localConversation,
            serverTimestamp: serverTimestamp
        )
    }

    /// A helper method (for all conversations) that fetches or creates a conversation locally and executes a completion block.
    ///
    /// - Parameter conversationID: The conversation ID to fetch or create the local conversation from.
    /// - Parameter domain: The domain to fetch or create the conversation from.
    /// - Parameter handler: A completion block that takes a `ZMConversation` as argument and returns
    ///   a `ZMConversation` and an optional `MLSGroupID`.
    ///
    ///  Since storage logic can be different according to the conversation type, the method provides a completion block
    ///  with the conversation fetched or created locally.

    @discardableResult
    private func fetchOrCreateConversation(
        conversationID: UUID,
        domain: String?,
        handler: @escaping (ZMConversation) -> (ZMConversation, MLSGroupID?)
    ) async -> (ZMConversation, MLSGroupID?) {
        let conversation = await fetchOrCreateConversation(
            id: conversationID,
            domain: domain
        )

        return await context.perform {
            handler(conversation)
        }
    }

}

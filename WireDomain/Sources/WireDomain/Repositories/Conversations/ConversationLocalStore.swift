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
import WireDataModel
import WireLogging

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

    /// Indicates whether a conversation is a MLS one.
    /// - parameter conversation: The conversation to check the flag for.
    /// - returns: A flag indicating whether the conversation uses the MLS protocol.

    func isMLSConversation(
        _ conversation: ZMConversation
    ) async -> Bool

    /// Fetches the MLS group ID from a conversation.
    /// - parameter conversation: The conversation to fetch the MLS group ID for.
    /// - returns: The MLS conversation group ID.

    func mlsGroupID(
        for conversation: ZMConversation
    ) async -> MLSGroupID?

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

}

public final class ConversationLocalStore: ConversationLocalStoreProtocol {

    enum Error: Swift.Error {
        case noBackendConversationID
    }

    // MARK: - Properties

    let context: NSManagedObjectContext
    let mlsService: any MLSServiceInterface
    let eventProcessingLogger = OldWireLogger.eventProcessing
    let mlsLogger = OldWireLogger.mls
    let updateEventLogger = OldWireLogger.updateEvent
    let userLocalStore: any UserLocalStoreProtocol
    let messageLocalStore: any MessageLocalStoreProtocol

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        mlsService: MLSServiceInterface,
        userLocalStore: any UserLocalStoreProtocol,
        messageLocalStore: any MessageLocalStoreProtocol
    ) {
        self.context = context
        self.mlsService = mlsService
        self.userLocalStore = userLocalStore
        self.messageLocalStore = messageLocalStore
    }

    // MARK: - Public

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
        conversation: (id: UUID, domain: String)
    ) async throws {
        typealias UserAndRole = (user: ZMUser, role: Role?)

        let localConversation = await fetchConversation(
            id: conversation.id,
            domain: conversation.domain
        )

        guard let localConversation else {
            return OldWireLogger.eventProcessing.error(
                "Member join update missing conversation, aborting... ",
                attributes: [
                    .conversationId: conversation.id.safeForLoggingDescription
                ]
            )
        }

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
                            in: localConversation
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
            in: localConversation
        )
        let newUsers = users.subtracting(existingUsers)

        if !newUsers.isEmpty, await isGroupConversation(localConversation) {

            let systemMessageType: MessageType = .participantsAdded(
                participants: participants.map { ($0.id, $0.domain) },
                sender: sender,
                date: date
            )

            await messageLocalStore.addSystemMessageToConversation(
                messageType: systemMessageType,
                conversationID: conversation.id,
                conversationDomain: conversation.domain
            )
        }

        await context.perform {
            localConversation.addParticipantsAndUpdateConversationState(
                usersAndRoles: usersAndRoles
            )
        }
    }

    public func storeConversation(
        _ conversation: Conversation,
        timestamp: Date,
        isFederationEnabled: Bool,
        isMLSEnabled: Bool
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
                from: conversation,
                withID: id,
                serverTimestamp: timestamp,
                isFederationEnabled: isFederationEnabled,
                isMLSEnabled: isMLSEnabled
            )

        case .`self`:
            await updateOrCreateSelfConversation(
                from: conversation,
                withID: id,
                serverTimestamp: timestamp,
                isFederationEnabled: isFederationEnabled
            )

        case .connection:
            /// Conversations are of type `connection` while the connection
            /// is pending.
            await updateOrCreateConnectionConversation(
                from: conversation,
                withID: id,
                serverTimestamp: timestamp,
                isFederationEnabled: isFederationEnabled
            )

        case .oneOnOne:
            /// Conversations are of type `oneOnOne` when the connection
            /// is accepted.
            await updateOrCreateOneToOneConversation(
                from: conversation,
                withID: id,
                serverTimestamp: timestamp,
                isFederationEnabled: isFederationEnabled
            )
        }
    }

    public func storeConversation(
        needsBackendUpdate: Bool,
        conversationID: UUID,
        conversationDomain: String
    ) async {
        await context.perform { [context] in
            let conversation = ZMConversation.fetch(
                with: conversationID,
                domain: conversationDomain,
                in: context
            )

            conversation?.needsToBeUpdatedFromBackend = needsBackendUpdate
        }
    }

    public func storeFailedConversation(
        conversationID: UUID,
        conversationDomain: String
    ) async {
        let conversation = await fetchOrCreateConversation(
            id: conversationID,
            domain: conversationDomain
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

    public func conversationMutedMessageTypes(
        _ conversation: ZMConversation
    ) async -> MutedMessageTypes {
        await context.perform {
            conversation.mutedMessageTypes
        }
    }

    public func conversationMessageDestructionTimeout(
        _ conversation: ZMConversation
    ) async -> MessageDestructionTimeoutValue {
        await context.perform {
            conversation.activeMessageDestructionTimeoutValue ?? .init(rawValue: 0)
        }
    }

    public func storeConversation(
        timeoutValue: Double,
        for conversation: ZMConversation
    ) async {
        await context.perform {
            conversation.setMessageDestructionTimeoutValue(
                .init(rawValue: timeoutValue),
                for: .groupConversation
            )
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
        participantID: UUID,
        participantDomain: String?,
        date: Date
    ) async throws {

        let user = try await userLocalStore.fetchUser(
            id: participantID,
            domain: participantDomain
        )

        let allGroupConversations = await context.perform {
            // swiftformat:disable:next redundantProperty
            let allGroupConversations: [ZMConversation] = user.participantRoles.compactMap {
                guard $0.conversation?.conversationType == .group else {
                    return nil
                }

                return $0.conversation
            }

            return allGroupConversations
        }

        for conversation in allGroupConversations {
            let (userTeam, isTeamMember, conversationTeam, conversationID, conversationDomain) = await context.perform {
                (
                    user.team,
                    user.isTeamMember,
                    conversation.team,
                    conversation.remoteIdentifier as UUID,
                    conversation.domain
                )
            }

            if isTeamMember, conversationTeam == userTeam {

                let systemMessageType: MessageType = .teamMemberRemoved(
                    member: (participantID, participantDomain),
                    date: date
                )

                await messageLocalStore.addSystemMessageToConversation(
                    messageType: systemMessageType,
                    conversationID: conversationID,
                    conversationDomain: conversationDomain
                )

            } else {

                let systemMessageType: MessageType = .participantsRemoved(
                    participants: [(participantID, participantDomain)],
                    sender: (participantID, participantDomain),
                    date: date
                )

                await messageLocalStore.addSystemMessageToConversation(
                    messageType: systemMessageType,
                    conversationID: conversationID,
                    conversationDomain: conversationDomain
                )
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

    public func isMLSConversation(
        _ conversation: ZMConversation
    ) async -> Bool {
        await context.perform {
            conversation.messageProtocol == .mls
        }
    }

    public func mlsGroupID(
        for conversation: ZMConversation
    ) async -> MLSGroupID? {
        await context.perform {
            conversation.mlsGroupID
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

    public func conversationName(
        conversation: ZMConversation
    ) async -> String? {
        await context.perform {
            conversation.userDefinedName
        }
    }

    public func storeConversation(
        newName: String,
        conversation: ZMConversation
    ) async {
        await context.perform {
            conversation.userDefinedName = newName
        }
    }

    // MARK: - Private

    /// Updates or creates a conversation of type `connection` locally.
    ///
    /// See <doc:conversations> and <doc:federation> for more information.
    ///
    /// - Parameter conversation: The up-to-date conversation object.
    /// - Parameter id: The conversation ID.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateConnectionConversation(
        from conversation: Conversation,
        withID id: UUID,
        serverTimestamp: Date,
        isFederationEnabled: Bool
    ) async {
        let localConversation = await fetchOrCreateConversation(
            id: id,
            domain: conversation.qualifiedID?.domain
        )

        await context.perform { [self] in
            localConversation.conversationType = .connection

            commonUpdate(
                from: conversation,
                for: localConversation,
                serverTimestamp: serverTimestamp,
                isFederationEnabled: isFederationEnabled
            )
            assignMessageProtocol(
                from: conversation,
                for: localConversation
            )

            updateConversationStatus(
                from: conversation,
                for: localConversation
            )

            localConversation.needsToBeUpdatedFromBackend = false
            localConversation.isPendingInitialFetch = false
        }

        guard let selfMember = conversation.members?.selfMember else {
            return
        }

        let mutedStatusInfo = (selfMember.mutedStatus, selfMember.mutedReference)
        let archivedStatusInfo = (selfMember.archived, selfMember.archivedReference)

        await updateMemberStatus(
            mutedStatusInfo: mutedStatusInfo,
            archivedStatusInfo: archivedStatusInfo,
            for: localConversation
        )
    }

    /// Updates or creates a conversation of type `self` locally.
    ///
    /// See <doc:conversations> and <doc:federation> for more information.
    ///
    /// - Parameter conversation: The up-to-date conversation object.
    /// - Parameter id: The conversation ID.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateSelfConversation(
        from conversation: Conversation,
        withID id: UUID,
        serverTimestamp: Date,
        isFederationEnabled: Bool
    ) async {

        let localConversation = await fetchOrCreateConversation(
            id: id,
            domain: conversation.qualifiedID?.domain
        )

        let mlsGroupID = await context.perform {
            conversation.mlsGroupID
        }

        await context.perform { [self] in
            localConversation.conversationType = .`self`
            localConversation.isPendingMetadataRefresh = false

            commonUpdate(
                from: conversation,
                for: localConversation,
                serverTimestamp: serverTimestamp,
                isFederationEnabled: isFederationEnabled
            )

            updateMessageProtocol(
                from: conversation,
                for: localConversation
            )

            localConversation.isPendingInitialFetch = false
            localConversation.needsToBeUpdatedFromBackend = false
        }

        if mlsGroupID != nil {
            do {
                try await createOrJoinSelfConversation(from: localConversation)
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
    /// - Parameter conversation: The up-to-date conversation object.
    /// - Parameter id: The conversation ID.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateGroupConversation(
        from conversation: Conversation,
        withID id: UUID,
        serverTimestamp: Date,
        isFederationEnabled: Bool,
        isMLSEnabled: Bool
    ) async {
        var isInitialFetch = false

        let localConversation = await fetchOrCreateConversation(
            id: id,
            domain: conversation.qualifiedID?.domain
        )

        await context.perform { [self] in
            isInitialFetch = localConversation.isPendingInitialFetch

            localConversation.conversationType = .group
            localConversation.remoteIdentifier = id
            localConversation.isPendingMetadataRefresh = false
            localConversation.isPendingInitialFetch = false

            commonUpdate(
                from: conversation,
                for: localConversation,
                serverTimestamp: serverTimestamp,
                isFederationEnabled: isFederationEnabled
            )

            updateConversationStatus(
                from: conversation,
                for: localConversation
            )

            if isInitialFetch {
                assignMessageProtocol(
                    from: conversation,
                    for: localConversation
                )
            } else {
                updateMessageProtocol(
                    from: conversation,
                    for: localConversation
                )
            }

            Flow.createGroup.checkpoint(
                description: "conversation created remote id: \(localConversation.remoteIdentifier?.safeForLoggingDescription ?? "<nil>")"
            )
        }

        if let selfMember = conversation.members?.selfMember {
            let mutedStatusInfo = (selfMember.mutedStatus, selfMember.mutedReference)
            let archivedStatusInfo = (selfMember.archived, selfMember.archivedReference)

            await updateMemberStatus(
                mutedStatusInfo: mutedStatusInfo,
                archivedStatusInfo: archivedStatusInfo,
                for: localConversation
            )
        }

        await updateMLSStatus(
            from: conversation,
            for: localConversation,
            isMLSEnabled: isMLSEnabled
        )

        await context.perform { [self] in
            if isInitialFetch {
                /// we just got a new conversation, we display new conversation header
                localConversation.appendNewConversationSystemMessage(
                    at: .distantPast,
                    users: localConversation.localParticipants
                )

                /// Slow synced conversations should be considered read from the start
                localConversation.lastReadServerTimeStamp = localConversation.lastModifiedDate

                Flow.createGroup.checkpoint(
                    description: "new system message for conversation inserted"
                )
            }

            /// If we discover this group is actually a fake one on one,
            /// then we should link the one on one user.
            linkOneOnOneUserIfNeeded(for: localConversation)
        }
    }

    /// Updates or creates a conversation of type `1:1` locally.
    ///
    /// See <doc:conversations> and <doc:federation> for more information.
    ///
    /// - Parameter conversation: The up-to-date conversation object.
    /// - Parameter id: The conversation ID.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.

    private func updateOrCreateOneToOneConversation(
        from conversation: Conversation,
        withID id: UUID,
        serverTimestamp: Date,
        isFederationEnabled: Bool
    ) async {
        guard let conversationTypeRawValue = conversation.type?.rawValue else {
            return
        }

        let localConversation = await fetchOrCreateConversation(
            id: id,
            domain: conversation.qualifiedID?.domain
        )

        await context.perform { [self] in
            let conversationType = BackendConversationType.clientConversationType(
                rawValue: conversationTypeRawValue
            )

            if localConversation.oneOnOneUser?.connection?.status == .sent {
                localConversation.conversationType = .connection
            } else {
                localConversation.conversationType = conversationType
            }

            assignMessageProtocol(
                from: conversation,
                for: localConversation
            )

            commonUpdate(
                from: conversation,
                for: localConversation,
                serverTimestamp: serverTimestamp,
                isFederationEnabled: isFederationEnabled
            )

            linkOneOnOneUserIfNeeded(for: localConversation)

            localConversation.needsToBeUpdatedFromBackend = false
            localConversation.isPendingInitialFetch = false

            updateConversationStatus(
                from: conversation,
                for: localConversation
            )

            if let otherUser = localConversation.localParticipantsExcludingSelf.first {
                localConversation.isPendingMetadataRefresh = otherUser.isPendingMetadataRefresh
            }
        }

        guard let selfMember = conversation.members?.selfMember else {
            return
        }

        let mutedStatusInfo = (selfMember.mutedStatus, selfMember.mutedReference)
        let archivedStatusInfo = (selfMember.archived, selfMember.archivedReference)

        await updateMemberStatus(
            mutedStatusInfo: mutedStatusInfo,
            archivedStatusInfo: archivedStatusInfo,
            for: localConversation
        )
    }

    /// A common update method for all conversations received, no matter the type of the conversation.
    ///
    /// - Parameter conversation: The up-to-date conversation object.
    /// - Parameter localConversation: The local conversation to update.
    /// - Parameter isFederationEnabled: A flag indicating whether a federation is enabled.
    /// - Parameter serverTimestamp: The date the conversation was created/updated.

    private func commonUpdate(
        from conversation: Conversation,
        for localConversation: ZMConversation,
        serverTimestamp: Date,
        isFederationEnabled: Bool
    ) {
        updateAttributes(
            from: conversation,
            for: localConversation,
            isFederationEnabled: isFederationEnabled
        )

        updateMetadata(
            from: conversation,
            for: localConversation
        )

        updateMembers(
            from: conversation,
            for: localConversation
        )

        updateConversationTimestamps(
            for: localConversation,
            serverTimestamp: serverTimestamp
        )
    }

    /// A helper method (for all conversations) that fetches or creates a conversation locally and executes a completion
    /// block.
    ///
    /// - Parameter conversationID: The conversation ID to fetch or create the local conversation from.
    /// - Parameter conversationDomain: The domain to fetch or create the conversation from.
    /// - Parameter handler: A completion block that takes a `ZMConversation` as argument and returns
    ///   a `ZMConversation` and an optional `MLSGroupID`.
    ///
    ///  Since storage logic can be different according to the conversation type, the method provides a completion block
    ///  with the conversation fetched or created locally.

    @discardableResult
    private func fetchOrCreateConversation(
        conversationID: UUID,
        conversationDomain: String?,
        handler: @escaping (ZMConversation) -> (ZMConversation, MLSGroupID?)
    ) async -> (ZMConversation, MLSGroupID?) {

        let conversation = await fetchOrCreateConversation(
            id: conversationID,
            domain: conversationDomain
        )

        return await context.perform {
            handler(conversation)
        }
    }

}

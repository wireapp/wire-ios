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

import CoreData
import GenericMessageProtocol
import WireDataModel
import WireLogging

public final class ConversationLocalStore: ConversationLocalStoreProtocol {

    enum Error: Swift.Error {
        case noBackendConversationID
    }

    // MARK: - Properties

    let context: NSManagedObjectContext
    let mlsService: (any MLSServiceInterface)?
    let eventProcessingLogger = WireLogger.eventProcessing
    let mlsLogger = WireLogger.mls
    let updateEventLogger = WireLogger.updateEvent
    let messageLocalStore: any MessageLocalStoreProtocol
    private let localDomain: String?
    private let isFederationEnabled: Bool

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        mlsService: (any MLSServiceInterface)?,
        messageLocalStore: any MessageLocalStoreProtocol,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.context = context
        self.mlsService = mlsService
        self.messageLocalStore = messageLocalStore
        self.localDomain = localDomain
        self.isFederationEnabled = isFederationEnabled
    }

    // MARK: - Public

    public func qualifiedID(for conversation: ZMConversation) async -> QualifiedID? {
        await context.perform {
            conversation.qualifiedID
        }
    }

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

    public func storeMLSConversationEstablished(
        mlsGroupID: MLSGroupID,
        conversation: ZMConversation
    ) async {
        await context.perform {
            conversation.mlsStatus = .ready
            conversation.mlsGroupID = mlsGroupID
        }
    }

    public func storeMLSConversationPendingJoinAfterReset(
        newMLSGroupID: MLSGroupID,
        conversation: ZMConversation
    ) async {
        await context.perform {
            conversation.mlsStatus = .pendingJoinAfterReset
            conversation.mlsGroupID = newMLSGroupID
        }
    }

    public func updateOrCreateMLSGroup(
        groupID: MLSGroupID
    ) async {
        await context.perform { [context] in

            MLSGroup.updateOrCreate(
                id: groupID,
                inSyncContext: context
            ) {
                $0.lastKeyMaterialUpdate = .now
            }
        }
    }

    public func fetchOtherUserIDInOneOnOneConversation(
        conversation: ZMConversation
    ) async -> WireDataModel.QualifiedID? {
        await context.perform {
            guard conversation.conversationType == .oneOnOne else {
                WireLogger.conversation.info(
                    "conversation type is not expected 'oneOnOne', aborting."
                )

                return nil
            }

            guard
                let otherUser = conversation.localParticipantsExcludingSelf.first,
                let otherUserID = otherUser.remoteIdentifier,
                let otherUserDomain = otherUser.domain ?? self.localDomain
            else {
                WireLogger.conversation.warn(
                    "failed to retrieve other user in 1:1 conversation"
                )

                return nil
            }

            return QualifiedID(
                uuid: otherUserID,
                domain: otherUserDomain
            )
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

    public func fetchAllMLSConversations(domain: String?) async throws -> [ZMConversation] {
        try await context.perform { [context] in
            try ZMConversation.fetchConversationsWithMLSGroupStatus(
                mlsGroupStatus: .ready,
                domain: domain,
                in: context
            )
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

    public func increaseUnreadCount(
        for conversation: ZMConversation
    ) async {
        await context.perform {
            conversation.internalEstimatedUnreadCount += 1
        }
    }

    public func decreaseUnreadCount(
        for conversation: ZMConversation
    ) async {
        await context.perform {
            conversation.internalEstimatedUnreadCount -= 1
        }
    }

    public func increaseUnreadSelfMentionCount(
        for conversation: ZMConversation
    ) async {
        await context.perform {
            conversation.internalEstimatedUnreadSelfMentionCount += 1
        }
    }

    public func increaseUnreadSelfReplyCount(
        for conversation: ZMConversation
    ) async {
        await context.perform {
            conversation.internalEstimatedUnreadSelfReplyCount += 1
        }
    }

    public func unreadConversationCount() async -> UInt {
        await context.perform { [context] in
            ZMConversation.unreadConversationCount(in: context)
        }
    }

    public func storeConversation(
        permission: Conversation.ChannelPermission,
        conversation: ZMConversation
    ) async {
        await context.perform {
            conversation.privateChannelPermission = PrivateChannelPermission(permission)
        }
    }

    public func storeConversation(
        historyDepth: String,
        conversationID: UUID,
        conversationDomain: String?
    ) async throws {
        let conversation = await fetchConversation(
            id: conversationID,
            domain: conversationDomain
        )

        await context.perform {
            conversation?.channelHistoryDepth = historyDepth
        }
    }

    public func fetchServerTimeDelta() async -> TimeInterval {
        await context.perform { [context] in
            context.serverTimeDelta
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
            return WireLogger.eventProcessing.error(
                "Member join update missing conversation, aborting... ",
                attributes: [
                    .conversationId: conversation.id.safeForLoggingDescription
                ]
            )
        }

        let usersAndRoles = await withTaskGroup(of: UserAndRole?.self) { taskGroup in
            for newParticipant in participants {
                taskGroup.addTask { [self] in
                    let user = await context.perform { [context] in
                        ZMUser.fetchOrCreate(
                            with: newParticipant.id,
                            domain: newParticipant.domain,
                            in: context
                        )
                    }

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

            return usersAndRoles.compactMap(\.self)
        }

        let users = Set(usersAndRoles.map(\.user))
        let existingUsers = await localParticipants(
            in: localConversation
        )
        let newUsers = users.subtracting(existingUsers)

        if !newUsers.isEmpty, await isGroupConversation(localConversation) {

            let systemMessageType: SystemMessageType = .participantsAdded(
                participants: participants.map { ($0.id, $0.domain) },
                sender: sender,
                date: date
            )

            await messageLocalStore.addSystemMessage(
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

    public func obtainPermanentIDs(
        user: ZMUser,
        conversation: ZMConversation
    ) async {
        await context.perform { [context] in
            if user.objectID.isTemporaryID || conversation.objectID.isTemporaryID {
                do {
                    try context.obtainPermanentIDs(for: [user, conversation])
                } catch {
                    WireLogger.eventProcessing.error(
                        "Failed to obtain permanent object ids: \(error.localizedDescription)"
                    )
                }
            }
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

    public func createMLSConversation(
        conversationID: UUID,
        conversationDomain: String?,
        mlsGroupID: MLSGroupID
    ) async {
        await context.perform { [context] in
            let conversation = ZMConversation.fetchOrCreate(
                with: conversationID,
                domain: conversationDomain,
                in: context
            )

            conversation.remoteIdentifier = conversationID
            conversation.domain = conversationDomain
            conversation.mlsGroupID = mlsGroupID
            conversation.mlsStatus = .ready
            context.saveOrRollback()
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

    public func conversationNeedsBackendUpdate(
        _ conversation: ZMConversation
    ) async -> Bool {
        await context.perform {
            conversation.needsToBeUpdatedFromBackend
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

    public func isMessageSilenced(
        _ message: GenericMessage,
        senderID: UUID?,
        conversation: ZMConversation
    ) async -> Bool {
        await context.perform {
            conversation.isMessageSilenced(message, senderID: senderID)
        }
    }

    public func shouldHideNotification() async -> Bool {
        await context.perform { [context] in
            let ZMShouldHideNotificationContentKey = "ZMShouldHideNotificationContentKey"
            let value = context.persistentStoreMetadata(
                forKey: ZMShouldHideNotificationContentKey
            ) as? NSNumber

            return value?.boolValue ?? false
        }
    }

    public func updateCommitPendingProposal(
        date: Date,
        for conversation: ZMConversation,
        commitDelay: UInt64
    ) async {
        let scheduledDate = date + TimeInterval(commitDelay)

        await context.perform {
            conversation.commitPendingProposalDate = scheduledDate
        }
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
        let participant = await context.perform { [context] in
            ZMUser.fetch(
                with: participantID,
                domain: participantDomain,
                in: context
            )
        }
        guard let participant else {
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

    public func conversationMutedMessageTypesIncludingAvailability(
        _ conversation: ZMConversation
    ) async -> MutedMessageTypes {
        await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)
            return selfUser.mutedMessagesTypes.union(conversation.mutedMessageTypes)
        }
    }

    public func lastReadServerTimestamp(
        _ conversation: ZMConversation
    ) async -> Date? {
        await context.perform {
            conversation.lastReadServerTimeStamp
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

    public func isSelfConversation(_ conversation: ZMConversation) async -> Bool {
        await context.perform {
            conversation.conversationType == .self
        }
    }

    public func name(
        for conversation: ZMConversation
    ) async -> String? {
        await context.perform {
            conversation.displayName
        }
    }

    public func removeParticipantFromAllGroupConversations(
        participantID: UUID,
        participantDomain: String?,
        date: Date
    ) async throws {

        let user = await context.perform { [context] in
            ZMUser.fetchOrCreate(
                with: participantID,
                domain: participantDomain,
                in: context
            )
        }

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

                let systemMessageType: SystemMessageType = .teamMemberRemoved(
                    member: (participantID, participantDomain),
                    date: date
                )

                await messageLocalStore.addSystemMessage(
                    messageType: systemMessageType,
                    conversationID: conversationID,
                    conversationDomain: conversationDomain
                )

            } else {

                let systemMessageType: SystemMessageType = .participantsRemoved(
                    participants: [(participantID, participantDomain)],
                    sender: (participantID, participantDomain),
                    date: date
                )

                await messageLocalStore.addSystemMessage(
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
        try await mlsService?.wipeGroup(groupID)
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

    private func notifyTypingUsers(
        _ typingUsers: Set<ZMUser>,
        in conversation: ZMConversation
    ) {
        let typingNotificationUsersKey = "typingUsers"

        NotificationInContext(
            name: .typingNotification,
            context: context.notificationContext,
            object: self,
            userInfo: [typingNotificationUsersKey: typingUsers]
        ).post()
    }

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
            localConversation.groupType = conversation.groupType.map { groupType in
                switch groupType {
                case .group:
                    .group
                case .channel:
                    .channel
                }
            } ?? .none

            localConversation.privateChannelPermission = conversation
                .addPermission.map { PrivateChannelPermission($0) } ?? .unset

            localConversation.cellsState = conversation.cellsState.map { cellsState in
                switch cellsState {
                case .ready:
                    .ready
                case .pending:
                    .pending
                case .disabled:
                    .disabled
                }
            } ?? .disabled

            commonUpdate(
                from: conversation,
                for: localConversation,
                serverTimestamp: serverTimestamp,
                isFederationEnabled: isFederationEnabled,
                shouldRemoveParticipants: false
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
                // we just got a new conversation, we display new conversation header
                localConversation.appendNewConversationSystemMessage(
                    at: .distantPast,
                    users: localConversation.localParticipants
                )

                // Slow synced conversations should be considered read from the start
                localConversation.lastReadServerTimeStamp = localConversation.lastModifiedDate

                Flow.createGroup.checkpoint(
                    description: "new system message for conversation inserted"
                )
            }

            // If we discover this group is actually a fake one on one,
            // then we should link the one on one user.
            linkOneOnOneUserIfNeeded(for: localConversation)

            // All metadata has been updated, object does not need to be updated from backend
            localConversation.needsToBeUpdatedFromBackend = false
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
        isFederationEnabled: Bool,
        shouldRemoveParticipants: Bool = true
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
            for: localConversation,
            shouldRemoveParticipants: shouldRemoveParticipants
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

    public func execute(
        identifier: MLSGroupID,
        block: @escaping @Sendable (ZMConversation?, NSManagedObjectContext) -> Void
    ) async {
        await context.perform { [context] in
            let conversation = ZMConversation.fetch(with: identifier, in: context)
            block(conversation, context)
        }
    }
}

// MARK: - Private helpers

private extension PrivateChannelPermission {

    init(_ value: Conversation.ChannelPermission) {
        switch value {
        case .admins:
            self = .admins
        case .everyone:
            self = .everyone
        }
    }
}

//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

final class ConversationEventPayloadProcessor {

    enum Source {
        case slowSync
        case eventStream
    }

    // MARK: - Properties

    private let mlsEventProcessor: MLSEventProcessing

    // MARK: - Life cycle

    convenience init(context: NSManagedObjectContext) {
        self.init(mlsEventProcessor: MLSEventProcessor(context: context))
    }

    init(mlsEventProcessor: MLSEventProcessing) {
        self.mlsEventProcessor = mlsEventProcessor
    }

    // MARK: - Conversation creation

    func updateOrCreateConversations(
        from payload: Payload.ConversationList,
        in context: NSManagedObjectContext
    ) {
        for payload in payload.conversations {
            updateOrCreateConversation(
                from: payload,
                source: .slowSync,
                in: context
            )
        }
    }

    func updateOrCreateConverations(
        from payload: Payload.QualifiedConversationList,
        in context: NSManagedObjectContext
    ) {
        for payload in payload.found {
            updateOrCreateConversation(
                from: payload,
                source: .slowSync,
                in: context
            )
        }
    }

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.Conversation>,
        in context: NSManagedObjectContext
    ) {
        guard let timestamp = payload.timestamp else {
            Logging.eventProcessing.error("Conversation creation missing timestamp in event, aborting...")
            return
        }

        updateOrCreateConversation(
            from: payload.data,
            serverTimestamp: timestamp,
            source: .eventStream,
            in: context
        )
    }

    // MARK: - Conversation deletion

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.UpdateConversationDeleted>,
        in context: NSManagedObjectContext
    ) {
        guard let conversation = fetchOrCreateConversation(
            from: payload,
            in: context
        ) else {
            Logging.eventProcessing.error("Conversation deletion missing conversation in event, aborting...")
            return
        }

        conversation.isDeletedRemotely = true
    }

    // MARK: - Member leave

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.UpdateConverationMemberLeave>,
        originalEvent: ZMUpdateEvent,
        in context: NSManagedObjectContext
    ) {
        guard
            let conversation = fetchOrCreateConversation(
                from: payload,
                in: context
            ),
            let removedUsers = fetchRemovedUsers(
                from: payload.data,
                in: context
            )
        else {
            Logging.eventProcessing.error("Member leave update missing conversation or users, aborting...")
            return
        }

        if !conversation.localParticipants.isDisjoint(with: removedUsers) {
            // TODO jacob refactor to append method on conversation
            _ = ZMSystemMessage.createOrUpdate(
                from: originalEvent,
                in: context
            )
        }

        let sender = fetchOrCreateSender(
            from: payload,
            in: context
        )

        // Idea for improvement, return removed users from this call to benefit from
        // checking that the participants are in the conversation before being removed
        conversation.removeParticipantsAndUpdateConversationState(users: Set(removedUsers), initiatingUser: sender)

        if removedUsers.contains(where: \.isSelfUser), conversation.messageProtocol == .mls {
            mlsEventProcessor.wipeMLSGroup(forConversation: conversation, context: context)
        }
    }

    // MARK: - Member join

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.UpdateConverationMemberJoin>,
        originalEvent: ZMUpdateEvent,
        in context: NSManagedObjectContext
    ) {
        guard let conversation = fetchOrCreateConversation(
            from: payload,
            in: context
        ) else {
            Logging.eventProcessing.error("Member join update missing conversation, aborting...")
            return
        }

        if let usersAndRoles = payload.data.users?.map({
            fetchUserAndRole(
                from: $0,
                for: conversation,
                in: context
            )!
        }) {
            let selfUser = ZMUser.selfUser(in: context)
            let users = Set(usersAndRoles.map { $0.0 })
            let newUsers = !users.subtracting(conversation.localParticipants).isEmpty

            if users.contains(selfUser) || newUsers {
                // TODO jacob refactor to append method on conversation
                _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: context)
            }

            conversation.addParticipantsAndUpdateConversationState(usersAndRoles: usersAndRoles)
        } else if let users = payload.data.userIDs?.map({ ZMUser.fetchOrCreate(with: $0, domain: nil, in: context)}) {
            // NOTE: legacy code path for backwards compatibility with servers without role support

            let users = Set(users)
            let selfUser = ZMUser.selfUser(in: context)

            if !users.isSubset(of: conversation.localParticipantsExcludingSelf) || users.contains(selfUser) {
                // TODO jacob refactor to append method on conversation
                _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: context)
            }
            conversation.addParticipantsAndUpdateConversationState(users: users, role: nil)
        }
    }

    // MARK: - Conversation rename

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.UpdateConversationName>,
        originalEvent: ZMUpdateEvent,
        in context: NSManagedObjectContext
    ) {
        guard let conversation = fetchOrCreateConversation(
            from: payload,
            in: context
        ) else {
            Logging.eventProcessing.error("Conversation name update missing conversation, aborting...")
            return
        }

        if conversation.userDefinedName != payload.data.name || ((conversation.modifiedKeys?.contains(ZMConversationUserDefinedNameKey)) != nil) {
            // TODO jacob refactor to append method on conversation
            _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: context)
        }

        conversation.userDefinedName = payload.data.name
    }

    // MARK: - Member update

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.ConversationMember>,
        in context: NSManagedObjectContext
    ) {
        guard
            let conversation = fetchOrCreateConversation(
                from: payload,
                in: context
            ),
            let targetUser = fetchOrCreateTargetUser(
                from: payload.data,
                in: context
            )
        else {
            Logging.eventProcessing.error("Conversation member update missing conversation or target user, aborting...")
            return
        }

        if targetUser.isSelfUser {
            if let mutedStatus = payload.data.mutedStatus,
               let mutedReference = payload.data.mutedReference {
                conversation.updateMutedStatus(status: Int32(mutedStatus), referenceDate: mutedReference)
            }

            if let archived = payload.data.archived,
               let archivedReference = payload.data.archivedReference {
                conversation.updateArchivedStatus(archived: archived, referenceDate: archivedReference)
            }
        }

        if let role = payload.data.conversationRole.map({conversation.fetchOrCreateRoleForConversation(name: $0) }) {
            conversation.addParticipantAndUpdateConversationState(user: targetUser, role: role)
        }
    }

    // MARK: - Access mode update

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.UpdateConversationAccess>,
        in context: NSManagedObjectContext
    ) {
        guard let conversation = fetchOrCreateConversation(
            from: payload,
            in: context
        ) else {
            Logging.eventProcessing.error("Converation access update missing conversation, aborting...")
            return
        }

        if let accessRoles = payload.data.accessRoleV2 {
            conversation.updateAccessStatus(accessModes: payload.data.access, accessRoles: accessRoles)
        } else if let accessRole = payload.data.accessRole, let legacyAccessRole = ConversationAccessRole(rawValue: accessRole) {
            let accessRoles = ConversationAccessRoleV2.fromLegacyAccessRole(legacyAccessRole)
            conversation.updateAccessStatus(accessModes: payload.data.access, accessRoles: accessRoles.map(\.rawValue))
        }
    }

    // MARK: - Message timer update

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.UpdateConversationMessageTimer>,
        in context: NSManagedObjectContext
    ) {
        guard
            let sender = fetchOrCreateSender(
                from: payload,
                in: context
            ),
            let conversation = fetchOrCreateConversation(
                from: payload,
                in: context
            )
        else {
            Logging.eventProcessing.error("Conversation message timer update missing sender or conversation, aborting...")
            return
        }

        let timeoutValue = (payload.data.messageTimer ?? 0) / 1000
        let timeout: MessageDestructionTimeoutValue = .init(rawValue: timeoutValue)
        let currentTimeout = conversation.activeMessageDestructionTimeoutValue ?? .init(rawValue: 0)

        if let timestamp = payload.timestamp, currentTimeout != timeout {
            conversation.appendMessageTimerUpdateMessage(fromUser: sender, timer: timeoutValue, timestamp: timestamp)
        }
        conversation.setMessageDestructionTimeoutValue(.init(rawValue: timeoutValue), for: .groupConversation)
    }

    // MARK: - Receipt mode update

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.UpdateConversationReceiptMode>,
        in context: NSManagedObjectContext
    ) {
        guard
            let sender = fetchOrCreateSender(
                from: payload,
                in: context
            ),
            let conversation = fetchOrCreateConversation(
                from: payload,
                in: context
            ),
            let timestamp = payload.timestamp,
            timestamp > conversation.lastServerTimeStamp // Discard event if it has already been applied
        else {
            Logging.eventProcessing.error("Conversation receipt mode has already been updated, aborting...")
            return
        }

        let enabled = payload.data.readReceiptMode > 0
        conversation.hasReadReceiptsEnabled = enabled
        conversation.appendMessageReceiptModeChangedMessage(fromUser: sender, timestamp: timestamp, enabled: enabled)
    }

    // MARK: - Connection request

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.UpdateConversationConnectionRequest>,
        originalEvent: ZMUpdateEvent,
        in context: NSManagedObjectContext
    ) {
        // TODO jacob refactor to append method on conversation
        _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: context)
    }

    // MARK: - Helpers

    @discardableResult
    func updateOrCreateConversation(
        from payload: Payload.Conversation,
        serverTimestamp: Date = Date(),
        source: Source = .eventStream,
        in context: NSManagedObjectContext
    ) -> ZMConversation? {
        guard let conversationType = payload.type.map(BackendConversationType.clientConversationType) else {
            return nil
        }

        switch conversationType {
        case .group:
            return updateOrCreateGroupConversation(
                from: payload,
                in: context,
                serverTimestamp: serverTimestamp,
                source: source
            )

        case .`self`:
            return updateOrCreateSelfConversation(
                from: payload,
                in: context,
                serverTimestamp: serverTimestamp,
                source: source
            )

        case .connection:
            // Conversations are of type `connection` while the connection
            // is pending.
            return updateOrCreateConnectionConversation(
                from: payload,
                in: context,
                serverTimestamp: serverTimestamp,
                source: source
            )

        case .oneOnOne:
            // Conversations are of type `oneOnOne` when the connection
            // is accepted.
            return updateOrCreateOneToOneConversation(
                from: payload,
                in: context,
                serverTimestamp: serverTimestamp,
                source: source
            )


        default:
            return nil
        }
    }

    @discardableResult
    func updateOrCreateGroupConversation(
        from payload: Payload.Conversation,
        in context: NSManagedObjectContext,
        serverTimestamp: Date,
        source: Source
    ) -> ZMConversation? {
        guard let conversationID = payload.id ?? payload.qualifiedID?.uuid else {
            Logging.eventProcessing.error("Missing conversationID in group conversation payload, aborting...")
            return nil
        }

        var created = false
        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: payload.qualifiedID?.domain,
            in: context,
            created: &created
        )

        conversation.conversationType = .group
        conversation.remoteIdentifier = conversationID
        conversation.isPendingMetadataRefresh = false
        updateAttributes(from: payload, for: conversation, context: context)
        updateMetadata(from: payload, for: conversation, context: context)
        updateMembers(from: payload, for: conversation, context: context)
        updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
        updateConversationStatus(from: payload, for: conversation)
        updateMessageProtocol(from: payload, for: conversation)
        updateMLSStatus(from: payload, for: conversation, context: context, source: source)

        if created {
            // we just got a new conversation, we display new conversation header
            conversation.appendNewConversationSystemMessage(at: serverTimestamp,
                                                            users: conversation.localParticipants)

            if source == .slowSync {
                // Slow synced conversations should be considered read from the start
                conversation.lastReadServerTimeStamp = conversation.lastModifiedDate
            }
        }

        return conversation
    }

    @discardableResult
    func updateOrCreateSelfConversation(
        from payload: Payload.Conversation,
        in context: NSManagedObjectContext,
        serverTimestamp: Date,
        source: Source
    ) -> ZMConversation? {
        guard let conversationID = payload.id ?? payload.qualifiedID?.uuid else {
            Logging.eventProcessing.error("Missing conversationID in self conversation payload, aborting...")
            return nil
        }

        var created = false
        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: payload.qualifiedID?.domain,
            in: context,
            created: &created
        )

        conversation.conversationType = .`self`
        conversation.isPendingMetadataRefresh = false
        updateAttributes(from: payload, for: conversation, context: context)
        updateMetadata(from: payload, for: conversation, context: context)
        updateMembers(from: payload, for: conversation, context: context)
        updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
        updateMessageProtocol(from: payload, for: conversation)

        if conversation.mlsGroupID != nil {
            createOrJoinSelfConversation(from: conversation)
        }

        return conversation
    }

    func createOrJoinSelfConversation(from conversation: ZMConversation) {
        guard
            let groupId = conversation.mlsGroupID,
            let mlsService = conversation.managedObjectContext?.mlsService
        else {
            WireLogger.mls.warn("no mlsService to createOrJoinSelfConversation")
            return
        }

        WireLogger.mls.debug("createOrJoinSelfConversation for \(groupId.safeForLoggingDescription); conv payload: \(String(describing: self))")

        if conversation.epoch <= 0 {
            mlsService.createSelfGroup(for: groupId)
        } else if !mlsService.conversationExists(groupID: groupId) {
            Task {
                try await mlsService.joinGroup(with: groupId)
            }
        }
    }

    @discardableResult
    func updateOrCreateConnectionConversation(
        from payload: Payload.Conversation,
        in context: NSManagedObjectContext,
        serverTimestamp: Date,
        source: Source
    ) -> ZMConversation? {
        guard let conversationID = payload.id ?? payload.qualifiedID?.uuid else {
            Logging.eventProcessing.error("Missing conversation or type in 1:1 conversation payload, aborting...")
            return nil
        }

        let conversation = ZMConversation.fetchOrCreate(with: conversationID, domain: payload.qualifiedID?.domain, in: context)
        conversation.conversationType = .connection
        updateAttributes(from: payload, for: conversation, context: context)
        updateMessageProtocol(from: payload, for: conversation)
        updateMetadata(from: payload, for: conversation, context: context)
        updateMembers(from: payload, for: conversation, context: context)
        updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
        updateConversationStatus(from: payload, for: conversation)
        conversation.needsToBeUpdatedFromBackend = false
        return conversation
    }

    @discardableResult
    func updateOrCreateOneToOneConversation(
        from payload: Payload.Conversation,
        in context: NSManagedObjectContext,
        serverTimestamp: Date,
        source: Source
    ) -> ZMConversation? {
        guard 
            let conversationID = payload.id ?? payload.qualifiedID?.uuid,
            let conversationType = payload.type.map(BackendConversationType.clientConversationType)
        else {
            Logging.eventProcessing.error("Missing conversation or type in 1:1 conversation payload, aborting...")
            return nil
        }

        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: payload.qualifiedID?.domain,
            in: context
        )

        if
            let otherMember = payload.members?.others.first,
            let otherUserID = otherMember.id ?? otherMember.qualifiedID?.uuid
        {
            let otherUser = ZMUser.fetchOrCreate(with: otherUserID, domain: otherMember.qualifiedID?.domain, in: context)
            otherUser.connection?.conversation = conversation
            conversation.isPendingMetadataRefresh = otherUser.isPendingMetadataRefresh
        }

        conversation.conversationType = self.conversationType(for: conversation, from: conversationType)
        updateAttributes(from: payload, for: conversation, context: context)
        updateMessageProtocol(from: payload, for: conversation)
        updateMetadata(from: payload, for: conversation, context: context)
        updateMembers(from: payload, for: conversation, context: context)
        updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
        updateConversationStatus(from: payload, for: conversation)
        conversation.needsToBeUpdatedFromBackend = false

        establishMLSGroupIfNeeded(for: conversation, in: context)

        return conversation
    }

    private func establishMLSGroupIfNeeded(
        for conversation: ZMConversation,
        in context: NSManagedObjectContext
    ) {
        guard 
            conversation.messageProtocol != .mls,
            let otherUser = conversation.connection?.to
        else {
            return
        }

        let selfUser = ZMUser.selfUser(in: context)
        let commonProtocols = selfUser.supportedProtocols.intersection(otherUser.supportedProtocols)

        guard !commonProtocols.isEmpty else {
            conversation.isForcedReadOnly = true
            return
        }

        guard commonProtocols.contains(.mls) else {
            return
        }

        guard
            let mlsService = context.mlsService,
            let otherUserID = otherUser.remoteIdentifier,
            let otherUserDomain = otherUser.domain ?? BackendInfo.domain
        else {
            return
        }

        Task {
            let otherUserID = QualifiedID(
                uuid: otherUserID,
                domain: otherUserDomain
            )

            let mlsGroupID = try await mlsService.establishOneToOneGroupIfNeeded(
                with: otherUserID,
                in: context
            )

            await context.perform {
                let conversation = ZMConversation.fetch(with: mlsGroupID, in: context)
                otherUser.connection?.conversation.conversationType = .invalid
                otherUser.connection?.conversation = conversation
            }
        }
    }

    private func updateAttributes(
        from payload: Payload.Conversation,
        for conversation: ZMConversation,
        context: NSManagedObjectContext
    ) {
        conversation.domain = BackendInfo.isFederationEnabled ? payload.qualifiedID?.domain : nil
        conversation.needsToBeUpdatedFromBackend = false

        if let epoch = payload.epoch.flatMap(UInt64.init) {
            conversation.epoch = epoch
        }

        if let mlsGroupID = payload.mlsGroupID.flatMap(MLSGroupID.init(base64Encoded:)) {
            conversation.mlsGroupID = mlsGroupID
        }
    }

    func updateMetadata(
        from payload: Payload.Conversation,
        for conversation: ZMConversation,
        context: NSManagedObjectContext
    ) {
        if let teamID = payload.teamID {
            conversation.updateTeam(identifier: teamID)
        }

        if let name = payload.name {
            conversation.userDefinedName = name
        }

        if let creator = fetchCreator(
            from: payload,
            in: context
        ) {
            conversation.creator = creator
        }
    }

    func updateMembers(
        from payload: Payload.Conversation,
        for conversation: ZMConversation,
        context: NSManagedObjectContext
    ) {
        guard let members = payload.members else {
            return
        }

        let otherMembers = fetchOtherMembers(
            from: members,
            conversation: conversation,
            in: context
        )

        let selfUserRole = fetchUserAndRole(
            from: members.selfMember,
            for: conversation,
            in: context
        )?.1

        conversation.updateMembers(otherMembers, selfUserRole: selfUserRole)
    }

    func updateConversationTimestamps(
        for conversation: ZMConversation,
        serverTimestamp: Date
    ) {
        // If the lastModifiedDate is non-nil, e.g. restore from backup,
        // do not update the lastModifiedDate.
        if conversation.lastModifiedDate == nil {
            conversation.updateLastModified(serverTimestamp)
        }

        conversation.updateServerModified(serverTimestamp)
    }

    func updateConversationStatus(
        from payload: Payload.Conversation,
        for conversation: ZMConversation
    ) {
        if let selfMember = payload.members?.selfMember {
            updateMemberStatus(
                from: selfMember,
                for: conversation
            )
        }

        if let readReceiptMode = payload.readReceiptMode {
            conversation.updateReceiptMode(readReceiptMode)
        }

        if let accessModes = payload.access {
            if let accessRoles = payload.accessRoles {
                conversation.updateAccessStatus(accessModes: accessModes, accessRoles: accessRoles)
            } else if 
                let accessRole = payload.legacyAccessRole,
                let legacyAccessRole = ConversationAccessRole(rawValue: accessRole) 
            {
                let accessRoles = ConversationAccessRoleV2.fromLegacyAccessRole(legacyAccessRole)
                conversation.updateAccessStatus(accessModes: accessModes, accessRoles: accessRoles.map(\.rawValue))
            }
        }

        if let messageTimer = payload.messageTimer {
            conversation.updateMessageDestructionTimeout(timeout: messageTimer)
        }
    }

    private func updateMessageProtocol(
        from payload: Payload.Conversation,
        for conversation: ZMConversation
    ) {
        guard let messageProtocolString = payload.messageProtocol else {
            Logging.eventProcessing.warn("message protocol is missing")
            return
        }

        guard let messageProtocol = MessageProtocol(string: messageProtocolString) else {
            Logging.eventProcessing.warn("message protocol is invalid, got: \(messageProtocolString)")
            return
        }

        conversation.messageProtocol = messageProtocol
    }

    private func updateMLSStatus(
        from payload: Payload.Conversation,
        for conversation: ZMConversation,
        context: NSManagedObjectContext,
        source: Source
    ) {
        mlsEventProcessor.updateConversationIfNeeded(
            conversation: conversation,
            groupID: payload.mlsGroupID,
            context: context
        )

        if source == .slowSync {
            mlsEventProcessor.joinMLSGroupWhenReady(
                forConversation: conversation,
                context: context
            )
        }
    }

    func fetchCreator(
        from payload: Payload.Conversation,
        in context: NSManagedObjectContext
    ) -> ZMUser? {
        guard let userID = payload.creator else {
            return nil
        }

        // We assume that the creator always belongs to the same domain as the conversation
        return ZMUser.fetchOrCreate(
            with: userID,
            domain: payload.qualifiedID?.domain,
            in: context
        )
    }

    private func conversationType(
        for conversation: ZMConversation?,
        from type: ZMConversationType
    ) -> ZMConversationType {
        guard let conversation = conversation else {
            return type
        }

        // The backend can't distinguish between one-to-one and connection conversation
        // types across federated enviroments so check locally if it's a connection.
        if conversation.connection?.status == .sent {
            return .connection
        } else {
            return type
        }
    }

    func fetchOrCreateConversation<T>(
        from payload: Payload.ConversationEvent<T>,
        in context: NSManagedObjectContext
    ) -> ZMConversation? {
        guard let conversationID = payload.id ?? payload.qualifiedID?.uuid else {
            return nil
        }

        return ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: payload.qualifiedID?.domain,
            in: context
        )
    }

    func fetchRemovedUsers(
        from payload: Payload.UpdateConverationMemberLeave,
        in context: NSManagedObjectContext
    ) -> [ZMUser]? {
        if let users = payload.qualifiedUserIDs?.map({ ZMUser.fetchOrCreate(with: $0.uuid, domain: $0.domain, in: context) }) {
            return users
        }

        if let users = payload.userIDs?.map({ ZMUser.fetchOrCreate(with: $0, domain: nil, in: context) }) {
            return users
        }

        return nil
    }

    func fetchOrCreateSender<T>(
        from payload: Payload.ConversationEvent<T>,
        in context: NSManagedObjectContext
    ) -> ZMUser? {
        guard let userID = payload.from ?? payload.qualifiedFrom?.uuid else {
            return nil
        }

        return ZMUser.fetchOrCreate(
            with: userID,
            domain: payload.qualifiedFrom?.domain,
            in: context
        )
    }

    func fetchOrCreateTargetUser(
        from payload: Payload.ConversationMember,
        in context: NSManagedObjectContext
    ) -> ZMUser? {
        guard let userID = payload.target ?? payload.qualifiedTarget?.uuid else {
            return nil
        }

        return ZMUser.fetchOrCreate(
            with: userID,
            domain: payload.qualifiedTarget?.domain,
            in: context
        )
    }

    func fetchOtherMembers(
        from payload: Payload.ConversationMembers,
        conversation: ZMConversation,
        in context: NSManagedObjectContext
    ) -> [(ZMUser, Role?)] {
        return payload.others.compactMap {
            fetchUserAndRole(
                from: $0,
                for: conversation,
                in: context
            )
        }
    }

    func fetchUserAndRole(
        from payload: Payload.ConversationMember,
        for conversation: ZMConversation,
        in context: NSManagedObjectContext
    ) -> (ZMUser, Role?)? {
        guard let userID = payload.id ?? payload.qualifiedID?.uuid else {
            return nil
        }

        let user = ZMUser.fetchOrCreate(
            with: userID,
            domain: payload.qualifiedID?.domain,
            in: context
        )

        let role = payload.conversationRole.map {
            conversation.fetchOrCreateRoleForConversation(name: $0)
        }

        return (user, role)
    }

    private func updateMemberStatus(
        from payload: Payload.ConversationMember,
        for conversation: ZMConversation
    ) {
        if let mutedStatus = payload.mutedStatus,
           let mutedReference = payload.mutedReference {
            conversation.updateMutedStatus(status: Int32(mutedStatus), referenceDate: mutedReference)
        }

        if let archived = payload.archived,
           let archivedReference = payload.archivedReference {
            conversation.updateArchivedStatus(archived: archived, referenceDate: archivedReference)
        }
    }

}

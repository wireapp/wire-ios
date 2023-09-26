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

    // MARK: - Conversation creation

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
            MLSEventProcessor.shared.wipeMLSGroup(forConversation: conversation, context: context)
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

        if let usersAndRoles = payload.data.users?.map({ $0.fetchUserAndRole(in: context, conversation: conversation)! }) {
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

    // MARK: - Helpers

    @discardableResult
    private func updateOrCreateConversation(
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

        case .connection, .oneOnOne:
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
        conversation.domain = BackendInfo.isFederationEnabled ? payload.qualifiedID?.domain : nil
        conversation.needsToBeUpdatedFromBackend = false
        conversation.isPendingMetadataRefresh = false
        conversation.epoch = UInt64(payload.epoch ?? 0)

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
        conversation.domain = BackendInfo.isFederationEnabled ? payload.qualifiedID?.domain : nil
        conversation.needsToBeUpdatedFromBackend = false
        conversation.isPendingMetadataRefresh = false

        updateMetadata(from: payload, for: conversation, context: context)
        updateMembers(from: payload, for: conversation, context: context)
        updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)

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
            let rawConversationType = payload.type
        else {
            Logging.eventProcessing.error("Missing conversation or type in 1:1 conversation payload, aborting...")
            return nil
        }

        let conversationType = BackendConversationType.clientConversationType(rawValue: rawConversationType)

        guard
            let otherMember = payload.members?.others.first,
            let otherUserID = otherMember.id ?? otherMember.qualifiedID?.uuid
        else {
            let conversation = ZMConversation.fetch(with: conversationID, domain: payload.qualifiedID?.domain, in: context)
            // TODO: use conversation type from the backend once it returns the correct value
            conversation?.conversationType = self.conversationType(for: conversation, from: conversationType)
            conversation?.needsToBeUpdatedFromBackend = false
            return conversation
        }

        let otherUser = ZMUser.fetchOrCreate(with: otherUserID, domain: otherMember.qualifiedID?.domain, in: context)

        var conversation: ZMConversation
        if let existingConversation = otherUser.connection?.conversation {
            existingConversation.mergeWithExistingConversation(withRemoteID: conversationID)
            conversation = existingConversation
        } else {
            conversation = ZMConversation.fetchOrCreate(with: conversationID, domain: payload.qualifiedID?.domain, in: context)
            otherUser.connection?.conversation = conversation
        }

        conversation.remoteIdentifier = conversationID
        conversation.domain = BackendInfo.isFederationEnabled ? payload.qualifiedID?.domain : nil

        // TODO: use conversation type from the backend once it returns the correct value
        conversation.conversationType = self.conversationType(for: conversation, from: conversationType)

        updateMetadata(from: payload, for: conversation, context: context)
        updateMembers(from: payload, for: conversation, context: context)
        updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
        updateConversationStatus(from: payload, for: conversation)

        conversation.needsToBeUpdatedFromBackend = false
        conversation.isPendingMetadataRefresh = otherUser.isPendingMetadataRefresh

        return conversation
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
        if let members = payload.members {
            let otherMembers = members.fetchOtherMembers(in: context, conversation: conversation)
            let selfUserRole = members.selfMember.fetchUserAndRole(in: context, conversation: conversation)?.1
            conversation.updateMembers(otherMembers, selfUserRole: selfUserRole)
        }
    }

    func updateConversationTimestamps(
        for conversation: ZMConversation,
        serverTimestamp: Date
    ) {
        // If the lastModifiedDate is non-nil, e.g. restore from backup, do not update the lastModifiedDate
        if conversation.lastModifiedDate == nil { // TODO jacob review this logic
            conversation.updateLastModified(serverTimestamp)
        }

        conversation.updateServerModified(serverTimestamp)
    }

    func updateConversationStatus(
        from payload: Payload.Conversation,
        for conversation: ZMConversation
    ) {
        if let selfMember = payload.members?.selfMember {
            selfMember.updateStatus(for: conversation)
        }

        if let readReceiptMode = payload.readReceiptMode {
            conversation.updateReceiptMode(readReceiptMode)
        }

        if let accessModes = payload.access {
            if let accessRoles = payload.accessRoles {
                conversation.updateAccessStatus(accessModes: accessModes, accessRoles: accessRoles)
            } else if let accessRole = payload.legacyAccessRole,
            let legacyAccessRole = ConversationAccessRole(rawValue: accessRole) {
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
        let mlsEventProcessor = MLSEventProcessor.shared

        mlsEventProcessor.updateConversationIfNeeded(
            conversation: conversation,
            groupID: payload.mlsGroupID,
            context: context
        )

        if source == .slowSync {
            mlsEventProcessor.joinMLSGroupWhenReady(forConversation: conversation, context: context)
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

    // There is a bug in the backend where the conversation type is not correct for
    // connection requests across federated backends. Instead of returning `.connection` type,
    // it returns `oneOnOne.
    // We fix this temporarily on our side by checking the connection status of the conversation.
    private func conversationType(
        for conversation: ZMConversation?,
        from type: ZMConversationType
    ) -> ZMConversationType {
        guard let conversation = conversation else {
            return type
        }

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

}

// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

// MARK: - Conversation

extension Payload.ConversationMember {

    func fetchUserAndRole(in context: NSManagedObjectContext,
                          conversation: ZMConversation) -> (ZMUser, Role?)? {
        guard let userID = id ?? qualifiedID?.uuid else { return nil }
        return (ZMUser.fetchOrCreate(with: userID, domain: qualifiedID?.domain, in: context),
                conversationRole.map({conversation.fetchOrCreateRoleForConversation(name: $0) }))
    }

    func updateStatus(for conversation: ZMConversation) {

        if let mutedStatus = mutedStatus,
           let mutedReference = mutedReference {
            conversation.updateMutedStatus(status: Int32(mutedStatus), referenceDate: mutedReference)
        }

        if let archived = archived,
           let archivedReference = archivedReference {
            conversation.updateArchivedStatus(archived: archived, referenceDate: archivedReference)
        }

    }

}

extension Payload.ConversationMembers {

    func fetchOtherMembers(in context: NSManagedObjectContext, conversation: ZMConversation) -> [(ZMUser, Role?)] {
        return others.compactMap({ $0.fetchUserAndRole(in: context, conversation: conversation) })
    }

}

extension Payload.Conversation {

    enum Source {
        case slowSync
        case eventStream
    }

    func fetchCreator(in context: NSManagedObjectContext) -> ZMUser? {
        guard let userID = creator else { return nil }

        // We assume that the creator always belongs to the same domain as the conversation
        return ZMUser.fetchOrCreate(with: userID, domain: qualifiedID?.domain, in: context)
    }

    @discardableResult
    func updateOrCreate(
        in context: NSManagedObjectContext,
        serverTimestamp: Date = Date(),
        source: Source = .eventStream
    ) -> ZMConversation? {
        guard let conversationType = type.map(BackendConversationType.clientConversationType) else {
            return nil
        }

        switch conversationType {
        case .group:
            return updateOrCreateGroupConversation(
                in: context,
                serverTimestamp: serverTimestamp,
                source: source
            )

        case .`self`:
            return updateOrCreateSelfConversation(
                in: context,
                serverTimestamp: serverTimestamp,
                source: source
            )

        case .connection, .oneOnOne:
            return updateOrCreateOneToOneConversation(
                in: context,
                serverTimestamp: serverTimestamp,
                source: source
            )

        default:
            return nil
        }
    }

    @discardableResult
    func updateOrCreateOneToOneConversation(
        in context: NSManagedObjectContext,
        serverTimestamp: Date,
        source: Source
    ) -> ZMConversation? {
        guard
            let conversationID = id ?? qualifiedID?.uuid,
            let rawConversationType = type
        else {
            Logging.eventProcessing.error("Missing conversation or type in 1:1 conversation payload, aborting...")
            return nil
        }

        let conversationType = BackendConversationType.clientConversationType(rawValue: rawConversationType)

        guard
            let otherMember = members?.others.first,
            let otherUserID = otherMember.id ?? otherMember.qualifiedID?.uuid
        else {
            let conversation = ZMConversation.fetch(with: conversationID, domain: qualifiedID?.domain, in: context)
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
            conversation = ZMConversation.fetchOrCreate(with: conversationID, domain: qualifiedID?.domain, in: context)
            otherUser.connection?.conversation = conversation
        }

        conversation.remoteIdentifier = conversationID
        conversation.domain = BackendInfo.isFederationEnabled ? qualifiedID?.domain : nil

        // TODO: use conversation type from the backend once it returns the correct value
        conversation.conversationType = self.conversationType(for: conversation, from: conversationType)

        updateMetadata(for: conversation, context: context)
        updateMembers(for: conversation, context: context)
        updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
        updateConversationStatus(for: conversation)

        conversation.needsToBeUpdatedFromBackend = false
        conversation.isPendingMetadataRefresh = otherUser.isPendingMetadataRefresh

        return conversation
    }

    @discardableResult
    func updateOrCreateSelfConversation(
        in context: NSManagedObjectContext,
        serverTimestamp: Date,
        source: Source
    ) -> ZMConversation? {
        guard let conversationID = id ?? qualifiedID?.uuid else {
            Logging.eventProcessing.error("Missing conversationID in self conversation payload, aborting...")
            return nil
        }

        var created = false
        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: qualifiedID?.domain,
            in: context,
            created: &created
        )

        conversation.conversationType = .`self`
        conversation.isPendingMetadataRefresh = false
        updateAttributes(for: conversation, context: context)
        updateMetadata(for: conversation, context: context)
        updateMembers(for: conversation, context: context)
        updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
        updateMessageProtocol(for: conversation)

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

        WireLogger.mls.debug("createOrJoinSelfConversation for \(groupId); conv payload: \(String(describing: self))")

        if conversation.epoch <= 0 {
            mlsService.createSelfGroup(for: groupId)
        } else if !mlsService.conversationExists(groupID: groupId) {
            Task {
                try await mlsService.joinGroup(with: groupId)
            }
        }
    }

    @discardableResult
    func updateOrCreateGroupConversation(
        in context: NSManagedObjectContext,
        serverTimestamp: Date,
        source: Source
    ) -> ZMConversation? {
        guard let conversationID = id ?? qualifiedID?.uuid else {
            Logging.eventProcessing.error("Missing conversationID in group conversation payload, aborting...")
            return nil
        }

        var created = false
        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: qualifiedID?.domain,
            in: context,
            created: &created
        )

        conversation.conversationType = .group

        conversation.remoteIdentifier = conversationID
        conversation.isPendingMetadataRefresh = false
        updateAttributes(for: conversation, context: context)
        updateMetadata(for: conversation, context: context)
        updateMembers(for: conversation, context: context)
        updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
        updateConversationStatus(for: conversation)
        updateMessageProtocol(for: conversation)
        updateMLSStatus(for: conversation, context: context, source: source)

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

    private func updateAttributes(for conversation: ZMConversation, context: NSManagedObjectContext) {
        conversation.domain = BackendInfo.isFederationEnabled ? qualifiedID?.domain : nil
        conversation.needsToBeUpdatedFromBackend = false
        conversation.epoch = UInt64(epoch ?? 0)

        conversation.mlsGroupID = self.mlsGroupID.flatMap { MLSGroupID(base64Encoded: $0) }
    }

    // There is a bug in the backend where the conversation type is not correct for
    // connection requests across federated backends. Instead of returning `.connection` type,
    // it returns `oneOnOne.
    // We fix this temporarily on our side by checking the connection status of the conversation.
    private func conversationType(for conversation: ZMConversation?, from type: ZMConversationType) -> ZMConversationType {
        guard let conversation = conversation else {
            return type
        }

        if conversation.connection?.status == .sent {
            return .connection
        } else {
            return type
        }
    }

    func updateMetadata(for conversation: ZMConversation, context: NSManagedObjectContext) {
        if let teamID = teamID {
            conversation.updateTeam(identifier: teamID)
        }

        if let name = name {
            conversation.userDefinedName = name
        }

        if let creator = fetchCreator(in: context) {
            conversation.creator = creator
        }
    }

    func updateMembers(for conversation: ZMConversation, context: NSManagedObjectContext) {
        if let members = members {
            let otherMembers = members.fetchOtherMembers(in: context, conversation: conversation)
            let selfUserRole = members.selfMember.fetchUserAndRole(in: context, conversation: conversation)?.1
            conversation.updateMembers(otherMembers, selfUserRole: selfUserRole)
        }
    }

    func updateConversationTimestamps(for conversation: ZMConversation, serverTimestamp: Date) {
        // If the lastModifiedDate is non-nil, e.g. restore from backup, do not update the lastModifiedDate
        if conversation.lastModifiedDate == nil { // TODO jacob review this logic
            conversation.updateLastModified(serverTimestamp)
        }

        conversation.updateServerModified(serverTimestamp)
    }

    func updateConversationStatus(for conversation: ZMConversation) {

        if let selfMember = members?.selfMember {
            selfMember.updateStatus(for: conversation)
        }

        if let readReceiptMode = readReceiptMode {
            conversation.updateReceiptMode(readReceiptMode)
        }

        if let accessModes = access {
            if let accessRoles = accessRoles {
                conversation.updateAccessStatus(accessModes: accessModes, accessRoles: accessRoles)
            } else if let accessRole = legacyAccessRole,
                      let legacyAccessRole = ConversationAccessRole(rawValue: accessRole) {
                let accessRoles = ConversationAccessRoleV2.fromLegacyAccessRole(legacyAccessRole)
                conversation.updateAccessStatus(accessModes: accessModes, accessRoles: accessRoles.map(\.rawValue))
            }
        }

        if let messageTimer = messageTimer {
            conversation.updateMessageDestructionTimeout(timeout: messageTimer)
        }
    }

    private func updateMessageProtocol(for conversation: ZMConversation) {
        guard let messageProtocolString = messageProtocol else {
            Logging.eventProcessing.warn("message protocol is missing")
            return
        }

        guard let messageProtocol = MessageProtocol(string: messageProtocolString) else {
            Logging.eventProcessing.warn("message protocol is invalid, got: \(messageProtocolString)")
            return
        }

        conversation.messageProtocol = messageProtocol
    }

    private func updateMLSStatus(for conversation: ZMConversation, context: NSManagedObjectContext, source: Source) {
        let mlsEventProcessor = MLSEventProcessor.shared

        mlsEventProcessor.updateConversationIfNeeded(
            conversation: conversation,
            groupID: mlsGroupID,
            context: context
        )

        if source == .slowSync {
            mlsEventProcessor.joinMLSGroupWhenReady(
                forConversation: conversation,
                context: context
            )
        }
    }

}

extension Payload.ConversationList {

    func updateOrCreateConverations(in context: NSManagedObjectContext) {
        conversations.forEach({ $0.updateOrCreate(in: context, source: .slowSync) })
    }

}

extension Payload.QualifiedConversationList {

    func updateOrCreateConverations(in context: NSManagedObjectContext) {
        found.forEach({ $0.updateOrCreate(in: context, source: .slowSync) })
    }

}

extension Payload.ConversationEvent {

    func fetchOrCreateConversation(in context: NSManagedObjectContext) -> ZMConversation? {
        guard let conversationID = id ?? qualifiedID?.uuid else { return nil }
        return ZMConversation.fetchOrCreate(with: conversationID, domain: qualifiedID?.domain, in: context)
    }

    func fetchOrCreateSender(in context: NSManagedObjectContext) -> ZMUser? {
        guard let userID = from ?? qualifiedFrom?.uuid else { return nil }
        return ZMUser.fetchOrCreate(with: userID, domain: qualifiedFrom?.domain, in: context)
    }

}

// MARK: - Conversation events

extension Payload.ConversationEvent where T == Payload.UpdateConversationName {

    func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
        guard
            let conversation = fetchOrCreateConversation(in: context)
        else {
            Logging.eventProcessing.error("Conversation name update missing conversation, aborting...")
            return
        }

        if conversation.userDefinedName != data.name || ((conversation.modifiedKeys?.contains(ZMConversationUserDefinedNameKey)) != nil) {
            // TODO jacob refactor to append method on conversation
            _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: context)
        }

        conversation.userDefinedName = data.name
    }

}

extension Payload.ConversationEvent where T == Payload.UpdateConverationMemberLeave {

    func fetchRemovedUsers(in context: NSManagedObjectContext) -> [ZMUser]? {
        if let users = data.qualifiedUserIDs?.map({ ZMUser.fetchOrCreate(with: $0.uuid, domain: $0.domain, in: context) }) {
            return users
        }

        if let users = data.userIDs?.map({ ZMUser.fetchOrCreate(with: $0, domain: nil, in: context) }) {
            return users
        }

        return nil
    }

    func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
        guard
            let conversation = fetchOrCreateConversation(in: context),
            let removedUsers = fetchRemovedUsers(in: context)
        else {
            Logging.eventProcessing.error("Member leave update missing conversation or users, aborting...")
            return
        }

        if !conversation.localParticipants.isDisjoint(with: removedUsers) {
            // TODO jacob refactor to append method on conversation
            _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: context)
        }

        let sender = fetchOrCreateSender(in: context)

        // Idea for improvement, return removed users from this call to benefit from
        // checking that the participants are in the conversation before being removed
        conversation.removeParticipantsAndUpdateConversationState(users: Set(removedUsers), initiatingUser: sender)

        if removedUsers.contains(where: \.isSelfUser), conversation.messageProtocol == .mls {
            MLSEventProcessor.shared.wipeMLSGroup(forConversation: conversation, context: context)
        }
    }

}

extension Payload.ConversationEvent where T == Payload.ConversationMember {

    func fetchOrCreateTargetUser(in context: NSManagedObjectContext) -> ZMUser? {
        guard
            let userID = data.target ?? data.qualifiedTarget?.uuid
        else {
            return nil
        }

        return ZMUser.fetchOrCreate(with: userID, domain: data.qualifiedTarget?.domain, in: context)
    }

    func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
        guard
            let conversation = fetchOrCreateConversation(in: context),
            let targetUser =  fetchOrCreateTargetUser(in: context)
        else {
            Logging.eventProcessing.error("Conversation member update missing conversation or target user, aborting...")
            return
        }

        if targetUser.isSelfUser {
            data.updateStatus(for: conversation)
        }

        if let role = data.conversationRole.map({conversation.fetchOrCreateRoleForConversation(name: $0) }) {
            conversation.addParticipantAndUpdateConversationState(user: targetUser, role: role)
        }
    }
}

extension Payload.ConversationEvent where T == Payload.UpdateConversationAccess {

    func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
        guard
            let conversation = fetchOrCreateConversation(in: context)
        else {
            Logging.eventProcessing.error("Converation access update missing conversation, aborting...")
            return
        }

        if let accessRoles = data.accessRoleV2 {
            conversation.updateAccessStatus(accessModes: data.access, accessRoles: accessRoles)
        } else if let accessRole = data.accessRole, let legacyAccessRole = ConversationAccessRole(rawValue: accessRole) {
            let accessRoles = ConversationAccessRoleV2.fromLegacyAccessRole(legacyAccessRole)
            conversation.updateAccessStatus(accessModes: data.access, accessRoles: accessRoles.map(\.rawValue))
        }
    }

}

extension Payload.ConversationEvent where T == Payload.UpdateConversationMessageTimer {

    func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
        guard
            let sender = fetchOrCreateSender(in: context),
            let conversation = fetchOrCreateConversation(in: context)
        else {
            Logging.eventProcessing.error("Conversation message timer update missing sender or conversation, aborting...")
            return
        }

        let timeoutValue = (data.messageTimer ?? 0) / 1000
        let timeout: MessageDestructionTimeoutValue = .init(rawValue: timeoutValue)
        let currentTimeout = conversation.activeMessageDestructionTimeoutValue ?? .init(rawValue: 0)

        if let timestamp = timestamp, currentTimeout != timeout {
            conversation.appendMessageTimerUpdateMessage(fromUser: sender, timer: timeoutValue, timestamp: timestamp)
        }
        conversation.setMessageDestructionTimeoutValue(.init(rawValue: timeoutValue), for: .groupConversation)
    }

}

extension Payload.ConversationEvent where T == Payload.UpdateConversationReceiptMode {

    func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
        guard
            let sender = fetchOrCreateSender(in: context),
            let conversation = fetchOrCreateConversation(in: context),
            let timestamp = timestamp,
            timestamp > conversation.lastServerTimeStamp // Discard event if it has already been applied
        else {
            Logging.eventProcessing.error("Conversation receipt mode has already been updated, aborting...")
            return
        }

        let enabled = data.readReceiptMode > 0
        conversation.hasReadReceiptsEnabled = enabled
        conversation.appendMessageReceiptModeChangedMessage(fromUser: sender, timestamp: timestamp, enabled: enabled)
    }
}

extension Payload.ConversationEvent where T == Payload.Conversation {

    func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
        guard
            let timestamp = timestamp
        else {
            Logging.eventProcessing.error("Conversation creation missing timestamp in event, aborting...")
            return
        }

        data.updateOrCreate(in: context, serverTimestamp: timestamp, source: .eventStream)
    }
}

extension Payload.ConversationEvent where T == Payload.UpdateConversationDeleted {

    func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
        guard
            let conversation = fetchOrCreateConversation(in: context)
        else {
            Logging.eventProcessing.error("Conversation deletion missing conversation in event, aborting...")
            return
        }

        conversation.isDeletedRemotely = true
    }

}

    extension Payload.ConversationEvent where T == Payload.UpdateConversationConnectionRequest {

        func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
            // TODO jacob refactor to append method on conversation
            _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: context)
        }

    }

    private extension ZMConversation {

        func firstSystemMessage(for systemMessageType: ZMSystemMessageType) -> ZMSystemMessage? {

            return allMessages
                .compactMap { $0 as? ZMSystemMessage }
                .first(where: { $0.systemMessageType == systemMessageType })
        }
    }

    extension Payload.UpdateConversationMLSWelcome {

        func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
            guard let qualifiedID else {
                return
            }

            MLSEventProcessor.shared.process(
                welcomeMessage: data,
                conversationID: qualifiedID,
                in: context
            )
        }
    }

    extension Payload.ConversationEvent where T == Payload.UpdateConverationMemberJoin {

        func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
            guard
                let conversation = fetchOrCreateConversation(in: context)
            else {
                Logging.eventProcessing.error("Member join update missing conversation, aborting...")
                return
            }

            if let usersAndRoles = data.users?.map({ $0.fetchUserAndRole(in: context, conversation: conversation)! }) {
                let selfUser = ZMUser.selfUser(in: context)
                let users = Set(usersAndRoles.map { $0.0 })
                let newUsers = !users.subtracting(conversation.localParticipants).isEmpty

                if users.contains(selfUser) || newUsers {
                    // TODO jacob refactor to append method on conversation
                    _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: context)
                }

                conversation.addParticipantsAndUpdateConversationState(usersAndRoles: usersAndRoles)
            } else if let users = data.userIDs?.map({ ZMUser.fetchOrCreate(with: $0, domain: nil, in: context)}) {
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

    }

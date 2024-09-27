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
import WireDataModel

// MARK: - ConversationEventPayloadProcessorError

enum ConversationEventPayloadProcessorError: Error {
    case noBackendConversationId
}

// MARK: - ConversationEventPayloadProcessor

struct ConversationEventPayloadProcessor {
    // MARK: Lifecycle

    init(
        mlsEventProcessor: MLSEventProcessing,
        removeLocalConversation: RemoveLocalConversationUseCaseProtocol
    ) {
        self.mlsEventProcessor = mlsEventProcessor
        self.removeLocalConversation = removeLocalConversation
    }

    // MARK: Internal

    enum Source {
        case slowSync
        case eventStream
    }

    // MARK: - Conversation creation

    func updateOrCreateConversations(
        from payload: Payload.ConversationList,
        in context: NSManagedObjectContext
    ) async {
        for payload in payload.conversations {
            await updateOrCreateConversation(
                from: payload,
                source: .slowSync,
                in: context
            )
        }
    }

    func updateOrCreateConverations(
        from payload: Payload.QualifiedConversationList,
        in context: NSManagedObjectContext
    ) async {
        for payload in payload.found {
            await updateOrCreateConversation(
                from: payload,
                source: .slowSync,
                in: context
            )
        }
    }

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.Conversation>,
        in context: NSManagedObjectContext
    ) async {
        guard let timestamp = payload.timestamp else {
            WireLogger.eventProcessing.error("Conversation creation missing timestamp in event, aborting...")
            return
        }
        guard let conversationID = payload.id ?? payload.qualifiedID?.uuid else {
            Flow.createGroup.fail(ConversationEventPayloadProcessorError.noBackendConversationId)
            WireLogger.eventProcessing.error("Conversation creation missing conversationID in event, aborting...")
            return
        }
        guard await context.perform({
            ZMConversation.fetch(with: conversationID, domain: payload.qualifiedID?.domain, in: context) == nil
        }) else {
            WireLogger.eventProcessing.warn("Conversation already exists, aborting...")
            return
        }

        await updateOrCreateConversation(
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
    ) async {
        let conversation = await context.perform {
            fetchOrCreateConversation(
                from: payload,
                in: context
            )
        }
        guard let conversation else {
            WireLogger.eventProcessing.error("Conversation deletion missing conversation in event, aborting...")
            return
        }

        do {
            try await removeLocalConversation.invoke(
                with: conversation,
                syncContext: context
            )
        } catch {
            WireLogger.mls.error("removeLocalConversation threw error: \(String(reflecting: error))")
        }
    }

    // MARK: - Member leave

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.UpdateConverationMemberLeave>,
        originalEvent: ZMUpdateEvent,
        in context: NSManagedObjectContext
    ) async {
        let (conversation, removedUsers) = await context.perform {
            let conversation = fetchOrCreateConversation(
                from: payload,
                in: context
            )
            let removedUsers = fetchRemovedUsers(
                from: payload.data,
                in: context
            )
            return (conversation, removedUsers)
        }
        guard let conversation, let removedUsers else {
            WireLogger.eventProcessing.error("Member leave update missing conversation or users, aborting...")
            return
        }

        let (isSelfUserRemoved, messageProtocol) = await context.perform {
            if !conversation.localParticipants.isDisjoint(with: removedUsers) {
                // TODO: jacob refactor to append method on conversation
                _ = ZMSystemMessage.createOrUpdate(
                    from: originalEvent,
                    in: context
                )
            }

            let initiatingUser = fetchOrCreateSender(
                from: payload,
                in: context
            )

            // Idea for improvement, return removed users from this call to benefit from
            // checking that the participants are in the conversation before being removed
            conversation.removeParticipantsAndUpdateConversationState(
                users: Set(removedUsers),
                initiatingUser: initiatingUser
            )

            let isSelfUserRemoved = removedUsers.contains(where: \.isSelfUser)
            return (isSelfUserRemoved, conversation.messageProtocol)
        }

        if DeveloperFlag.enableMLSSupport.isOn {
            if isSelfUserRemoved, messageProtocol.isOne(of: .mls, .mixed) {
                await mlsEventProcessor.wipeMLSGroup(forConversation: conversation, context: context)
            }
        }

        await context.perform {
            if payload.data.reason == .userDeleted {
                // delete the users locally and/or logout if the self user is affected
                let removedUsers = removedUsers.sorted { !$0.isSelfUser && $1.isSelfUser }
                for user in removedUsers {
                    // only delete users that had been members
                    guard let membership = user.membership else {
                        WireLogger.updateEvent.error("Trying to delete non existent membership of \(user)")
                        continue
                    }

                    context.delete(membership)
                    if user.isSelfUser {
                        // should actually be handled by the "user.delete" event, this is just a fallback
                        DispatchQueue.main.async {
                            AccountDeletedNotification(context: context)
                                .post(in: context.notificationContext)
                        }
                    } else {
                        user.markAccountAsDeleted(at: originalEvent.timestamp ?? Date())
                    }
                }
            }
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
            WireLogger.eventProcessing.error("Member join update missing conversation, aborting...")
            return
        }

        if let usersAndRoles = payload.data.users?.map({
            fetchUserAndRole(
                from: $0,
                for: conversation,
                in: context
            )!
        }) {
            let users = Set(usersAndRoles.map(\.0))
            let newUsers = !users.subtracting(conversation.localParticipants).isEmpty

            if newUsers, conversation.conversationType == .group {
                // TODO: jacob refactor to append method on conversation
                _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: context)
            }

            conversation.addParticipantsAndUpdateConversationState(usersAndRoles: usersAndRoles)
        } else if let users = payload.data.userIDs?.map({ ZMUser.fetchOrCreate(with: $0, domain: nil, in: context) }) {
            // NOTE: legacy code path for backwards compatibility with servers without role support

            let users = Set(users)
            let selfUser = ZMUser.selfUser(in: context)

            if !users.isSubset(of: conversation.localParticipantsExcludingSelf) || users.contains(selfUser),
               conversation.conversationType == .group {
                // TODO: jacob refactor to append method on conversation
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
            WireLogger.eventProcessing.error("Conversation name update missing conversation, aborting...")
            return
        }

        if conversation.userDefinedName != payload.data
            .name || ((conversation.modifiedKeys?.contains(ZMConversationUserDefinedNameKey)) != nil) {
            // TODO: jacob refactor to append method on conversation
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
            WireLogger.eventProcessing
                .error("Conversation member update missing conversation or target user, aborting...")
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

        if let role = payload.data.conversationRole.map({ conversation.fetchOrCreateRoleForConversation(name: $0) }) {
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
            WireLogger.eventProcessing.error("Converation access update missing conversation, aborting...")
            return
        }

        if let accessRoles = payload.data.accessRoleV2 {
            conversation.updateAccessStatus(accessModes: payload.data.access, accessRoles: accessRoles)
        } else if let accessRole = payload.data.accessRole,
                  let legacyAccessRole = ConversationAccessRole(rawValue: accessRole) {
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
            WireLogger.eventProcessing
                .error("Conversation message timer update missing sender or conversation, aborting...")
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
            conversation.lastServerTimeStamp == nil || conversation
            .lastServerTimeStamp! < timestamp // Discard event if it has already been applied
        else {
            WireLogger.eventProcessing.error("Conversation receipt mode has already been updated, aborting...")
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
        // TODO: jacob refactor to append method on conversation
        _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: context)
    }

    // MARK: - Protocol Change

    func processPayload(
        _ payload: Payload.ConversationEvent<Payload.UpdateConversationProtocolChange>,
        originalEvent: ZMUpdateEvent,
        in context: NSManagedObjectContext
    ) async {
        guard let qualifiedID = payload.qualifiedID else {
            WireLogger.eventProcessing
                .error(
                    "processPayload of event type \(originalEvent.type): Conversation qualifiedID missing, aborting..."
                )
            return
        }

        do {
            var action = SyncConversationAction(qualifiedID: qualifiedID)
            try await action.perform(in: context.notificationContext)
        } catch {
            WireLogger.eventProcessing
                .error(
                    "processPayload of event type \(originalEvent.type): sync conversation failed with error: \(error)"
                )
        }
    }

    // MARK: - Helpers

    @discardableResult
    func updateOrCreateConversation(
        from payload: Payload.Conversation,
        serverTimestamp: Date = Date(),
        source: Source = .eventStream,
        in context: NSManagedObjectContext
    ) async -> ZMConversation? {
        guard let conversationType = payload.type.map(BackendConversationType.clientConversationType) else {
            return nil
        }

        Flow.createGroup.checkpoint(description: "create ZMConversation of type \(conversationType))")
        switch conversationType {
        case .group:
            return await updateOrCreateGroupConversation(
                from: payload,
                in: context,
                serverTimestamp: serverTimestamp,
                source: source
            )

        case .`self`:
            return await updateOrCreateSelfConversation(
                from: payload,
                in: context,
                serverTimestamp: serverTimestamp,
                source: source
            )

        case .connection:
            // Conversations are of type `connection` while the connection
            // is pending.
            return await updateOrCreateConnectionConversation(
                from: payload,
                in: context,
                serverTimestamp: serverTimestamp,
                source: source
            )

        case .oneOnOne:
            // Conversations are of type `oneOnOne` when the connection
            // is accepted.
            return await updateOrCreateOneToOneConversation(
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
    ) async -> ZMConversation? {
        guard let conversationID = payload.id ?? payload.qualifiedID?.uuid else {
            Flow.createGroup.fail(ConversationEventPayloadProcessorError.noBackendConversationId)
            WireLogger.eventProcessing.error("Missing conversationID in group conversation payload, aborting...")
            return nil
        }

        var isInitialFetch = false
        let conversation = await context.perform {
            let conversation = ZMConversation.fetchOrCreate(
                with: conversationID,
                domain: payload.qualifiedID?.domain,
                in: context
            )

            isInitialFetch = conversation.isPendingInitialFetch

            conversation.conversationType = .group
            conversation.remoteIdentifier = conversationID
            conversation.isPendingMetadataRefresh = false
            conversation.isPendingInitialFetch = false
            updateAttributes(from: payload, for: conversation, context: context)
            updateMetadata(from: payload, for: conversation, context: context)
            updateMembers(from: payload, for: conversation, context: context)
            updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
            updateConversationStatus(from: payload, for: conversation)

            if isInitialFetch {
                assignMessageProtocol(from: payload, for: conversation, in: context)
            } else {
                updateMessageProtocol(from: payload, for: conversation, in: context)
            }

            Flow.createGroup
                .checkpoint(
                    description: "conversation created remote id: \(conversation.remoteIdentifier?.safeForLoggingDescription ?? "<nil>")"
                )

            return conversation
        }

        await updateMLSStatus(from: payload, for: conversation, context: context, source: source)
        await context.perform {
            if isInitialFetch {
                // we just got a new conversation, we display new conversation header
                conversation.appendNewConversationSystemMessage(
                    at: .distantPast,
                    users: conversation.localParticipants
                )

                if source == .slowSync {
                    // Slow synced conversations should be considered read from the start
                    conversation.lastReadServerTimeStamp = conversation.lastModifiedDate
                }
                Flow.createGroup.checkpoint(description: "new system message for conversation inserted")
            }

            // If we discover this group is actually a fake one on one,
            // then we should link the one on one user.
            linkOneOnOneUserIfNeeded(for: conversation)
        }

        return conversation
    }

    @discardableResult
    func updateOrCreateSelfConversation(
        from payload: Payload.Conversation,
        in context: NSManagedObjectContext,
        serverTimestamp: Date,
        source: Source
    ) async -> ZMConversation? {
        guard let conversationID = payload.id ?? payload.qualifiedID?.uuid else {
            WireLogger.eventProcessing.error("Missing conversationID in self conversation payload, aborting...")
            return nil
        }

        let (conversation, mlsGroupID) = await context.perform { [self] in
            let conversation = ZMConversation.fetchOrCreate(
                with: conversationID,
                domain: payload.qualifiedID?.domain,
                in: context
            )

            conversation.conversationType = .`self`
            conversation.isPendingMetadataRefresh = false
            updateAttributes(from: payload, for: conversation, context: context)
            updateMetadata(from: payload, for: conversation, context: context)
            updateMembers(from: payload, for: conversation, context: context)
            updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
            updateMessageProtocol(from: payload, for: conversation, in: context)

            conversation.isPendingInitialFetch = false
            conversation.needsToBeUpdatedFromBackend = false

            return (conversation, conversation.mlsGroupID)
        }

        if mlsGroupID != nil {
            do {
                try await createOrJoinSelfConversation(from: conversation)
            } catch {
                WireLogger.mls.error("createOrJoinSelfConversation threw error: \(String(reflecting: error))")
            }
        }

        return conversation
    }

    func createOrJoinSelfConversation(from conversation: ZMConversation) async throws {
        guard let context = conversation.managedObjectContext else {
            return WireLogger.mls.warn("conversation.managedObjectContext is nil")
        }
        let (groupID, mlsService, hasRegisteredMLSClient) = await context.perform {
            (
                conversation.mlsGroupID,
                context.mlsService,
                ZMUser.selfUser(in: context).selfClient()?.hasRegisteredMLSClient == true
            )
        }

        guard let groupID, let mlsService, hasRegisteredMLSClient else {
            WireLogger.mls.warn("no mlsService or not registered mls client to createOrJoinSelfConversation")
            return
        }

        WireLogger.mls
            .debug(
                "createOrJoinSelfConversation for \(groupID.safeForLoggingDescription); conv payload: \(String(describing: self))"
            )

        if await context.perform({ conversation.epoch <= 0 }) {
            let ciphersuite = try await mlsService.createSelfGroup(for: groupID)
            await context.perform { conversation.ciphersuite = ciphersuite }
        } else if try await !mlsService.conversationExists(groupID: groupID) {
            try await mlsService.joinGroup(with: groupID)
        }
    }

    @discardableResult
    func updateOrCreateConnectionConversation(
        from payload: Payload.Conversation,
        in context: NSManagedObjectContext,
        serverTimestamp: Date,
        source: Source
    ) async -> ZMConversation? {
        guard let conversationID = payload.id ?? payload.qualifiedID?.uuid else {
            WireLogger.eventProcessing.error("Missing conversation or type in 1:1 conversation payload, aborting...")
            return nil
        }

        return await context.perform {
            let conversation = ZMConversation.fetchOrCreate(
                with: conversationID,
                domain: payload.qualifiedID?.domain,
                in: context
            )
            conversation.conversationType = .connection

            updateAttributes(from: payload, for: conversation, context: context)
            assignMessageProtocol(from: payload, for: conversation, in: context)
            updateMetadata(from: payload, for: conversation, context: context)
            updateMembers(from: payload, for: conversation, context: context)
            updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
            updateConversationStatus(from: payload, for: conversation)

            conversation.needsToBeUpdatedFromBackend = false
            conversation.isPendingInitialFetch = false

            return conversation
        }
    }

    @discardableResult
    func updateOrCreateOneToOneConversation(
        from payload: Payload.Conversation,
        in context: NSManagedObjectContext,
        serverTimestamp: Date,
        source: Source
    ) async -> ZMConversation? {
        guard
            let conversationID = payload.id ?? payload.qualifiedID?.uuid,
            let conversationType = payload.type.map(BackendConversationType.clientConversationType)
        else {
            WireLogger.eventProcessing.error("Missing conversation or type in 1:1 conversation payload, aborting...")
            return nil
        }

        return await context.perform {
            let conversation = ZMConversation.fetchOrCreate(
                with: conversationID,
                domain: payload.qualifiedID?.domain,
                in: context
            )

            conversation.conversationType = self.conversationType(for: conversation, from: conversationType)
            updateAttributes(from: payload, for: conversation, context: context)
            assignMessageProtocol(from: payload, for: conversation, in: context)
            updateMetadata(from: payload, for: conversation, context: context)
            updateMembers(from: payload, for: conversation, context: context)
            updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
            updateConversationStatus(from: payload, for: conversation)
            linkOneOnOneUserIfNeeded(for: conversation)

            conversation.needsToBeUpdatedFromBackend = false
            conversation.isPendingInitialFetch = false

            if let otherUser = conversation.localParticipantsExcludingSelf.first {
                conversation.isPendingMetadataRefresh = otherUser.isPendingMetadataRefresh
            }

            return conversation
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
                let legacyAccessRole = ConversationAccessRole(rawValue: accessRole) {
                let accessRoles = ConversationAccessRoleV2.fromLegacyAccessRole(legacyAccessRole)
                conversation.updateAccessStatus(accessModes: accessModes, accessRoles: accessRoles.map(\.rawValue))
            }
        }

        if let messageTimer = payload.messageTimer {
            conversation.updateMessageDestructionTimeout(timeout: messageTimer)
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

    func fetchOrCreateConversation(
        from payload: Payload.ConversationEvent<some Any>,
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
        if let users = payload.qualifiedUserIDs?.map({ ZMUser.fetchOrCreate(
            with: $0.uuid,
            domain: $0.domain,
            in: context
        ) }) {
            return users
        }

        if let users = payload.userIDs?.map({ ZMUser.fetchOrCreate(with: $0, domain: nil, in: context) }) {
            return users
        }

        return nil
    }

    func fetchOrCreateSender(
        from payload: Payload.ConversationEvent<some Any>,
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
        payload.others.compactMap {
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

    // MARK: Private

    // MARK: - Properties

    private let mlsEventProcessor: MLSEventProcessing
    private let removeLocalConversation: RemoveLocalConversationUseCaseProtocol

    private func linkOneOnOneUserIfNeeded(for conversation: ZMConversation) {
        guard
            conversation.conversationType == .oneOnOne,
            let otherUser = conversation.localParticipantsExcludingSelf.first
        else {
            return
        }

        conversation.oneOnOneUser = otherUser
    }

    private func updateAttributes(
        from payload: Payload.Conversation,
        for conversation: ZMConversation,
        context: NSManagedObjectContext
    ) {
        conversation.domain = BackendInfo.isFederationEnabled ? payload.qualifiedID?.domain : nil
        conversation.needsToBeUpdatedFromBackend = false

        if let epoch = payload.epoch {
            conversation.epoch = UInt64(epoch)
        }

        if
            let base64String = payload.mlsGroupID,
            let mlsGroupID = MLSGroupID(base64Encoded: base64String) {
            conversation.mlsGroupID = mlsGroupID
        }

        if let ciphersuite = payload.cipherSuite, let epoch = payload.epoch, epoch > 0 {
            conversation.ciphersuite = MLSCipherSuite(rawValue: Int(ciphersuite))
        }
    }

    private func assignMessageProtocol(
        from payload: Payload.Conversation,
        for conversation: ZMConversation,
        in context: NSManagedObjectContext
    ) {
        guard let messageProtocolString = payload.messageProtocol else {
            WireLogger.eventProcessing.warn("message protocol is missing")
            return
        }

        guard let newMessageProtocol = MessageProtocol(rawValue: messageProtocolString) else {
            WireLogger.eventProcessing.warn("message protocol is invalid, got: \(messageProtocolString)")
            return
        }

        conversation.messageProtocol = newMessageProtocol
    }

    private func updateMessageProtocol(
        from payload: Payload.Conversation,
        for conversation: ZMConversation,
        in context: NSManagedObjectContext
    ) {
        guard let messageProtocolString = payload.messageProtocol else {
            WireLogger.eventProcessing.warn("message protocol is missing")
            return
        }

        guard let newMessageProtocol = MessageProtocol(rawValue: messageProtocolString) else {
            WireLogger.eventProcessing.warn("message protocol is invalid, got: \(messageProtocolString)")
            return
        }

        let sender = ZMUser.selfUser(in: context)

        switch conversation.messageProtocol {
        case .proteus:
            switch newMessageProtocol {
            case .proteus:
                break // no update, ignore
            case .mixed:
                conversation.appendMLSMigrationStartedSystemMessage(sender: sender, at: .now)
                conversation.messageProtocol = newMessageProtocol

            case .mls:
                let date = conversation.lastModifiedDate ?? .now
                conversation.appendMLSMigrationPotentialGapSystemMessage(sender: sender, at: date)
                conversation.messageProtocol = newMessageProtocol
            }

        case .mixed:
            switch newMessageProtocol {
            case .proteus:
                WireLogger.updateEvent
                    .warn(
                        "update message protocol from \(conversation.messageProtocol) to \(newMessageProtocol) is not allowed, ignore event!"
                    )

            case .mixed:
                break // no update, ignore
            case .mls:
                conversation.appendMLSMigrationFinalizedSystemMessage(sender: sender, at: .now)
                conversation.messageProtocol = newMessageProtocol
            }

        case .mls:
            switch newMessageProtocol {
            case .proteus, .mixed:
                WireLogger.updateEvent
                    .warn(
                        "update message protocol from '\(conversation.messageProtocol)' to '\(newMessageProtocol)' is not allowed, ignore event!"
                    )

            case .mls:
                break // no update, ignore
            }
        }
    }

    private func updateMLSStatus(
        from payload: Payload.Conversation,
        for conversation: ZMConversation,
        context: NSManagedObjectContext,
        source: Source
    ) async {
        guard DeveloperFlag.enableMLSSupport.isOn else { return }
        await mlsEventProcessor.updateConversationIfNeeded(
            conversation: conversation,
            fallbackGroupID: payload.mlsGroupID.map { .init(base64Encoded: $0) } ?? nil,
            context: context
        )
    }

    private func conversationType(
        for conversation: ZMConversation?,
        from type: ZMConversationType
    ) -> ZMConversationType {
        guard let conversation else {
            return type
        }

        // The backend can't distinguish between one-to-one and connection conversation
        // types across federated enviroments so check locally if it's a connection.
        if conversation.oneOnOneUser?.connection?.status == .sent {
            return .connection
        } else {
            return type
        }
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

// MARK: - Payload parsing utils

extension ZMConversation {
    fileprivate func fetchOrCreateRoleForConversation(name: String) -> Role {
        Role.fetchOrCreateRole(
            with: name,
            teamOrConversation: team != nil ? .team(team!) : .conversation(self),
            in: managedObjectContext!
        )
    }
}

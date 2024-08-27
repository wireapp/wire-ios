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

import WireDataModel
import CoreData
import WireAPI

final class ConversationLocalStore {
    
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Update
    
    func update(localConversation: ZMConversation, remoteConversation: WireAPI.Conversation) {
        
    }
    
    // MARK: - Conversations
    
    func createOrJoinSelfConversation(from conversation: ZMConversation) async throws {
        guard let context = conversation.managedObjectContext else {
            return
        }
        
        let (groupID, mlsService, hasRegisteredMLSClient) = await context.perform {
            (
                conversation.mlsGroupID,
                context.mlsService,
                ZMUser.selfUser(in: context).selfClient()?.hasRegisteredMLSClient == true
            )
        }
        
        guard let groupID, let mlsService, hasRegisteredMLSClient else {
            return
        }
        
        if await context.perform({ conversation.epoch <= 0 }) {
            let ciphersuite = try await mlsService.createSelfGroup(for: groupID)
            await context.perform { conversation.ciphersuite = ciphersuite }
        } else if try await !mlsService.conversationExists(groupID: groupID) {
            try await mlsService.joinGroup(with: groupID)
        }
    }
    
    func updateConversationStatus(
        from payload: WireAPI.Conversation,
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
                conversation.updateAccessStatus(accessModes: accessModes.map(\.rawValue), accessRoles: accessRoles.map(\.rawValue))
            } else if
                let accessRole = payload.legacyAccessRole,
                let legacyAccessRole = accessRole.toDomainModel() {
                let accessRoles = ConversationAccessRoleV2.fromLegacyAccessRole(legacyAccessRole)
                conversation.updateAccessStatus(accessModes: accessModes.map(\.rawValue), accessRoles: accessRoles.map(\.rawValue))
            }
        }
        
        if let messageTimer = payload.messageTimer {
            conversation.updateMessageDestructionTimeout(timeout: messageTimer)
        }
    }
    
    func updateConversationIfNeeded(
        conversation: ZMConversation,
        fallbackGroupID: MLSGroupID?
    ) async {
        
        let (messageProtocol, mlsGroupID, mlsService) = await context.perform { [self] in
            (
                conversation.messageProtocol,
                conversation.mlsGroupID,
                context.mlsService
            )
        }
        
        guard
            messageProtocol.isOne(of: .mls, .mixed),
            let mlsGroupID = mlsGroupID ?? fallbackGroupID else {
            return
        }
        
        await context.perform {
            if conversation.mlsGroupID == nil {
                conversation.mlsGroupID = mlsGroupID
            }
        }
        
        guard let mlsService else { return }
        
        let conversationExists: Bool
        
        do {
            conversationExists = try await mlsService.conversationExists(groupID: mlsGroupID)
        } catch {
            conversationExists = false
        }
        
        let newStatus: MLSGroupStatus = conversationExists ? .ready : .pendingJoin
        
        await context.perform { [self] in
            let previousStatus = conversation.mlsStatus
            
            conversation.mlsStatus = newStatus
            context.saveOrRollback()
        }
    }
    
    func updateConversationTimestamps(
        for conversation: ZMConversation,
        serverTimestamp: Date
    ) {
        /// If the lastModifiedDate is non-nil, e.g. restore from backup,
        /// do not update the lastModifiedDate.
        
        if conversation.lastModifiedDate == nil {
            conversation.updateLastModified(serverTimestamp)
        }
        
        conversation.updateServerModified(serverTimestamp)
    }
    
    // MARK: - Message protocols
    
    func assignMessageProtocol(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation
    ) {
        guard let newMessageProtocol = payload.messageProtocol else {
            return
        }
        
        conversation.messageProtocol = newMessageProtocol.toDomainModel()
    }
    
    func updateMessageProtocol(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation
    ) {
        
        guard let newMessageProtocol = payload.messageProtocol else {
            return
        }
        
        let sender = ZMUser.selfUser(in: context)
        
        switch conversation.messageProtocol {
        case .proteus:
            switch newMessageProtocol {
            case .proteus:
                break /// no update, ignore
            case .mixed:
                conversation.appendMLSMigrationStartedSystemMessage(sender: sender, at: .now)
                conversation.messageProtocol = newMessageProtocol.toDomainModel()
            case .mls:
                let date = conversation.lastModifiedDate ?? .now
                conversation.appendMLSMigrationPotentialGapSystemMessage(sender: sender, at: date)
                conversation.messageProtocol = newMessageProtocol.toDomainModel()
            }
            
        case .mixed:
            switch newMessageProtocol {
            case .proteus, .mixed:
                break /// no update, ignore
            case .mls:
                conversation.appendMLSMigrationFinalizedSystemMessage(sender: sender, at: .now)
                conversation.messageProtocol = newMessageProtocol.toDomainModel()
            }
            
        case .mls:
            switch newMessageProtocol {
            case .proteus, .mixed, .mls:
                break
            }
        }
    }
    
    func updateMLSStatus(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation,
        isSlowSync: Bool
    ) async {
        guard DeveloperFlag.enableMLSSupport.isOn else { return }
        
        await updateConversationIfNeeded(
            conversation: conversation,
            fallbackGroupID: payload.mlsGroupID.map( { .init(base64Encoded: $0) }) ?? nil
        )
    }
    
    
    // MARK: - Participants
    
    func fetchCreator(from payload: WireAPI.Conversation) -> ZMUser? {
        guard let userID = payload.creator else {
            return nil
        }
        
        /// We assume that the creator always belongs to the same domain as the conversation
        return ZMUser.fetchOrCreate(
            with: userID,
            domain: payload.qualifiedID?.domain,
            in: context
        )
    }
    
    func fetchUserAndRole(
        from payload: WireAPI.Conversation.Member,
        for conversation: ZMConversation
    ) -> (ZMUser, Role?)? {
        guard let userID = payload.id ?? payload.qualifiedID?.uuid else {
            return nil
        }
        
        let user = ZMUser.fetchOrCreate(
            with: userID,
            domain: payload.qualifiedID?.domain,
            in: context
        )
        
        func fetchOrCreateRoleForConversation(
            name: String,
            conversation: ZMConversation
        ) -> Role {
            Role.fetchOrCreateRole(
                with: name,
                teamOrConversation: conversation.team != nil ? .team(conversation.team!) : .conversation(conversation),
                in: context
            )
        }
        
        let role = payload.conversationRole.map {
            fetchOrCreateRoleForConversation(name: $0, conversation: conversation)
        }
        
        return (user, role)
    }
    
    func linkOneOnOneUserIfNeeded(for conversation: ZMConversation) {
        guard
            conversation.conversationType == .oneOnOne,
            let otherUser = conversation.localParticipantsExcludingSelf.first
        else {
            return
        }
        
        conversation.oneOnOneUser = otherUser
    }
    
    func updateMemberStatus(
        from payload: WireAPI.Conversation.Member,
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
    
    func updateMembers(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation
    ) {
        guard let members = payload.members else {
            return
        }
        
        let otherMembers = fetchOtherMembers(
            from: members,
            conversation: conversation
        )
        
        let selfUserRole = fetchUserAndRole(
            from: members.selfMember,
            for: conversation
        )?.1
        
        conversation.updateMembers(otherMembers, selfUserRole: selfUserRole)
    }
    
    func fetchOtherMembers(
        from payload: WireAPI.Conversation.Members,
        conversation: ZMConversation
    ) -> [(ZMUser, Role?)] {
        return payload.others.compactMap {
            fetchUserAndRole(
                from: $0,
                for: conversation
            )
        }
    }
    
    
    // MARK: - Other
    
    func updateAttributes(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation
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
            conversation.ciphersuite = ciphersuite.toDomainModel()
        }
    }
    
    func updateMetadata(
        from payload: WireAPI.Conversation,
        for conversation: ZMConversation
    ) {
        if let teamID = payload.teamID {
            conversation.updateTeam(identifier: teamID)
        }
        
        if let name = payload.name {
            conversation.userDefinedName = name
        }
        
        if let creator = fetchCreator(
            from: payload
        ) {
            conversation.creator = creator
        }
    }
    
}

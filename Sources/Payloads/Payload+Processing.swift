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

extension Payload.UserClient {

    func update(_ client: WireDataModel.UserClient) {
        client.needsToBeUpdatedFromBackend = false

        guard
            client.user?.isSelfUser == false,
            let deviceClass = deviceClass
        else { return }

        client.deviceClass = DeviceClass(rawValue: deviceClass)
    }

    func createOrUpdateClient(for user: ZMUser) -> WireDataModel.UserClient {
        let client = WireDataModel.UserClient.fetchUserClient(withRemoteId: id, forUser: user, createIfNeeded: true)!

        update(client)

        return client
    }
    
}

extension Array where Array.Element == Payload.UserClient {

    func updateClients(for user: ZMUser, selfClient: UserClient) {
        let clients: [UserClient] = map { $0.createOrUpdateClient(for: user) }

        // Remove clients that have not been included in the response
        let deletedClients = user.clients.subtracting(clients)
        deletedClients.forEach {
            $0.deleteClientAndEndSession()
        }

        // Mark new clients as missed and ignore them
        let newClients = Set(clients.filter({ $0.isInserted || !$0.hasSessionWithSelfClient }))
        selfClient.missesClients(newClients)
        selfClient.addNewClientsToIgnored(newClients)
        selfClient.updateSecurityLevelAfterDiscovering(newClients)
    }

}

// MARK: User Profile

extension Payload.UserProfile {

    /// Update a user entity with the data from a user profile payload.
    ///
    /// A user profile payload comes in two variants: full and delta, a full update is
    /// used to initially sync the entity with the server state. After this the entity
    /// can be updated with delta updates, which only contain the fields which have changed.
    ///
    /// - parameter user: User entity which on which the update should be applied.
    /// - parameter authoritative: If **true** the update will be applied as if the update
    ///                            is a full update, any missing fields will be removed from
    ///                            the entity.
    func updateUserProfile(for user: ZMUser, authoritative: Bool = true) {

        if let qualifiedID = qualifiedID {
            precondition(user.remoteIdentifier == nil || user.remoteIdentifier == qualifiedID.uuid)
            precondition(user.domain == nil || user.domain == qualifiedID.domain)

            user.remoteIdentifier = qualifiedID.uuid
            user.domain = qualifiedID.domain
        } else if let id = id {
            precondition(user.remoteIdentifier == nil || user.remoteIdentifier == id)

            user.remoteIdentifier = id
        }

        if let serviceID = serviceID {
            user.serviceIdentifier = serviceID.id.transportString()
            user.providerIdentifier = serviceID.provider.transportString()
        }

        if (updatedKeys.contains(.teamID) || authoritative) {
            user.teamIdentifier = teamID
            user.createOrDeleteMembershipIfBelongingToTeam()
        }

        if SSOID != nil || authoritative {
            user.usesCompanyLogin = SSOID != nil
        }

        if isDeleted == true {
            user.markAccountAsDeleted(at: Date())
        }

        if (name != nil || authoritative) && !user.isAccountDeleted {
            user.name = name
        }

        if (updatedKeys.contains(.phone) || authoritative) && !user.isAccountDeleted {
            user.phoneNumber = phone?.removingExtremeCombiningCharacters
        }
        
        if (updatedKeys.contains(.email) || authoritative) && !user.isAccountDeleted {
            user.emailAddress = email?.removingExtremeCombiningCharacters
        }

        if (handle != nil || authoritative) && !user.isAccountDeleted {
            user.handle = handle
        }

        if (managedBy != nil || authoritative) {
             user.managedBy = managedBy
        }

        if let accentColor = accentColor, let accentColorValue = ZMAccentColor(rawValue: Int16(accentColor)) {
            user.accentColorValue = accentColorValue
        }

        if let expiresAt = expiresAt {
            user.expiresAt = expiresAt
        }

        updateAssets(for: user, authoritative: authoritative)

        if authoritative {
            user.needsToBeUpdatedFromBackend = false
        }

        user.updatePotentialGapSystemMessagesIfNeeded()
    }

    func updateAssets(for user: ZMUser, authoritative: Bool = true) {
        let assetKeys = Set(arrayLiteral: ZMUser.previewProfileAssetIdentifierKey, ZMUser.completeProfileAssetIdentifierKey)
        guard !user.hasLocalModifications(forKeys: assetKeys) else {
            return
        }

        let validAssets = assets?.filter(\.key.isValidAssetID)
        let previewAssetKey = validAssets?.first(where: {$0.size == .preview }).map(\.key)
        let completeAssetKey = validAssets?.first(where: {$0.size == .complete }).map(\.key)

        if previewAssetKey != nil || authoritative {
            user.previewProfileAssetIdentifier = previewAssetKey
        }

        if completeAssetKey != nil || authoritative {
            user.completeProfileAssetIdentifier = completeAssetKey
        }
    }

}

extension Payload.UserProfiles {


    /// Update all user entities with the data from the user profiles.
    ///
    /// - parameter context: `NSManagedObjectContext` on which the update should be performed.
    func updateUserProfiles(in context: NSManagedObjectContext) {

        for userProfile in self {
            guard
                let id = userProfile.id ?? userProfile.qualifiedID?.uuid,
                let user = ZMUser.fetch(with: id, domain: userProfile.qualifiedID?.domain, in: context)
            else {
                continue
            }

            userProfile.updateUserProfile(for: user)
        }
    }

}

// MARK: - Prekeys

extension Payload.PrekeyByUserID {

    /// Establish new sessions using the prekeys retreived for each client.
    ///
    /// - parameter selfClient: The self user's client
    /// - parameter context: The `NSManagedObjectContext` on which the operation should be performed
    /// - parameter domain: originating domain of the clients.
    ///
    /// - returns `True` if there's more sessions which needs to be established.
    func establishSessions(with selfClient: UserClient,
                           context: NSManagedObjectContext,
                           domain: String? = nil) -> Bool {
        for (userID, prekeyByClientID) in self {
            for (clientID, prekey) in prekeyByClientID {
                guard
                    let userID = UUID(uuidString: userID),
                    let user = ZMUser.fetch(with: userID, domain: domain, in: context),
                    let missingClient = UserClient.fetchUserClient(withRemoteId: clientID,
                                                                   forUser: user,
                                                                   createIfNeeded: true)
                else {
                    continue
                }

                if let prekey = prekey {
                    missingClient.establishSessionAndUpdateMissingClients(prekey: prekey,
                                                                          selfClient: selfClient)
                } else {
                    missingClient.markClientAsInvalidAfterFailingToRetrievePrekey(selfClient: selfClient)
                }


            }
        }

        let hasMoreMissingClients = (selfClient.missingClients?.count ?? 0) > 0

        return hasMoreMissingClients
    }

}

extension Payload.PrekeyByQualifiedUserID {

    /// Establish new sessions using the prekeys retreived for each client.
    ///
    /// - parameter selfClient: The self user's client
    /// - parameter context: The `NSManagedObjectContext` on which the operation should be performed
    ///
    /// - returns `True` if there's more sessions which needs to be established.
    func establishSessions(with selfClient: UserClient, context: NSManagedObjectContext) -> Bool {
        for (domain, prekeyByUserID) in self {
            _ = prekeyByUserID.establishSessions(with: selfClient, context: context, domain: domain)
        }

        let hasMoreMissingClients = (selfClient.missingClients?.count ?? 0) > 0

        return hasMoreMissingClients
    }

}

// MARK: - UserClient

extension UserClient {

    /// Creates session and update missing clients and messages that depend on those clients
    fileprivate func establishSessionAndUpdateMissingClients(prekey: Payload.Prekey,
                                                             selfClient: UserClient) {

        let sessionCreated = selfClient.establishSessionWithClient(self,
                                                                   usingPreKey: prekey.key)

       // If the session creation failed, the client probably has corrupted prekeys,
       // we mark the client in order to send him a bogus message and not block all requests
       failedToEstablishSession = !sessionCreated
       clearMessagesMissingRecipient()
       selfClient.removeMissingClient(self)
   }

    fileprivate func markClientAsInvalidAfterFailingToRetrievePrekey(selfClient: UserClient) {
        failedToEstablishSession = true
        clearMessagesMissingRecipient()
        selfClient.removeMissingClient(self)
    }

    fileprivate func clearMessagesMissingRecipient() {
        messagesMissingRecipient.forEach {
            if let message = $0 as? ZMOTRMessage {
                message.doesNotMissRecipient(self)
            } else {
                mutableSetValue(forKey: "messagesMissingRecipient").remove($0)
            }
        }
    }

}

extension Payload.ClientListByQualifiedUserID {

    func fetchUsers(in context: NSManagedObjectContext) -> [ZMUser] {
        return flatMap { (domain, userClientsByUserID) in
            return userClientsByUserID.compactMap { (userID, _) -> ZMUser? in
                guard
                    let userID = UUID(uuidString: userID),
                    let user = ZMUser.fetch(with: userID, domain: domain, in: context)
                else {
                    return nil
                }

                return user
            }
        }
    }

    func fetchClients(in context: NSManagedObjectContext) -> [ZMUser: [UserClient]] {
        let userClientsByUserTuples = flatMap { (domain, userClientsByUserID) in
            return userClientsByUserID.compactMap { (userID, userClientIDs) -> [ZMUser: [UserClient]]? in
                guard
                    let userID = UUID(uuidString: userID),
                    let user = ZMUser.fetch(with: userID, domain: domain, in: context)
                else {
                    return nil
                }

                let userClients = user.clients.filter({
                    guard let clientID = $0.remoteIdentifier else { return false }
                    return userClientIDs.contains(clientID)
                })

                return [user: Array(userClients)]
            }
        }.flatMap { $0 }

        return Dictionary<ZMUser, [UserClient]>(userClientsByUserTuples, uniquingKeysWith: +)
    }

    func fetchOrCreateClients(in context: NSManagedObjectContext) -> [ZMUser: [UserClient]] {
        let userClientsByUserTuples = flatMap { (domain, userClientsByUserID) in
            return userClientsByUserID.compactMap { (userID, userClientIDs) -> [ZMUser: [UserClient]]? in
                guard
                    let userID = UUID(uuidString: userID)
                else {
                    return nil
                }

                let user = ZMUser.fetchOrCreate(with: userID, domain: domain, in: context)
                let userClients = userClientIDs.compactMap { (clientID) -> UserClient? in
                    guard
                        let userClient = UserClient.fetchUserClient(withRemoteId: clientID,
                                                                    forUser: user,
                                                                    createIfNeeded: true),
                        !userClient.hasSessionWithSelfClient
                    else {
                        return nil
                    }
                    return userClient
                }

                return [user: userClients]
            }
        }.flatMap { $0 }

        return Dictionary<ZMUser, [UserClient]>(userClientsByUserTuples, uniquingKeysWith: +)
    }

}

// MARK: - Message sending

extension Payload.MessageSendingStatus {

    /// Updates the reported client changes after an attempt to send the message
    ///
    /// - Parameter message: message for which the message sending status was created
    /// - Returns *True* if the message was missing clients in the original payload.
    ///
    /// If a message was missing clients we should attempt to send the message again
    /// after establishing sessions with the missing clients.
    ///
    func updateClientsChanges(for message: OTREntity) -> Bool {

        let deletedClients = deleted.fetchClients(in: message.context)
        for (_, deletedClients) in deletedClients {
            deletedClients.forEach { $0.deleteClientAndEndSession() }
        }

        let redundantUsers = redundant.fetchUsers(in: message.context)
        if !redundantUsers.isEmpty {
            // if the BE tells us that these users are not in the
            // conversation anymore, it means that we are out of sync
            // with the list of participants
            message.conversation?.needsToBeUpdatedFromBackend = true

            // The missing users might have been deleted so we need re-fetch their profiles
            // to verify if that's the case.
            redundantUsers.forEach { $0.needsToBeUpdatedFromBackend = true }

            message.detectedRedundantUsers(redundantUsers)
        }

        let missingClients = missing.fetchOrCreateClients(in: message.context)
        for (user, userClients) in missingClients {
            userClients.forEach({ $0.discoveredByMessage = message as? ZMOTRMessage })
            message.registersNewMissingClients(Set(userClients))
            message.conversation?.addParticipantAndSystemMessageIfMissing(user, date: nil)
        }

        return !missingClients.isEmpty
    }

}

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

    func updateOrCreate(in context: NSManagedObjectContext,
                        serverTimestamp: Date = Date(),
                        source: Source = .eventStream) {

        guard let rawType = type else { return }
        let conversationType = BackendConversationType.clientConversationType(rawValue: rawType)

        switch conversationType {
        case .group:
            updateOrCreateGroupConversation(in: context, serverTimestamp: serverTimestamp, source: source)
        case .`self`:
            updateOrCreateSelfConversation(in: context, serverTimestamp: serverTimestamp, source: source)
        case .connection, .oneOnOne:
            updateOrCreateOneToOneConversation(in: context, serverTimestamp: serverTimestamp, source: source)
        default:
            break
        }
    }

    func updateOrCreateOneToOneConversation(in context: NSManagedObjectContext,
                                            serverTimestamp: Date,
                                            source: Source) {

        guard let conversationID = id ?? qualifiedID?.uuid,
              let rawConversationType = type else {
            Logging.eventProcessing.error("Missing conversation or type in 1:1 conversation payload, aborting...")
            return
        }

        let conversationType = BackendConversationType.clientConversationType(rawValue: rawConversationType)

        guard let otherMember = members?.others.first, let otherUserID = otherMember.id ?? otherMember.qualifiedID?.uuid else {
            let conversation = ZMConversation.fetch(with: conversationID, domain: qualifiedID?.domain, in: context)
            conversation?.conversationType = conversationType
            conversation?.needsToBeUpdatedFromBackend = false
            return
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
        conversation.domain = qualifiedID?.domain
        conversation.conversationType = conversationType

        updateMetadata(for: conversation, context: context)
        updateMembers(for: conversation, context: context)
        updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
        updateConversationStatus(for: conversation)

        conversation.needsToBeUpdatedFromBackend = false
    }

    func updateOrCreateSelfConversation(in context: NSManagedObjectContext,
                                        serverTimestamp: Date,
                                        source: Source) {
        guard let conversationID = id ?? qualifiedID?.uuid else {
            Logging.eventProcessing.error("Missing conversationID in self conversation payload, aborting...")
            return
        }

        var created = false
        let conversation = ZMConversation.fetchOrCreate(with: conversationID,
                                                        domain: qualifiedID?.domain,
                                                        in: context,
                                                        created: &created)

        conversation.conversationType = .`self`
        conversation.domain = qualifiedID?.domain
        conversation.needsToBeUpdatedFromBackend = false

        updateMetadata(for: conversation, context: context)
        updateMembers(for: conversation, context: context)
        updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
    }

    func updateOrCreateGroupConversation(in context: NSManagedObjectContext,
                                         serverTimestamp: Date,
                                         source: Source) {
        guard let conversationID = id ?? qualifiedID?.uuid else {
            Logging.eventProcessing.error("Missing conversationID in group conversation payload, aborting...")
            return
        }

        var created = false
        let conversation = ZMConversation.fetchOrCreate(with: conversationID,
                                                        domain: qualifiedID?.domain,
                                                        in: context,
                                                        created: &created)

        conversation.conversationType = .group
        conversation.remoteIdentifier = conversationID
        conversation.domain = qualifiedID?.domain
        conversation.needsToBeUpdatedFromBackend = false

        updateMetadata(for: conversation, context: context)
        updateMembers(for: conversation, context: context)
        updateConversationTimestamps(for: conversation, serverTimestamp: serverTimestamp)
        updateConversationStatus(for: conversation)

        if created {
            // we just got a new conversation, we display new conversation header
            conversation.appendNewConversationSystemMessage(at: serverTimestamp,
                                                            users: conversation.localParticipants)

            if source == .slowSync {
                // Slow synced conversations should be considered read from the start
                conversation.lastReadServerTimeStamp = conversation.lastModifiedDate
            }
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

        if let access = access, let accessRole = accessRole {
            conversation.updateAccessStatus(accessModes: access, role: accessRole)
        }

        if let messageTimer = messageTimer {
            conversation.updateMessageDestructionTimeout(timeout: messageTimer)
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
        conversation.removeParticipantsAndUpdateConversationState(users: Set(removedUsers), initiatingUser: sender)
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

        conversation.updateAccessStatus(accessModes: data.access, role: data.accessRole)
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
        let timeout: MessageDestructionTimeout = .synced((.init(rawValue: timeoutValue)))
        let currentTimeout = conversation.messageDestructionTimeout ?? .synced(0)

        if let timestamp = timestamp, currentTimeout != timeout {
            conversation.appendMessageTimerUpdateMessage(fromUser: sender, timer: timeoutValue, timestamp: timestamp)
        }

        conversation.messageDestructionTimeout = timeout
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

        context.delete(conversation)
    }

}

extension Payload.ConversationEvent where T == Payload.UpdateConversationConnectionRequest {

    func process(in context: NSManagedObjectContext, originalEvent: ZMUpdateEvent) {
        // TODO jacob refactor to append method on conversation
        _ = ZMSystemMessage.createOrUpdate(from: originalEvent, in: context)
    }

}

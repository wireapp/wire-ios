//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "DuplicateEntity")

enum DuplicatedEntityRemoval {
    
    static func removeDuplicated(in moc: NSManagedObjectContext) {
        // will skip this during test unless on disk
        guard moc.persistentStoreCoordinator!.persistentStores.first!.type != NSInMemoryStoreType else { return }
        self.deleteDuplicatedClients(in: moc)
        moc.saveOrRollback()
        self.deleteDuplicatedUsers(in: moc)
        moc.saveOrRollback()
        self.deleteDuplicatedConversations(in: moc)
        moc.saveOrRollback()
    }
    
    static func deleteDuplicatedClients(in context: NSManagedObjectContext) {
        // Fetch clients having the same remote identifiers
        context.findDuplicated(by: #keyPath(UserClient.remoteIdentifier)).forEach { (remoteId: String?, clients: [UserClient]) in
            // Group clients having the same remote identifiers by user
            clients.filter { !($0.user?.isSelfUser ?? true) }.group(by: ZMUserClientUserKey).forEach { (user: ZMUser, clients: [UserClient]) in
                UserClient.merge(clients)
            }
        }
    }
    
    static func deleteDuplicatedUsers(in context: NSManagedObjectContext) {
        // Fetch users having the same remote identifiers
        context.findDuplicated(by: "remoteIdentifier_data").forEach { (remoteId: Data, users: [ZMUser]) in
            ZMUser.merge(users)
        }
    }
    
    static func deleteDuplicatedConversations(in context: NSManagedObjectContext) {
        // Fetch conversations having the same remote identifiers
        context.findDuplicated(by: "remoteIdentifier_data").forEach { (remoteId: Data, conversations: [ZMConversation]) in
            ZMConversation.merge(conversations)
        }
    }
    
}

extension UserClient {

    static func merge(_ clients: [UserClient]) {
        guard let firstClient = clients.first, let context = firstClient.managedObjectContext, clients.count > 1 else {
            return
        }
        let tail = clients.dropFirst()
        // Merge clients having the same remote identifier and same user

        tail.forEach {
            firstClient.merge(with: $0)
            context.delete($0)
        }
    }

    // Migration method for merging two duplicated @c UserClient entities
    func merge(with client: UserClient) {
        precondition(!(self.user?.isSelfUser ?? false), "Cannot merge self user's clients")
        precondition(client.remoteIdentifier == self.remoteIdentifier, "UserClient's remoteIdentifier should be equal to merge")
        precondition(client.user == self.user, "UserClient's Users should be equal to merge")
        
        let addedOrRemovedInSystemMessages = client.addedOrRemovedInSystemMessages
        let ignoredByClients = client.ignoredByClients
        let messagesMissingRecipient = client.messagesMissingRecipient
        let trustedByClients = client.trustedByClients
        
        self.addedOrRemovedInSystemMessages.formUnion(addedOrRemovedInSystemMessages)
        self.ignoredByClients.formUnion(ignoredByClients)
        self.messagesMissingRecipient.formUnion(messagesMissingRecipient)
        self.trustedByClients.formUnion(trustedByClients)
        
        if let missedByClient = client.missedByClient {
            self.missedByClient = missedByClient
        }
    }
}

extension ZMUser {

    @discardableResult static func merge(_ users: [ZMUser]) -> ZMUser? {
        guard let firstUser = users.first, let context = firstUser.managedObjectContext, users.count > 1 else {
            return users.first
        }

        let tail = users.dropFirst()
        // Merge users having the same remote identifier

        tail.forEach {
            firstUser.merge(with: $0)
            context.delete($0)
        }
        firstUser.needsToBeUpdatedFromBackend = true
        firstUser.lastServerSyncedActiveConversations.forEach { ($0 as? ZMConversation)?.needsToBeUpdatedFromBackend = true }
        return firstUser
    }

    // Migration method for merging two duplicated @c ZMUser entities
    func merge(with user: ZMUser) {
        precondition(user.remoteIdentifier == self.remoteIdentifier, "ZMUser's remoteIdentifier should be equal to merge")
        
        // NOTE:
        // we are not merging clients since they are re-created on demand
        // but we need to delete them so they would get recreated with correct relations
        user.clients.forEach {
            user.managedObjectContext?.delete($0)
        }
        self.connection = ZMManagedObject.firstNonNullAndDeleteSecond(self.connection, user.connection)
        self.addressBookEntry = ZMManagedObject.firstNonNullAndDeleteSecond(self.addressBookEntry, user.addressBookEntry)
        self.lastServerSyncedActiveConversations = self.lastServerSyncedActiveConversations.adding(orderedSet: user.lastServerSyncedActiveConversations)
        self.conversationsCreated = self.conversationsCreated.union(user.conversationsCreated)
        self.createdTeams = self.createdTeams.union(user.createdTeams)
        self.membership = ZMManagedObject.firstNonNullAndDeleteSecond(self.membership, user.membership)
        self.reactions = self.reactions.union(user.reactions)
        self.showingUserAdded = self.showingUserAdded.union(user.showingUserAdded)
        self.showingUserRemoved = self.showingUserRemoved.union(user.showingUserRemoved)
        self.systemMessages = self.systemMessages.union(user.systemMessages)
    }
}

extension ZMConversation {
    static func merge(_ conversations: [ZMConversation]) {
        // Group conversations having the same remote identifiers
        guard let firstConversation = conversations.first, let context = firstConversation.managedObjectContext, conversations.count > 1 else {
            return
        }

        let tail = conversations.dropFirst()
        // Merge conversations having the same remote identifier

        tail.forEach {
            firstConversation.merge(with: $0)
            if let connection = $0.connection {
                context.delete(connection)
            }
            context.delete($0)
        }
        firstConversation.needsToBeUpdatedFromBackend = true
    }

    // Migration method for merging two duplicated @c ZMConversation entities
    func merge(with conversation: ZMConversation) {
        precondition(conversation.remoteIdentifier == self.remoteIdentifier, "ZMConversation's remoteIdentifier should be equal to merge")
        
        // NOTE:
        // connection will be fixed when merging the users
        // creator will be fixed when merging the users
        let mutableHiddenMessages = self.mutableSetValue(forKey: ZMConversationHiddenMessagesKey)
        mutableHiddenMessages.union(conversation.hiddenMessages)
        self.mutableMessages.union(conversation.allMessages)
        self.team = self.team ?? conversation.team // I don't want to delete a team just in case it's needed
        self.connection = ZMManagedObject.firstNonNullAndDeleteSecond(self.connection, conversation.connection)
        self.mutableLastServerSyncedActiveParticipants.union(conversation.mutableLastServerSyncedActiveParticipants)
        
        zmLog.debug("Merged duplicate conversation \(self.remoteIdentifier?.transportString() ?? "N/A")")
        zmLog.debug("mutableLastServerSyncedActiveParticipants = \(self.mutableLastServerSyncedActiveParticipants.count)")
    }
}

extension ZMManagedObject {
    
    /// Returns the first of two objects that is not null. If both are
    /// not null, deletes the second one
    fileprivate static func firstNonNullAndDeleteSecond<Object: ZMManagedObject>(
        _ obj1: Object?,
        _ obj2: Object?) -> Object?
    {
        if let obj1 = obj1 {
            if let obj2 = obj2 {
                obj2.managedObjectContext?.delete(obj2)
            }
            return obj1
        }
        return obj2
    }
}

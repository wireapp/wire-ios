//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cryptobox


extension ZMConversation {

    /// Contains current security level of conversation.
    ///Client should check this property to properly annotate conversation.
    @NSManaged public var securityLevel : ZMConversationSecurityLevel

    /// Should be called when client is trusted.
    /// If the conversation became trusted, it will trigger UI notification and add system message for all devices verified
    @objc(increaseSecurityLevelIfNeededAfterTrustingClients:)
    public func increaseSecurityLevelIfNeededAfterTrusting(clients: Set<UserClient>) {
        guard self.increaseSecurityLevelIfNeeded() else { return }
        self.appendNewIsSecureSystemMessage(verified: clients)
        self.notifyOnUI(notification: ZMConversationIsVerifiedNotificationName)
    }

    /// Should be called when client is deleted.
    /// If the conversation became trusted, it will trigger UI notification and add system message for all devices verified
    @objc(increaseSecurityLevelIfNeededAfterRemovingClientForUser:)
    public func increaseSecurityLevelIfNeededAfterRemovingClient(for user: ZMUser) {
        guard self.increaseSecurityLevelIfNeeded() else { return }
        self.appendNewIsSecureSystemMessage(verified: Set<UserClient>(), for: Set(arrayLiteral: user))
        self.notifyOnUI(notification: ZMConversationIsVerifiedNotificationName)
    }

    /// Should be called when a new client is discovered
    @objc(decreaseSecurityLevelIfNeededAfterDiscoveringClients:causedByMessage:)
    public func decreaseSecurityLevelIfNeededAfterDiscovering(clients: Set<UserClient>, causedBy message: ZMOTRMessage?) {
        guard self.decreaseSecurityLevelIfNeeded() else { return }
        self.appendNewAddedClientSystemMessage(added: clients, before: message)
        if let message = message {
            if message.deliveryState != .sent && message.deliveryState != .delivered {
                self.expireAllPendingMessages(staringFrom: message)
            }
        }
    }

    /// Should be called when a client is ignored
    @objc(decreaseSecurityLevelIfNeededAfterIgnoringClients:)
    public func decreaseSecurityLevelIfNeededAfterIgnoring(clients: Set<UserClient>) {
        guard self.decreaseSecurityLevelIfNeeded() else { return }
        self.appendIgnoredClientsSystemMessage(ignored: clients)
    }

    /// Creates system message that says that you started using this device, if you were not registered on this device
    public func appendStartedUsingThisDeviceMessage() {
        guard ZMSystemMessage.fetchStartedUsingOnThisDeviceMessage(conversation: self) == nil else { return }
        let selfUser = ZMUser.selfUser(in: self.managedObjectContext!)
        guard let selfClient = selfUser.selfClient() else { return }
        _ = self.appendSystemMessage(type: .usingNewDevice,
                                     sender: selfUser,
                                     users: Set(arrayLiteral: selfUser),
                                     clients: Set(arrayLiteral: selfClient),
                                     timestamp: self.timestamp(after: self.messages.lastObject as? ZMMessage))
    }

    /// Creates a system message when a device has previously been used before, but was logged out due to invalid cookie and/ or invalidated client
    public func appendContinuedUsingThisDeviceMessage() {
        let selfUser = ZMUser.selfUser(in: self.managedObjectContext!)
        guard let selfClient = selfUser.selfClient() else { return }
        _ = self.appendSystemMessage(type: .reactivatedDevice,
                                 sender: selfUser,
                                 users: Set(arrayLiteral: selfUser),
                                 clients: Set(arrayLiteral: selfClient),
                                 timestamp: Date())
    }

    /// Creates a system message that inform that there are pontential lost messages, and that some users were added to the conversation
    public func appendNewPotentialGapSystemMessage(users: Set<ZMUser>?, timestamp: Date) {
        
        let (systemMessage, index) = self.appendSystemMessage(type: .potentialGap,
                                                              sender: ZMUser.selfUser(in: self.managedObjectContext!),
                                                              users: users,
                                                              clients: nil,
                                                              timestamp: timestamp)
        systemMessage.needsUpdatingUsers = true
        if index > 1,
            let previousMessage = self.messages[Int(index - 1)] as? ZMSystemMessage,
            previousMessage.systemMessageType == .potentialGap
        {
            // In case the message before the new system message was also a system message of
            // the type ZMSystemMessageTypePotentialGap, we delete the old one and update the
            // users property of the new one to use old users and calculate the added / removed users
            // from the time the previous one was added
            systemMessage.users = previousMessage.users
            self.managedObjectContext?.delete(previousMessage)
        }
    }

    /// Creates the message that warns user about the fact that decryption of incoming message is failed
    @objc(appendDecryptionFailedSystemMessageAtTime:sender:client:errorCode:)
    public func appendDecryptionFailedSystemMessage(at date: Date?, sender: ZMUser, client: UserClient?, errorCode: Int) {
        let type = (UInt32(errorCode) == CBOX_REMOTE_IDENTITY_CHANGED.rawValue) ? ZMSystemMessageType.decryptionFailed_RemoteIdentityChanged : ZMSystemMessageType.decryptionFailed
        let clients = client.flatMap { Set(arrayLiteral: $0) } ?? Set<UserClient>()
        let serverTimestamp = date ?? self.timestamp(after: self.messages.lastObject as? ZMMessage)
        _ = self.appendSystemMessage(type: type,
                                     sender: sender,
                                     users: nil,
                                     clients: clients,
                                     timestamp: serverTimestamp)
    }

    public func appendDeletedForEveryoneSystemMessage(at date: Date, sender: ZMUser) {
        _ = self.appendSystemMessage(type: .messageDeletedForEveryone,
                                     sender: sender,
                                     users: nil,
                                     clients: nil,
                                     timestamp: date)

    }
    
    /// Expire all pending message after the given message, including the given message
    private func expireAllPendingMessages(staringFrom startingMessage: ZMMessage) {
        self.messages.enumerateObjects(options: .reverse) { (msg, idx, stop) in
            guard let message = msg as? ZMMessage else { return }
            if message.deliveryState != .delivered && message.deliveryState != .sent {
                message.expire()
            }
            if startingMessage == message {
                stop.initialize(to: true)
            }
        }
    }
    
    /// Decrease the security level if some clients are now not trusted
    /// - returns: true if the security level was decreased
    private func decreaseSecurityLevelIfNeeded() -> Bool {
        guard !self.trusted && self.securityLevel == .secure else { return false }
        self.securityLevel = .secureWithIgnored
        return true
    }
    
    /// Increase the security level if all clients are now trusted
    /// - returns: true if the security level was increased
    private func increaseSecurityLevelIfNeeded() -> Bool {
        guard self.trusted && self.allParticipantsHaveClients else { return false }
        self.securityLevel = .secure
        return true
    }
}

// MARK: - HotFix
extension ZMConversation {

    /// Replaces the first NewClient systemMessage for the selfClient with a UsingNewDevice system message
    func replaceNewClientMessageIfNeededWithNewDeviceMesssage() {

        let selfUser = ZMUser.selfUser(in: self.managedObjectContext!)
        guard let selfClient = selfUser.selfClient() else { return }
        
        self.messages.enumerateObjects(options: .reverse) { (msg, idx, stop) in
            guard idx <= 2 else {
                stop.initialize(to: true)
                return
            }
            
            guard let systemMessage = msg as? ZMSystemMessage,
                systemMessage.systemMessageType == .newClient,
                systemMessage.sender == selfUser else {
                    return
            }
            
            if systemMessage.clients.contains(selfClient) {
                systemMessage.systemMessageType = .usingNewDevice
                stop.initialize(to: true)
            }
        }
    }
}

// MARK: - Appending system messages
extension ZMConversation {
    
    fileprivate func appendNewIsSecureSystemMessage(verified clients: Set<UserClient>) {
        let users = Set(clients.flatMap { $0.user })
        self.appendNewIsSecureSystemMessage(verified: clients, for: users)
    }
    
    fileprivate func appendNewIsSecureSystemMessage(verified clients: Set<UserClient>, for users: Set<ZMUser>) {
        guard !users.isEmpty,
            self.securityLevel != .secureWithIgnored else {
                return
            }
        _ = self.appendSystemMessage(type: .conversationIsSecure,
                                 sender: ZMUser.selfUser(in: self.managedObjectContext!),
                                 users: users,
                                 clients: clients,
                                 timestamp: self.timestamp(after: self.messages.lastObject as? ZMMessage))
        
    }
    
    fileprivate func appendNewAddedClientSystemMessage(added clients: Set<UserClient>, before message: ZMOTRMessage?) {
        guard !clients.isEmpty else { return }
        let users = Set(clients.flatMap { $0.user })
        let timestamp : Date?
        if let message = message, message.conversation == self {
            timestamp = self.timestamp(after: self.messages.lastObject as? ZMMessage)
        } else {
            timestamp = self.timestamp(before: message)
        }
        _ = self.appendSystemMessage(type: .newClient,
                                     sender: ZMUser.selfUser(in: self.managedObjectContext!),
                                     users: users,
                                     clients: clients,
                                     timestamp: timestamp)
    }
    
    fileprivate func appendIgnoredClientsSystemMessage(ignored clients: Set<UserClient>) {
        guard !clients.isEmpty else { return }
        let users = Set(clients.flatMap { $0.user })
        _ = self.appendSystemMessage(type: .ignoredClient,
                                     sender: ZMUser.selfUser(in: self.managedObjectContext!),
                                     users: users,
                                     clients: clients,
                                     timestamp: self.timestamp(after: self.messages.lastObject as? ZMMessage))
    }
    
    fileprivate func appendSystemMessage(type: ZMSystemMessageType,
                                         sender: ZMUser,
                                         users: Set<ZMUser>?,
                                         clients: Set<UserClient>?,
                                         timestamp: Date?
                                         ) -> (message: ZMSystemMessage, insertionIndex: UInt) {
        let systemMessage = ZMSystemMessage.insertNewObject(in: self.managedObjectContext!)
        systemMessage.systemMessageType = type
        systemMessage.sender = sender
        systemMessage.isEncrypted = false
        systemMessage.isPlainText = true
        systemMessage.users = users ?? Set()
        systemMessage.clients = clients ?? Set()
        systemMessage.nonce = UUID()
        systemMessage.serverTimestamp = timestamp ?? Date()
        
        let index = self.sortedAppendMessage(systemMessage)
        systemMessage.visibleInConversation = self
        return (message: systemMessage, insertionIndex: index)
    }
    

    
    /// Returns a timestamp that is shortly (as short as possible) before the given message,
    /// or the last modified date if the message is nil
    fileprivate func timestamp(before: ZMMessage?) -> Date? {
        guard let timestamp = before?.serverTimestamp ?? self.lastModifiedDate else { return nil }
        // this feels a bit hackish, but should work. If two messages are less than 1 milliseconds apart
        // then in this case one of them will be out of order
        return timestamp.addingTimeInterval(-0.001)
    }
    
    /// Returns a timestamp that is shortly (as short as possible) after the given message,
    /// or the last modified date if the message is nil
    fileprivate func timestamp(after: ZMMessage?) -> Date? {
        guard let timestamp = after?.serverTimestamp ?? self.lastModifiedDate else { return nil }
        // this feels a bit hackish, but should work. If two messages are less than 1 milliseconds apart
        // then in this case one of them will be out of order
        return timestamp.addingTimeInterval(0.001)
    }

}

// MARK: - Conversation participants status
extension ZMConversation {
    
    /// Returns true if all participants are connected to the self user and all participants are trusted
    public var trusted : Bool {
        let hasOnlyTrustedUsers = (self.activeParticipants.array as! [ZMUser]).first { !$0.trusted() } == nil
        return hasOnlyTrustedUsers && !self.containsUnconnectedParticipant
    }
    
    fileprivate var containsUnconnectedParticipant : Bool {
        return (self.otherActiveParticipants.array as! [ZMUser]).first { !$0.isConnected } != nil
    }
    
    fileprivate var allParticipantsHaveClients : Bool {
        return (self.activeParticipants.array as! [ZMUser]).first { $0.clients.count == 0 } == nil
    }
    
    /// If true the conversation might still be trusted / ignored
    public var hasUntrustedClients : Bool {
        return (self.activeParticipants.array as! [ZMUser]).first { $0.untrusted() } != nil
    }
}

// MARK: - Notifications
extension ZMConversation {
    
    func notifyOnUI(notification: String) {
        self.managedObjectContext?.zm_userInterface .performGroupedBlock {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: notification), object: self)
        }
    }
}

extension ZMSystemMessage {

    /// Fetch the first system message in the conversation about "started to use this device"
    fileprivate static func fetchStartedUsingOnThisDeviceMessage(conversation: ZMConversation) -> ZMSystemMessage? {
        let conversationPredicate = NSPredicate(format: "%K == %@ OR %K == %@", ZMMessageConversationKey, conversation, ZMMessageHiddenInConversationKey, conversation)
        let newClientPredicate = NSPredicate(format: "%K == %d", ZMMessageSystemMessageTypeKey, ZMSystemMessageType.newClient.rawValue)
        let containsSelfClient = NSPredicate(format: "ANY %K == %@", ZMMessageSystemMessageClientsKey, ZMUser.selfUser(in: conversation.managedObjectContext!).selfClient()!)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [conversationPredicate, newClientPredicate, containsSelfClient])
        
        let fetchRequest = ZMSystemMessage.sortedFetchRequest(with: compound)!
        let result = conversation.managedObjectContext!.executeFetchRequestOrAssert(fetchRequest)!
        return result.first as? ZMSystemMessage
    }
}


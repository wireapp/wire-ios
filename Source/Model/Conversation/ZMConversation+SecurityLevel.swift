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
import WireCryptobox

@objc public enum ZMConversationLegalHoldStatus: Int16 {
    case disabled = 0
    case pendingApproval = 1
    case enabled = 2

    public var denotesEnabledComplianceDevice: Bool {
        switch self {
        case .pendingApproval, .enabled:
            return true
        case .disabled:
            return false
        }
    }
}

extension ZMConversation {

    /// Contains current security level of conversation.
    /// Client should check this property to properly annotate conversation.
    @NSManaged public internal(set) var securityLevel: ZMConversationSecurityLevel

    @NSManaged private var primitiveLegalHoldStatus: NSNumber

    /// Whether the conversation is under legal hold.
    @objc public internal(set) var legalHoldStatus: ZMConversationLegalHoldStatus {
        get {
            willAccessValue(forKey: #keyPath(legalHoldStatus))
            defer { didAccessValue(forKey: #keyPath(legalHoldStatus)) }

            if let status = ZMConversationLegalHoldStatus(rawValue: primitiveLegalHoldStatus.int16Value) {
                return status
            } else {
                return .disabled
            }
        }
        set {
            willChangeValue(forKey: #keyPath(legalHoldStatus))
            primitiveLegalHoldStatus = NSNumber(value: newValue.rawValue)
            didChangeValue(forKey: #keyPath(legalHoldStatus))
        }
    }

    /// Whether the conversation is under legal hold.
    @objc public var isUnderLegalHold: Bool {
        return legalHoldStatus.denotesEnabledComplianceDevice
    }

    /// Whether the self user can send messages in this conversation.
    @objc public var selfUserCanSendMessages: Bool {
        return !isReadOnly && securityLevel != .secureWithIgnored && legalHoldStatus != .pendingApproval
    }

    // MARK: - Events

    /// Should be called when a message is received.
    /// If the legal hold status hint inside the received message is different than the local status,
    /// we update the local version to match the remote one.
    @objc(updateSecurityLevelIfNeededAfterReceiving:timestamp:)
    public func updateSecurityLevelIfNeededAfterReceiving(message: ZMGenericMessage, timestamp: Date) {
        updateLegalHoldIfNeededWithHint(from: message, timestamp: timestamp)
    }

    /// Should be called when client is trusted.
    /// If the conversation became trusted, it will trigger UI notification and add system message for all devices verified
    @objc(increaseSecurityLevelIfNeededAfterTrustingClients:)
    public func increaseSecurityLevelIfNeededAfterTrusting(clients: Set<UserClient>) {
         applySecurityChanges(cause: .verifiedClients(clients))
    }

    /// Should be called when client is deleted.
    /// If the conversation became trusted, it will trigger UI notification and add system message for all devices verified
    @objc(increaseSecurityLevelIfNeededAfterRemovingClientForUsers:)
    public func increaseSecurityLevelIfNeededAfterRemoving(clients: [ZMUser: Set<UserClient>]) {
        applySecurityChanges(cause: .removedClients(clients))
    }

    /// Should be called when a user is deleted.
    /// If the conversation became trusted, it will trigger UI notification and add system message for all devices verified
    @objc(increaseSecurityLevelIfNeededAfterRemovingUsers:)
    public func increaseSecurityLevelIfNeededAfterRemoving(users: Set<ZMUser>) {
        applySecurityChanges(cause: .removedUsers(users))
    }

    /// Should be called when a new client is discovered
    @objc(decreaseSecurityLevelIfNeededAfterDiscoveringClients:causedByMessage:)
    public func decreaseSecurityLevelIfNeededAfterDiscovering(clients: Set<UserClient>, causedBy message: ZMOTRMessage?) {
        applySecurityChanges(cause: .addedClients(clients, source: message))
    }
    
    /// Should be called when a new user is added to the conversation
    @objc(decreaseSecurityLevelIfNeededAfterDiscoveringClients:causedByAddedUsers:)
    public func decreaseSecurityLevelIfNeededAfterDiscovering(clients: Set<UserClient>, causedBy users: Set<ZMUser>) {
        applySecurityChanges(cause: .addedUsers(users))
    }

    /// Should be called when a client is ignored
    @objc(decreaseSecurityLevelIfNeededAfterIgnoringClients:)
    public func decreaseSecurityLevelIfNeededAfterIgnoring(clients: Set<UserClient>) {
        applySecurityChanges(cause: .ignoredClients(clients))
    }

    /// Applies the security changes for the set of users.
    private func applySecurityChanges(cause: SecurityChangeCause) {
        updateLegalHoldState(cause: cause)
        updateSecurityLevel(cause: cause)
    }

    private func updateLegalHoldState(cause: SecurityChangeCause) {
        switch cause {
        case .addedUsers, .addedClients:
            enableLegalHoldIfNeeded(cause: cause)

        case .removedClients, .removedUsers:
            disableLegalHoldIfNeeded(cause: cause)

        case .verifiedClients, .ignoredClients:
            // no-op: verification does not impact legal hold because no clients are added or removed
            break
        }
    }

    private func updateSecurityLevel(cause: SecurityChangeCause) {
        switch cause {
        case .addedUsers, .addedClients, .ignoredClients:
            degradeSecurityLevelIfNeeded(for: cause)

        case .removedUsers, .removedClients, .verifiedClients:
            increaseSecurityLevelIfNeeded(for: cause)
        }
    }

    private func increaseSecurityLevelIfNeeded(for cause: SecurityChangeCause) {
        guard securityLevel != .secure && allUsersTrusted && allParticipantsHaveClients else {
            return
        }

        securityLevel = .secure
        appendNewIsSecureSystemMessage(cause: cause)
        notifyOnUI(name: ZMConversation.isVerifiedNotificationName)
    }

    private func degradeSecurityLevelIfNeeded(for cause: SecurityChangeCause) {
        guard securityLevel == .secure && !allUsersTrusted else {
            return
        }

        securityLevel = .secureWithIgnored

        switch cause {
        case .addedClients, .addedUsers:
            appendNewAddedClientSystemMessage(cause: cause)
            expireAllPendingMessagesBecauseOfSecurityLevelDegradation()
        case .ignoredClients(let clients):
            appendIgnoredClientsSystemMessage(ignored: clients)
        default:
            break
        }
    }

    /// Check whether the conversation became under legal hold and disable it if needed.
    private func enableLegalHoldIfNeeded(cause: SecurityChangeCause) {
        guard !legalHoldStatus.denotesEnabledComplianceDevice && activeParticipants.any(\.isUnderLegalHold) else {
            return
        }

        legalHoldStatus = .pendingApproval
        appendLegalHoldEnabledSystemMessageForConversation(cause: cause)
        expireAllPendingMessagesBecauseOfSecurityLevelDegradation()
    }

    /// Check whether the conversation is still under legal hold and disable it if needed.
    private func disableLegalHoldIfNeeded(cause: SecurityChangeCause) {
        guard legalHoldStatus.denotesEnabledComplianceDevice && !activeParticipants.any(\.isUnderLegalHold) else {
            return
        }

        legalHoldStatus = .disabled
        appendLegalHoldDisabledSystemMessageForConversation()
    }

    /// Update the legal hold status based on the hint of a message.
    private func updateLegalHoldIfNeededWithHint(from message: ZMGenericMessage, timestamp: Date) {
        guard let statusHint = message.content?.legalHoldStatusHint else {
            return
        }

        switch statusHint {
        case .ENABLED where !legalHoldStatus.denotesEnabledComplianceDevice:
            legalHoldStatus = .pendingApproval
            appendLegalHoldEnabledSystemMessageForConversationAfterReceivingMessage(at: timestamp)
            expireAllPendingMessagesBecauseOfSecurityLevelDegradation()
        case .DISABLED where legalHoldStatus.denotesEnabledComplianceDevice:
            legalHoldStatus = .disabled
            appendLegalHoldDisabledSystemMessageForConversationAfterReceivingMessage(at: timestamp)
        default:
            break
        }
    }

    // MARK: - Messages

    /// Creates system message that says that you started using this device, if you were not registered on this device
    @objc public func appendStartedUsingThisDeviceMessage() {
        guard ZMSystemMessage.fetchStartedUsingOnThisDeviceMessage(conversation: self) == nil else { return }
        let selfUser = ZMUser.selfUser(in: self.managedObjectContext!)
        guard let selfClient = selfUser.selfClient() else { return }
        self.appendSystemMessage(type: .usingNewDevice,
                                 sender: selfUser,
                                 users: Set(arrayLiteral: selfUser),
                                 clients: Set(arrayLiteral: selfClient),
                                 timestamp: timestampAfterLastMessage())
    }

    /// Creates a system message when a device has previously been used before, but was logged out due to invalid cookie and/ or invalidated client
    @objc public func appendContinuedUsingThisDeviceMessage() {
        let selfUser = ZMUser.selfUser(in: self.managedObjectContext!)
        guard let selfClient = selfUser.selfClient() else { return }
        self.appendSystemMessage(type: .reactivatedDevice,
                                 sender: selfUser,
                                 users: Set(arrayLiteral: selfUser),
                                 clients: Set(arrayLiteral: selfClient),
                                 timestamp: Date())
    }

    /// Creates a system message that inform that there are pontential lost messages, and that some users were added to the conversation
    @objc public func appendNewPotentialGapSystemMessage(users: Set<ZMUser>?, timestamp: Date) {
        
        let previousLastMessage = lastMessage
        let systemMessage = self.appendSystemMessage(type: .potentialGap,
                                                     sender: ZMUser.selfUser(in: self.managedObjectContext!),
                                                     users: users,
                                                     clients: nil,
                                                     timestamp: timestamp)
        systemMessage.needsUpdatingUsers = true
        
        if let previousLastMessage = previousLastMessage as? ZMSystemMessage,
            previousLastMessage.systemMessageType == .potentialGap,
            previousLastMessage.serverTimestamp < timestamp {
            // In case the message before the new system message was also a system message of
            // the type ZMSystemMessageTypePotentialGap, we delete the old one and update the
            // users property of the new one to use old users and calculate the added / removed users
            // from the time the previous one was added
            systemMessage.users = previousLastMessage.users
            self.managedObjectContext?.delete(previousLastMessage)
        }
    }

    /// Creates the message that warns user about the fact that decryption of incoming message is failed
    @objc(appendDecryptionFailedSystemMessageAtTime:sender:client:errorCode:)
    public func appendDecryptionFailedSystemMessage(at date: Date?, sender: ZMUser, client: UserClient?, errorCode: Int) {
        let type = (UInt32(errorCode) == CBOX_REMOTE_IDENTITY_CHANGED.rawValue) ? ZMSystemMessageType.decryptionFailed_RemoteIdentityChanged : ZMSystemMessageType.decryptionFailed
        let clients = client.flatMap { Set(arrayLiteral: $0) } ?? Set<UserClient>()
        let serverTimestamp = date ?? timestampAfterLastMessage()
        self.appendSystemMessage(type: type,
                                 sender: sender,
                                 users: nil,
                                 clients: clients,
                                 timestamp: serverTimestamp)
    }

    /// Adds the user to the list of participants if not already present and inserts a .participantsAdded system message
    @objc(addParticipantIfMissing:date:)
    public func addParticipantIfMissing(_ user: ZMUser, at date: Date = Date()) {
        guard !activeParticipants.contains(user) else { return }
        
        switch conversationType {
        case .group:
            appendSystemMessage(type: .participantsAdded, sender: user, users: Set(arrayLiteral: user), clients: nil, timestamp: date)
            internalAddParticipants(Set(arrayLiteral: user))
        case .oneOnOne, .connection:
            if user.connection == nil {
                user.connection = connection ?? ZMConnection.insertNewObject(in: managedObjectContext!)
            } else if connection == nil {
                connection = user.connection
            }
            
            user.connection?.needsToBeUpdatedFromBackend = true
        default:
            break
        }
        
        // A missing user indicate that we are out of sync with the BE so we'll re-sync the conversation
        needsToBeUpdatedFromBackend = true
    }

    private func appendLegalHoldEnabledSystemMessageForConversation(cause: SecurityChangeCause) {
        var timestamp : Date?
        
        if case .addedClients(_, let message) = cause, message?.conversation == self {
            timestamp = self.timestamp(before: message)
        }
        
        appendSystemMessage(type: .legalHoldEnabled,
                            sender: ZMUser.selfUser(in: self.managedObjectContext!),
                            users: nil,
                            clients: nil,
                            timestamp: timestamp ?? timestampAfterLastMessage())
    }

    private func appendLegalHoldEnabledSystemMessageForConversationAfterReceivingMessage(at timestamp: Date) {
        appendSystemMessage(type: .legalHoldEnabled,
                            sender: ZMUser.selfUser(in: self.managedObjectContext!),
                            users: nil,
                            clients: nil,
                            timestamp: timestamp.previousNearestTimestamp)
    }

    private func appendLegalHoldDisabledSystemMessageForConversation() {
        appendSystemMessage(type: .legalHoldDisabled,
                            sender: ZMUser.selfUser(in: self.managedObjectContext!),
                            users: nil,
                            clients: nil,
                            timestamp: timestampAfterLastMessage())
    }

    private func appendLegalHoldDisabledSystemMessageForConversationAfterReceivingMessage(at timestamp: Date) {
        appendSystemMessage(type: .legalHoldDisabled,
                            sender: ZMUser.selfUser(in: self.managedObjectContext!),
                            users: nil,
                            clients: nil,
                            timestamp: timestamp.previousNearestTimestamp)
    }

}

// MARK: - Messages resend/expiration
extension ZMConversation {

    private func acknowledgePrivacyChanges() {
        precondition(managedObjectContext?.zm_isUserInterfaceContext == true)

        // Downgrade the conversation to be unverified
        if securityLevel == .secureWithIgnored {
            securityLevel = .notSecure
        }

        // Accept legal hold
        if legalHoldStatus == .pendingApproval {
            legalHoldStatus = .enabled
        }

        managedObjectContext?.saveOrRollback()
    }

    private func resendPendingMessagesAfterPrivacyChanges() {
        enumerateReverseMessagesThatCausedDegradationUntilFirstSystemMessageOnSyncContext {
            $0.causedSecurityLevelDegradation = false
            $0.resend()
        }
    }

    private func discardPendingMessagesAfterPrivacyChanges() {
        guard let syncMOC = managedObjectContext?.zm_sync else { return }
        syncMOC.performGroupedBlock {
            guard let conversation = (try? syncMOC.existingObject(with: self.objectID)) as? ZMConversation else { return }
            conversation.clearMessagesThatCausedSecurityLevelDegradation()
            syncMOC.saveOrRollback()
        }
    }

    /// Accepts the privacy changes (legal hold and/or degradation) and resend the pending messages.
    @objc(acknowledgePrivacyWarningWithResendIntent:) public func acknowledgePrivacyWarning(withResendIntent shouldResendMessages: Bool) {
        acknowledgePrivacyChanges()

        if shouldResendMessages {
            resendPendingMessagesAfterPrivacyChanges()
        } else {
            discardPendingMessagesAfterPrivacyChanges()
        }
    }

    /// Enumerates all messages from newest to oldest and apply a block to all ZMOTRMessage encountered, 
    /// halting the enumeration when a system message for security level degradation is found.
    /// This is executed asychronously on the sync context
    private func enumerateReverseMessagesThatCausedDegradationUntilFirstSystemMessageOnSyncContext(block: @escaping (ZMOTRMessage)->()) {
        guard let syncMOC = self.managedObjectContext?.zm_sync else { return }
        syncMOC.performGroupedBlock {
            guard let conversation = (try? syncMOC.existingObject(with: self.objectID)) as? ZMConversation else { return }
            conversation.messagesThatCausedSecurityLevelDegradation.forEach(block)
            syncMOC.saveOrRollback()
        }
    }
    
    /// Expire all pending messages
    fileprivate func expireAllPendingMessagesBecauseOfSecurityLevelDegradation() {
        for message in undeliveredMessages {
            if let clientMessage = message as? ZMClientMessage, let genericMessage = clientMessage.genericMessage, genericMessage.hasConfirmation() {
                // Delivery receipt: just expire it
                message.expire()
            } else {
                // All other messages: expire and mark that it caused security degradation
                message.expire()
                message.causedSecurityLevelDegradation = true
            }
        }
    }
    
    fileprivate var undeliveredMessages: [ZMOTRMessage] {
        guard let managedObjectContext = managedObjectContext else { return [] }
        
        let timeoutLimit = Date().addingTimeInterval(-ZMMessage.defaultExpirationTime())
        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        let undeliveredMessagesPredicate = NSPredicate(format: "%K == %@ AND %K == %@ AND %K == NO AND %K > %@",
                                                       ZMMessageConversationKey, self,
                                                       ZMMessageSenderKey, selfUser,
                                                       DeliveredKey,
                                                       ZMMessageServerTimestampKey, timeoutLimit as NSDate)
        
        let fetchRequest = NSFetchRequest<ZMClientMessage>(entityName: ZMClientMessage.entityName())
        fetchRequest.predicate = undeliveredMessagesPredicate
        
        let assetFetchRequest = NSFetchRequest<ZMAssetClientMessage>(entityName: ZMAssetClientMessage.entityName())
        assetFetchRequest.predicate = undeliveredMessagesPredicate
        
        var undeliveredMessages: [ZMOTRMessage] = []
        undeliveredMessages += managedObjectContext.fetchOrAssert(request: fetchRequest) as [ZMOTRMessage]
        undeliveredMessages += managedObjectContext.fetchOrAssert(request: assetFetchRequest) as [ZMOTRMessage]
        
        return undeliveredMessages
    }
    
}

// MARK: - HotFix
extension ZMConversation {

    /// Replaces the first NewClient systemMessage for the selfClient with a UsingNewDevice system message
    @objc public func replaceNewClientMessageIfNeededWithNewDeviceMesssage() {

        let selfUser = ZMUser.selfUser(in: self.managedObjectContext!)
        guard let selfClient = selfUser.selfClient() else { return }
        
        NSOrderedSet(array: lastMessages()).enumerateObjects() { (msg, idx, stop) in
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
    
    fileprivate func appendNewIsSecureSystemMessage(cause: SecurityChangeCause) {
        switch cause {
        case .removedUsers(let users):
            appendNewIsSecureSystemMessage(verified: [], for: users)
        case .verifiedClients(let userClients):
            let users = Set(userClients.compactMap { $0.user })
            appendNewIsSecureSystemMessage(verified: userClients, for: users)
        case .removedClients(let userClients):
            let users = Set(userClients.keys)
            let clients = Set(userClients.values.flatMap { $0 })
            appendNewIsSecureSystemMessage(verified: clients, for: users)
        default:
            // no-op: the conversation is not secure in other cases
            return
        }
    }
    
    fileprivate func appendNewIsSecureSystemMessage(verified clients: Set<UserClient>, for users: Set<ZMUser>) {
        guard !users.isEmpty, securityLevel != .secureWithIgnored else {
            return
        }

        appendSystemMessage(type: .conversationIsSecure,
                            sender: ZMUser.selfUser(in: self.managedObjectContext!),
                            users: users,
                            clients: clients,
                            timestamp: timestampAfterLastMessage())
    }
    
    fileprivate enum SecurityChangeCause {
        case addedClients(Set<UserClient>, source: ZMOTRMessage?)
        case addedUsers(Set<ZMUser>)
        case removedUsers(Set<ZMUser>)
        case verifiedClients(Set<UserClient>)
        case removedClients([ZMUser: Set<UserClient>])
        case ignoredClients(Set<UserClient>)
    }
    
    fileprivate func appendNewAddedClientSystemMessage(cause: SecurityChangeCause) {
        var timestamp : Date?
        var affectedUsers: Set<ZMUser> = []
        var addedUsers: Set<ZMUser> = []
        var addedClients: Set<UserClient> = []
        
        switch cause {
        case .addedUsers(let users):
            affectedUsers = users
            addedUsers = users
        case .addedClients(let clients, let message):
            affectedUsers = Set(clients.compactMap(\.user))
            addedClients = clients
            if let message = message, message.conversation == self {
                timestamp = self.timestamp(before: message)
            } else {
                timestamp = clients.compactMap(\.discoveryDate).first?.previousNearestTimestamp
            }
        default:
            // unsupported cause
            return
        }
        
        guard !addedClients.isEmpty || !addedUsers.isEmpty else { return }
        
        self.appendSystemMessage(type: .newClient,
                                 sender: ZMUser.selfUser(in: self.managedObjectContext!),
                                 users: affectedUsers,
                                 addedUsers: addedUsers,
                                 clients: addedClients,
                                 timestamp: timestamp ?? timestampAfterLastMessage())
    }
    
    fileprivate func appendIgnoredClientsSystemMessage(ignored clients: Set<UserClient>) {
        guard !clients.isEmpty else { return }
        let users = Set(clients.compactMap { $0.user })
        self.appendSystemMessage(type: .ignoredClient,
                                 sender: ZMUser.selfUser(in: self.managedObjectContext!),
                                 users: users,
                                 clients: clients,
                                 timestamp: timestampAfterLastMessage())
    }
    
    @discardableResult
    func appendSystemMessage(type: ZMSystemMessageType,
                                         sender: ZMUser,
                                         users: Set<ZMUser>?,
                                         addedUsers: Set<ZMUser> = Set(),
                                         clients: Set<UserClient>?,
                                         timestamp: Date,
                                         duration: TimeInterval? = nil,
                                         messageTimer: Double? = nil,
                                         relevantForStatus: Bool = true) -> ZMSystemMessage {
        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: managedObjectContext!)
        systemMessage.systemMessageType = type
        systemMessage.sender = sender
        systemMessage.users = users ?? Set()
        systemMessage.addedUsers = addedUsers
        systemMessage.clients = clients ?? Set()
        systemMessage.serverTimestamp = timestamp
        if let duration = duration {
            systemMessage.duration = duration
        }
        
        if let messageTimer = messageTimer {
            systemMessage.messageTimer = NSNumber(value: messageTimer)
        }
        
        systemMessage.relevantForConversationStatus = relevantForStatus
        
        self.append(systemMessage)
        
        return systemMessage
    }
    
    /// Returns a timestamp that is shortly (as short as possible) before the given message,
    /// or the last modified date if the message is nil
    fileprivate func timestamp(before: ZMMessage?) -> Date? {
        guard let timestamp = before?.serverTimestamp ?? self.lastModifiedDate else { return nil }
        return timestamp.previousNearestTimestamp
    }
    
    /// Returns a timestamp that is shortly (as short as possible) after the given message,
    /// or the last modified date if the message is nil
    fileprivate func timestamp(after: ZMMessage?) -> Date? {
        guard let timestamp = after?.serverTimestamp ?? self.lastModifiedDate else { return nil }
        return timestamp.nextNearestTimestamp
    }
    
    // Returns a timestamp that is shortly (as short as possible) after the last message in the conversation,
    // or current time if there's no last message
    fileprivate func timestampAfterLastMessage() -> Date {
        return timestamp(after: lastMessage) ?? Date()
    }
}

// MARK: - Conversation participants status
extension ZMConversation {
    
    /// Returns true if all participants are connected to the self user and all participants are trusted
    @objc public var allUsersTrusted : Bool {
        guard self.lastServerSyncedActiveParticipants.count > 0, self.isSelfAnActiveMember else { return false }
        let hasOnlyTrustedUsers = self.activeParticipants.first { !$0.trusted() } == nil
        return hasOnlyTrustedUsers && !self.containsUnconnectedOrExternalParticipant
    }
    
    fileprivate var containsUnconnectedOrExternalParticipant : Bool {
        guard let managedObjectContext = self.managedObjectContext else {
            return true
        }
        
        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        return (self.lastServerSyncedActiveParticipants.array as! [ZMUser]).first {
            if $0.isConnected {
                return false
            }
            else if $0.isWirelessUser {
                return false
            }
            else {
                return selfUser.team == nil || $0.team != selfUser.team
            }
        } != nil
    }
    
    fileprivate var allParticipantsHaveClients : Bool {
        return self.activeParticipants.first { $0.clients.count == 0 } == nil
    }
    
    /// If true the conversation might still be trusted / ignored
    @objc public var hasUntrustedClients : Bool {
        return self.activeParticipants.first { $0.untrusted() } != nil
    }
}

// MARK: - System messages
extension ZMSystemMessage {

    /// Fetch the first system message in the conversation about "started to use this device"
    fileprivate static func fetchStartedUsingOnThisDeviceMessage(conversation: ZMConversation) -> ZMSystemMessage? {
        guard let selfClient = ZMUser.selfUser(in: conversation.managedObjectContext!).selfClient() else { return nil }
        let conversationPredicate = NSPredicate(format: "%K == %@ OR %K == %@", ZMMessageConversationKey, conversation, ZMMessageHiddenInConversationKey, conversation)
        let newClientPredicate = NSPredicate(format: "%K == %d", ZMMessageSystemMessageTypeKey, ZMSystemMessageType.newClient.rawValue)
        let containsSelfClient = NSPredicate(format: "ANY %K == %@", ZMMessageSystemMessageClientsKey, selfClient)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [conversationPredicate, newClientPredicate, containsSelfClient])
        
        let fetchRequest = ZMSystemMessage.sortedFetchRequest(with: compound)!
        let result = conversation.managedObjectContext!.executeFetchRequestOrAssert(fetchRequest)!
        return result.first as? ZMSystemMessage
    }
}

extension ZMMessage {
    
    /// True if the message is a "conversation degraded because of new client"
    /// system message
    fileprivate var isConversationNotVerifiedSystemMessage : Bool {
        guard let system = self as? ZMSystemMessage else { return false }
        return system.systemMessageType == .ignoredClient
    }
}

extension Date {
    var nextNearestTimestamp: Date {
        return Date(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate.nextUp)
    }
    var previousNearestTimestamp: Date {
        return Date(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate.nextDown)
    }
}

extension NSDate {
    @objc var nextNearestTimestamp: NSDate {
        return NSDate(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate.nextUp)
    }
    @objc var previousNearestTimestamp: NSDate {
        return NSDate(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate.nextDown)
    }
}

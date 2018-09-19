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

private var zmLog = ZMSLog(tag: "message encryption")

// MARK: - Encrypted data for recipients

/// Strategy for missing clients.
/// When sending a message through the backend, the backend might warn
/// us that some user clients that were supposed to be there are missing (e.g.
/// another user added a new client that we don't yet know about). The various
/// strategies give a hint to the backend of how we want to handle missing clients.
public enum MissingClientsStrategy : Equatable {
    
    /// Fail the request if there is any missing client
    case doNotIgnoreAnyMissingClient
    /// Fail the request if there is any missing client for the given user,
    /// but ignore missing clients of any other user
    case ignoreAllMissingClientsNotFromUsers(users: Set<ZMUser>)
    /// Do not fail the request, no matter which clients are missing
    case ignoreAllMissingClients
}

public func ==(lhs: MissingClientsStrategy, rhs: MissingClientsStrategy) -> Bool {
    switch (lhs, rhs) {
    case (.doNotIgnoreAnyMissingClient, .doNotIgnoreAnyMissingClient):
        return true
    case (.ignoreAllMissingClients, .ignoreAllMissingClients):
        return true
    case (.ignoreAllMissingClientsNotFromUsers(let leftUsers), .ignoreAllMissingClientsNotFromUsers(let rightUsers)):
        return leftUsers == rightUsers
    default:
        return false
    }
}


public protocol EncryptedPayloadGenerator {
    /// Returns the payload encrypted for each recipients, and the strategy
    /// to use to handle missing clients
    func encryptedMessagePayloadData() -> (data: Data, strategy: MissingClientsStrategy)?

    var debugInfo: String { get }
}


extension ZMClientMessage: EncryptedPayloadGenerator {

    public func encryptedMessagePayloadData() -> (data: Data, strategy: MissingClientsStrategy)? {
        guard let genericMessage = self.genericMessage, let conversation = self.conversation else {
            return nil
        }
        return genericMessage.encryptedMessagePayloadData(conversation, externalData: nil)
    }

    public var debugInfo: String {
        var info = "\(String(describing: genericMessage))"
        if let genericMessage = genericMessage, genericMessage.hasExternal() {
            info = "External message: " + info
        }
        return info
    }

}


extension ZMAssetClientMessage: EncryptedPayloadGenerator {

    public func encryptedMessagePayloadData() -> (data: Data, strategy: MissingClientsStrategy)? {
        guard let genericMessage = genericAssetMessage, let conversation = conversation else { return nil }
        return genericMessage.encryptedMessagePayloadData(conversation, externalData: nil)
    }

    public var debugInfo: String {
        return "\(String(describing: genericAssetMessage))"
    }
    
}


extension ZMGenericMessage {
        
    public func encryptedMessagePayloadData(_ conversation: ZMConversation, externalData: Data?) -> (data: Data, strategy: MissingClientsStrategy)? {
        guard let context = conversation.managedObjectContext else { return nil }
        
        let recipientsAndStrategy = recipientUsersForMessage(in: conversation, selfUser: ZMUser.selfUser(in: context))
        if let data = encryptedMessagePayloadData(for: recipientsAndStrategy.users, externalData: nil, context: context) {
            return (data, recipientsAndStrategy.strategy)
        }
        
        return nil
    }
    
    public func encryptedMessagePayloadDataForBroadcast(context: NSManagedObjectContext) -> (data: Data, strategy: MissingClientsStrategy)? {
        let recipients = ZMUser.connectionsAndTeamMembers(in: context)
        
        if let data = encryptedMessagePayloadData(for: recipients, externalData: nil, context: context) {
            return (data, MissingClientsStrategy.doNotIgnoreAnyMissingClient)
        }
        
        return nil
    }
    
    fileprivate func encryptedMessagePayloadData(for recipients: Set<ZMUser>, externalData: Data?, context: NSManagedObjectContext) -> Data? {
        guard let selfClient = ZMUser.selfUser(in: context).selfClient(), selfClient.remoteIdentifier != nil
            else { return nil }
        
        let encryptionContext = selfClient.keysStore.encryptionContext
        var messageData : Data?
        
        encryptionContext.perform { (sessionsDirectory) in
            let message = otrMessage(selfClient, recipients: recipients, externalData: externalData, sessionDirectory: sessionsDirectory)

            messageData = message.data()
            
            // message too big?
            if let data = messageData, UInt(data.count) > ZMClientMessageByteSizeExternalThreshold && externalData == nil {
                // The payload is too big, we therefore rollback the session since we won't use the message we just encrypted.
                // This will prevent us advancing sender chain multiple time before sending a message, and reduce the risk of TooDistantFuture.
                sessionsDirectory.discardCache()
                messageData = self.encryptedMessageDataWithExternalDataBlob(recipients, context: context)
            }
        }
        return messageData
    }

    func recipientUsersForMessage(in conversation: ZMConversation, selfUser: ZMUser) -> (users: Set<ZMUser>, strategy: MissingClientsStrategy) {
        let (services, otherUsers) = (conversation.lastServerSyncedActiveParticipants.set as! Set<ZMUser>).categorize()

        func recipientForConfirmationMessage() -> Set<ZMUser>? {
            guard self.hasConfirmation(), self.confirmation.firstMessageId != nil else { return nil }
            guard let message = ZMMessage.fetch(withNonce:UUID(uuidString:self.confirmation.firstMessageId), for:conversation, in:conversation.managedObjectContext!) else { return nil }
            guard let sender = message.sender else { return nil }
            return Set(arrayLiteral: sender)
        }

        func recipientForOtherUsers() -> Set<ZMUser>? {
            guard conversation.connectedUser != nil || (otherUsers.isEmpty == false) else { return nil }
            if let connectedUser = conversation.connectedUser { return Set(arrayLiteral:connectedUser) }
            return Set(otherUsers)
        }

        func recipientsForDeletedEphemeral() -> Set<ZMUser>? {
            guard (self.hasDeleted() && conversation.conversationType == .group ) else { return nil }
            let nonce = UUID(uuidString: self.deleted.messageId)
            guard let message = ZMMessage.fetch(withNonce:nonce, for:conversation, in:conversation.managedObjectContext!) else { return nil }
            guard message.destructionDate != nil else { return nil }
            guard let sender = message.sender else {
                zmLog.error("sender of deleted ephemeral message \(String(describing: self.deleted.messageId)) is already cleared \n ConvID: \(String(describing: conversation.remoteIdentifier)) ConvType: \(conversation.conversationType.rawValue)")
                return Set(arrayLiteral: selfUser)
            }
            
            // if self deletes their own message, we want to send delete msg
            // for everyone, so return nil.
            guard !sender.isSelfUser else { return nil }
            
            // otherwise we delete only for self and the sender, all other
            // recipients are unaffected.
            return Set(arrayLiteral: sender, selfUser)
        }

        func allAuthorizedRecipients() -> Set<ZMUser> {
            if let connectedUser = conversation.connectedUser { return Set(arrayLiteral: connectedUser, selfUser) }

            func mentionedServices() -> Set<ZMUser> {
                return services.filtered { service in
                    self.textData?.mentions?.contains { $0.userId == service.remoteIdentifier?.transportString() } ?? false
                }
            }
            
            let authorizedServices = ZMUser.servicesMustBeMentioned ? mentionedServices() : services

            return otherUsers.union(authorizedServices).union([selfUser])
        }

        var recipientUsers = Set<ZMUser>()

        if self.hasConfirmation() {
            guard let recipients = recipientForConfirmationMessage() ?? recipientForOtherUsers() else {
                let confirmationInfo = hasConfirmation() ? ", original message: \(String(describing: self.confirmation.firstMessageId))" : ""
                fatal("confirmation need a recipient\n ConvType: \(conversation.conversationType.rawValue) \(confirmationInfo)")
            }
            recipientUsers = recipients
        }
        else if let deletedEphemeral = recipientsForDeletedEphemeral() {
            recipientUsers = deletedEphemeral
        }
        else {
            recipientUsers = allAuthorizedRecipients()
        }

        let hasRestrictions: Bool = {
            if conversation.connectedUser != nil { return recipientUsers.count != 2 }
            return recipientUsers.count != conversation.activeParticipants.count
        }()

        let strategy : MissingClientsStrategy = hasRestrictions ? .ignoreAllMissingClientsNotFromUsers(users: recipientUsers)
                                                                : .doNotIgnoreAnyMissingClient

        return (recipientUsers, strategy)
    }
    
    
    /// Returns a message with recipients and a strategy to handle missing clients
    fileprivate func otrMessage(_ selfClient: UserClient,
                            conversation: ZMConversation,
                            externalData: Data?,
                            sessionDirectory: EncryptionSessionsDirectory) -> (message: ZMNewOtrMessage, strategy: MissingClientsStrategy) {

        let (recipientUsers, strategy) = recipientUsersForMessage(in: conversation, selfUser: selfClient.user!)
        let recipients = self.recipientsWithEncryptedData(selfClient, recipients: recipientUsers, sessionDirectory: sessionDirectory)

        let nativePush = !hasConfirmation() // We do not want to send pushes for delivery receipts
        let message = ZMNewOtrMessage.message(withSender: selfClient, nativePush: nativePush, recipients: recipients, blob: externalData)
        
        return (message: message, strategy: strategy)
    }
    
    /// Returns a message with recipients
    fileprivate func otrMessage(_ selfClient: UserClient,
                                recipients: Set<ZMUser>,
                                externalData: Data?,
                                sessionDirectory: EncryptionSessionsDirectory) -> ZMNewOtrMessage {
        
        let userEntries = self.recipientsWithEncryptedData(selfClient, recipients: recipients, sessionDirectory: sessionDirectory)
        let nativePush = !hasConfirmation() // We do not want to send pushes for delivery receipts
        let message = ZMNewOtrMessage.message(withSender: selfClient, nativePush: nativePush, recipients: userEntries, blob: externalData)
        
        return message
    }
    
    /// Returns the recipients and the encrypted data for each recipient
    func recipientsWithEncryptedData(_ selfClient: UserClient,
                                     recipients: Set<ZMUser>,
                                     sessionDirectory: EncryptionSessionsDirectory
        ) -> [ZMUserEntry]
    {
        let userEntries = recipients.compactMap { user -> ZMUserEntry? in
                let clientsEntries = user.clients.compactMap { client -> ZMClientEntry? in
                if client != selfClient {
                    guard let clientRemoteIdentifier = client.sessionIdentifier else {
                        return nil
                    }
                    
                    let corruptedClient = client.failedToEstablishSession
                    client.failedToEstablishSession = false
                    
                    let hasSessionWithClient = sessionDirectory.hasSession(for: clientRemoteIdentifier)
                    if !hasSessionWithClient {
                        // if the session is corrupted, will send a special payload
                        if corruptedClient {
                            let data = ZMFailedToCreateEncryptedMessagePayloadString.data(using: String.Encoding.utf8)!
                            return ZMClientEntry.entry(withClient: client, data: data)
                        }
                        else {
                            // does not have session, will need to fetch prekey and create client
                            return nil
                        }
                    }
                    
                    guard let encryptedData = try? sessionDirectory.encryptCaching(self.data(), for: clientRemoteIdentifier) else {
                        return nil
                    }
                    return ZMClientEntry.entry(withClient: client, data: encryptedData)
                } else {
                    return nil
                }
            }
            
            if clientsEntries.isEmpty {
                return nil
            }
            return ZMUserEntry.entry(withUser: user, clientEntries: clientsEntries)
        }
        return userEntries
    }
    
}

// MARK: - External
extension ZMGenericMessage {
    
    /// Returns a message with recipients, with the content stored externally, and a strategy to handle missing clients
    fileprivate func encryptedMessageDataWithExternalDataBlob(_ conversation: ZMConversation) -> (data: Data, strategy: MissingClientsStrategy)? {
        
        guard let encryptedDataWithKeys = ZMGenericMessage.encryptedDataWithKeys(from: self) else { return nil }
        
        let externalGenericMessage = ZMGenericMessage.message(content: ZMExternal.external(withKeyWithChecksum: encryptedDataWithKeys.keys))
        return externalGenericMessage.encryptedMessagePayloadData(conversation, externalData: encryptedDataWithKeys.data)
    }
    
    fileprivate func encryptedMessageDataWithExternalDataBlob(_ recipients: Set<ZMUser>, context: NSManagedObjectContext) -> Data? {
        
        guard let encryptedDataWithKeys = ZMGenericMessage.encryptedDataWithKeys(from: self) else { return nil }
        
        let externalGenericMessage = ZMGenericMessage.message(content: ZMExternal.external(withKeyWithChecksum: encryptedDataWithKeys.keys))
        return externalGenericMessage.encryptedMessagePayloadData(for: recipients, externalData: encryptedDataWithKeys.data, context: context)
    }
}

// MARK: - Session identifier {
extension UserClient {
    
    /// Session identifier of the local cryptobox session with this client
    public var sessionIdentifier : EncryptionSessionIdentifier? {
        guard let userIdentifier = self.user?.remoteIdentifier,
            let clientIdentifier = self.remoteIdentifier
        else { return nil }
        return EncryptionSessionIdentifier(rawValue: "\(userIdentifier)_\(clientIdentifier)")
    }
    
    /// Previous (V1) session identifier
    fileprivate var sessionIdentifier_V1 : String? {
        return self.remoteIdentifier
    }
    
    /// Migrates from old session identifier to new session identifier if needed
    public func migrateSessionIdentifierFromV1IfNeeded(sessionDirectory: EncryptionSessionsDirectory) {
        guard let sessionIdentifier_V1 = self.sessionIdentifier_V1, let sessionIdentifier = self.sessionIdentifier else { return }
        sessionDirectory.migrateSession(from: sessionIdentifier_V1, to: sessionIdentifier)
    }
}

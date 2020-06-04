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

public let ZMFailedToCreateEncryptedMessagePayloadString = "💣"

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
        guard let genericMessage = self.underlyingMessage, let conversation = self.conversation else {
            return nil
        }
        return genericMessage.encryptedMessagePayloadData(conversation, externalData: nil)
    }

    public var debugInfo: String {
        var info = "\(String(describing: underlyingMessage))"
        if let genericMessage = underlyingMessage, genericMessage.hasExternal {
            info = "External message: " + info
        }
        return info
    }

}


extension ZMAssetClientMessage: EncryptedPayloadGenerator {

    public func encryptedMessagePayloadData() -> (data: Data, strategy: MissingClientsStrategy)? {
        guard let genericMessage = underlyingMessage, let conversation = conversation else { return nil }
        return genericMessage.encryptedMessagePayloadData(conversation, externalData: nil)
    }

    public var debugInfo: String {
        return "\(String(describing: underlyingMessage))"
    }
    
}

extension GenericMessage {
    public func encryptedMessagePayloadData(_ conversation: ZMConversation,
                                            externalData: Data?) -> (data: Data, strategy: MissingClientsStrategy)? {
        guard let context = conversation.managedObjectContext else { return nil }
        
        let recipientsAndStrategy = recipientUsersForMessage(in: conversation,
                                                             selfUser: ZMUser.selfUser(in: context))
        if let data = encryptedMessagePayloadData(for: recipientsAndStrategy.users,
                                                  missingClientsStrategy: recipientsAndStrategy.strategy,
                                                  externalData: nil,
                                                  context: context) {
            return (data, recipientsAndStrategy.strategy)
        }
        
        return nil
    }
    
    public func encryptedMessagePayloadDataForBroadcast(recipients: Set<ZMUser>,
                                                        in context: NSManagedObjectContext) -> (data: Data, strategy: MissingClientsStrategy)? {
        let missingClientsStrategy = MissingClientsStrategy.ignoreAllMissingClientsNotFromUsers(users: recipients)
        guard let data = encryptedMessagePayloadData(for: recipients,
                                                     missingClientsStrategy: missingClientsStrategy,
                                                     externalData: nil,
                                                     context: context) else { return nil }
        
        // It's important to ignore all irrelevant missing clients, because otherwise the backend will enforce that
        // the message is sent to all team members and contacts.
        return (data, missingClientsStrategy)
    }
    
    fileprivate func encryptedMessagePayloadData(for recipients: Set<ZMUser>,
                                                 missingClientsStrategy: MissingClientsStrategy,
                                                 externalData: Data?, context: NSManagedObjectContext) -> Data? {
        guard let selfClient = ZMUser.selfUser(in: context).selfClient(), selfClient.remoteIdentifier != nil
            else { return nil }
        
        let encryptionContext = selfClient.keysStore.encryptionContext
        var messageData : Data?
        
        encryptionContext.perform { (sessionsDirectory) in
            let message = otrMessage(selfClient,
                                     recipients: recipients,
                                     missingClientsStrategy: missingClientsStrategy,
                                     externalData: externalData,
                                     sessionDirectory: sessionsDirectory)
            
            messageData = try? message.serializedData()
            
            // message too big?
            if let data = messageData, UInt(data.count) > ZMClientMessage.byteSizeExternalThreshold && externalData == nil {
                // The payload is too big, we therefore rollback the session since we won't use the message we just encrypted.
                // This will prevent us advancing sender chain multiple time before sending a message, and reduce the risk of TooDistantFuture.
                sessionsDirectory.discardCache()
                messageData = self.encryptedMessageDataWithExternalDataBlob(recipients,
                                                                            missingClientsStrategy: missingClientsStrategy,
                                                                            context: context)
            }
        }
        
        // reset all failed sessions
        for recipient in recipients {
            recipient.clients.forEach({ $0.failedToEstablishSession = false })
        }
        
        return messageData
    }
    
    func recipientUsersForMessage(in conversation: ZMConversation, selfUser: ZMUser) -> (users: Set<ZMUser>, strategy: MissingClientsStrategy) {
        let (services, otherUsers) = conversation.localParticipants.categorizeServicesAndUser()

        func recipientForButtonActionMessage() -> Set<ZMUser> {
            guard
                case .buttonAction? = content,
                let message = ZMMessage.fetch(withNonce: UUID(uuidString: self.buttonAction.referenceMessageID), for: conversation, in: conversation.managedObjectContext!),
                let sender = message.sender else {
                    fatal("buttonAction needs a recipient")
            }
            return Set(arrayLiteral: sender)
        }
        
        func recipientForConfirmationMessage() -> Set<ZMUser>? {
            guard
                hasConfirmation,
                let managedObjectContext = conversation.managedObjectContext,
                let message = ZMMessage.fetch(withNonce:UUID(uuidString:self.confirmation.firstMessageID), for:conversation, in:managedObjectContext),
                let sender = message.sender else {
                    return nil
            }
            return Set(arrayLiteral: sender)
        }
        
        func recipientForOtherUsers() -> Set<ZMUser>? {
            guard conversation.connectedUser != nil || (otherUsers.isEmpty == false) else { return nil }
            if let connectedUser = conversation.connectedUser { return Set(arrayLiteral:connectedUser) }
            return Set(otherUsers)
        }
        
        func recipientsForDeletedEphemeral() -> Set<ZMUser>? {
            guard
                case .deleted? = content,
                conversation.conversationType == .group else {
                return nil
            }
            let nonce = UUID(uuidString: self.deleted.messageID)
            guard let message = ZMMessage.fetch(withNonce:nonce, for:conversation, in:conversation.managedObjectContext!) else { return nil }
            guard message.destructionDate != nil else { return nil }
            guard let sender = message.sender else {
                zmLog.error("sender of deleted ephemeral message \(String(describing: self.deleted.messageID)) is already cleared \n ConvID: \(String(describing: conversation.remoteIdentifier)) ConvType: \(conversation.conversationType.rawValue)")
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
                return services.filter { service in
                    self.textData?.mentions.contains { $0.userID == service.remoteIdentifier?.transportString() } ?? false
                }
            }
            
            let authorizedServices = ZMUser.servicesMustBeMentioned ? mentionedServices() : services
            
            return otherUsers.union(authorizedServices).union([selfUser])
        }
        
        var recipientUsers = Set<ZMUser>()
        
        switch content {
        case .confirmation?:
            guard let recipients = recipientForConfirmationMessage() ?? recipientForOtherUsers() else {
                let confirmationInfo = ", original message: \(String(describing: self.confirmation.firstMessageID))"
                fatal("confirmation need a recipient\n ConvType: \(conversation.conversationType.rawValue) \(confirmationInfo)")
            }
            recipientUsers = recipients
        case .buttonAction?:
            recipientUsers = recipientForButtonActionMessage()
        default:
            if let deletedEphemeral = recipientsForDeletedEphemeral() {
                recipientUsers = deletedEphemeral
            } else {
                recipientUsers = allAuthorizedRecipients()
            }
        }
        
        let hasRestrictions: Bool = {
            if conversation.connectedUser != nil { return recipientUsers.count != 2 }
            return recipientUsers.count != conversation.localParticipants.count
        }()
        
        let strategy: MissingClientsStrategy = hasRestrictions
            ? .ignoreAllMissingClientsNotFromUsers(users: recipientUsers)
            : .doNotIgnoreAnyMissingClient
        
        return (recipientUsers, strategy)
    }
    
    /// Returns a message with recipients
    fileprivate func otrMessage(_ selfClient: UserClient,
                                recipients: Set<ZMUser>,
                                missingClientsStrategy: MissingClientsStrategy,
                                externalData: Data?,
                                sessionDirectory: EncryptionSessionsDirectory) -> NewOtrMessage {
        
        let userEntries = recipientsWithEncryptedData(selfClient, recipients: recipients, sessionDirectory: sessionDirectory)
        let nativePush = !hasConfirmation // We do not want to send pushes for delivery receipts
        
        var message = NewOtrMessage(withSender: selfClient, nativePush: nativePush, recipients: userEntries, blob: externalData)
        
        
        switch missingClientsStrategy {
        case .ignoreAllMissingClientsNotFromUsers(let users):
            message.reportMissing = Array(users.map{ $0.userId })
        default:
            break
        }
        
        return message
    }
    
    /// Returns the recipients and the encrypted data for each recipient
    func recipientsWithEncryptedData(_ selfClient: UserClient,
                                     recipients: Set<ZMUser>,
                                     sessionDirectory: EncryptionSessionsDirectory
        ) -> [UserEntry]
    {
        let userEntries = recipients.compactMap { user -> UserEntry? in
            guard !user.isAccountDeleted else { return nil }
            
            let clientsEntries = user.clients.compactMap { client -> ClientEntry? in
                
                if client != selfClient {
                    guard let clientRemoteIdentifier = client.sessionIdentifier else {
                        return nil
                    }
                    
                    let hasSessionWithClient = sessionDirectory.hasSession(for: clientRemoteIdentifier)
                    
                    if !hasSessionWithClient {
                        // if the session is corrupted, we will send a special payload
                        if client.failedToEstablishSession {
                            let data = ZMFailedToCreateEncryptedMessagePayloadString.data(using: String.Encoding.utf8)!
                            return ClientEntry(withClient: client, data: data)
                        }
                        else {
                            // if we do not have a session, we need to fetch a prekey and create a new session
                            return nil
                        }
                    }
                    
                    guard let encryptedData = try? sessionDirectory.encryptCaching(self.serializedData(), for: clientRemoteIdentifier) else {
                        return nil
                    }
                    return ClientEntry(withClient: client, data: encryptedData)
                } else {
                    return nil
                }
            }
            
            if clientsEntries.isEmpty {
                return nil
            }
            return UserEntry(withUser: user, clientEntries: clientsEntries)
        }
        return userEntries
    }
}

// MARK: - External
extension GenericMessage {
    
    /// Returns a message with recipients, with the content stored externally, and a strategy to handle missing clients
    fileprivate func encryptedMessageDataWithExternalDataBlob(_ conversation: ZMConversation) -> (data: Data, strategy: MissingClientsStrategy)? {
        guard let encryptedDataWithKeys = GenericMessage.encryptedDataWithKeys(from: self) else {
            return nil
        }
        
        let externalGenericMessage = GenericMessage(content: External(withKeyWithChecksum: encryptedDataWithKeys.keys))
        return externalGenericMessage.encryptedMessagePayloadData(conversation, externalData: encryptedDataWithKeys.data)
    }
    
    fileprivate func encryptedMessageDataWithExternalDataBlob(_ recipients: Set<ZMUser>,
                                                              missingClientsStrategy: MissingClientsStrategy,
                                                              context: NSManagedObjectContext) -> Data? {
        guard let encryptedDataWithKeys = GenericMessage.encryptedDataWithKeys(from: self) else {
            return nil
        }
        
        let externalGenericMessage = GenericMessage(content: External(withKeyWithChecksum: encryptedDataWithKeys.keys))
        return externalGenericMessage.encryptedMessagePayloadData(for: recipients,
                                                                  missingClientsStrategy: missingClientsStrategy,
                                                                  externalData: encryptedDataWithKeys.data,
                                                                  context: context)
    }
}

// MARK: - Session identifier 
extension UserClient {
    
    /// Session identifier of the local cryptobox session with this client
    public var sessionIdentifier : EncryptionSessionIdentifier? {
        guard let userIdentifier = self.user?.remoteIdentifier,
            let clientIdentifier = self.remoteIdentifier
        else { return nil }
        return EncryptionSessionIdentifier(userId: userIdentifier.uuidString, clientId: clientIdentifier)
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

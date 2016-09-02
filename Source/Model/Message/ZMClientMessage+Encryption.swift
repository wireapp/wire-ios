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

// MARK: - Encrypted data for recipients

/// Strategy for missing clients.
/// When sending a message through the backend, the backend might warn
/// us that some user clients that were supposed to be there are missing (e.g.
/// another user added a new client that we don't yet know about). The various
/// strategies give a hint to the backend of how we want to handle missing clients.
public enum MissingClientsStrategy {
    
    /// Fail the request if there is any missing client
    case DoNotIgnoreAnyMissingClient
    /// Fail the request if there is any missing client for the given user,
    /// but ignore missing clients of any other user
    case IgnoreAllMissingClientsNotFromUser(user: ZMUser)
    /// Do not fail the request, no matter which clients are missing
    case IgnoreAllMissingClients
}

extension ZMClientMessage {
    
    /// Returns the payload encrypted for each recipients, and the strategy
    /// to use to handle missing clients
    public func encryptedMessagePayloadData() -> (data: NSData, strategy: MissingClientsStrategy)? {
        guard let genericMessage = self.genericMessage, let conversation = self.conversation else {
            return nil
        }
        return genericMessage.encryptedMessagePayloadData(conversation, externalData: nil)
    }
}

extension ZMGenericMessage {
    
    /// Returns the payload encrypted for each recipients in the conversation, 
    /// and the strategy to use to handle missing clients
    func encryptedMessagePayloadData(conversation: ZMConversation,
                                             externalData: NSData?)
        -> (data: NSData, strategy: MissingClientsStrategy)?
    {
        guard let context = conversation.managedObjectContext else {
            return nil
        }
        guard let selfClient = ZMUser.selfUserInContext(context).selfClient()
            where selfClient.remoteIdentifier != nil
        else {
            return nil
        }
        
        let encryptionContext = selfClient.keysStore.encryptionContext
        var messageDataAndStrategy : (data: NSData, strategy: MissingClientsStrategy)!
        encryptionContext.perform { (sessionsDirectory) in
            let messageAndStrategy = self.otrMessage(selfClient,
                conversation: conversation,
                externalData: externalData,
                sessionDirectory: sessionsDirectory
            )
            var messageData = messageAndStrategy.message.data()
            
            // message too big?
            if UInt(messageData.length) > ZMClientMessageByteSizeExternalThreshold && externalData == nil {
                // The payload is too big, we therefore rollback the session since we won't use the message we just encrypted.
                // This will prevent us advancing sender chain multiple time before sending a message, and reduce the risk of TooDistantFuture.
                sessionsDirectory.discardCache()
                messageData = self.encryptedMessageDataWithExternalDataBlob(conversation)!.data
            }
            messageDataAndStrategy = (data: messageData, strategy: messageAndStrategy.strategy)
        }
        return messageDataAndStrategy
    }
    
    /// Returns a message with recipients and a strategy to handle missing clients
    private func otrMessage(selfClient: UserClient,
                            conversation: ZMConversation,
                            externalData: NSData?,
                            sessionDirectory: EncryptionSessionsDirectory) -> (message: ZMNewOtrMessage, strategy: MissingClientsStrategy) {
        
        let recipientUsers : [ZMUser]
        let replyOnlyToSender = self.hasConfirmation()
        if replyOnlyToSender {
            // In case of confirmation messages, we want to send the confirmation only to the clients of the sender of the original message, not to everyone in the conversation
            let messageID = NSUUID.uuidWithTransportString(self.confirmation.messageId)
            let message = ZMMessage.fetchMessageWithNonce(messageID, forConversation: conversation, inManagedObjectContext: conversation.managedObjectContext)
            recipientUsers = [message.sender].flatMap { $0 }
        } else {
            recipientUsers = conversation.activeParticipants.array as! [ZMUser]
        }
        
        let recipients = self.recipientsWithEncryptedData(selfClient, recipients: recipientUsers, sessionDirectory: sessionDirectory)
        let message = ZMNewOtrMessage.message(withSender: selfClient, nativePush: true, recipients: recipients, blob: externalData)
        
        let strategy : MissingClientsStrategy =
            replyOnlyToSender ?
                .IgnoreAllMissingClientsNotFromUser(user: recipientUsers.first!)
                : .DoNotIgnoreAnyMissingClient
        return (message: message, strategy: strategy)
    }
    
    /// Returns the recipients and the encrypted data for each recipient
    func recipientsWithEncryptedData(selfClient: UserClient,
                                             recipients: [ZMUser],
                                             sessionDirectory: EncryptionSessionsDirectory
        ) -> [ZMUserEntry]
    {
        let userEntries = recipients.flatMap { user -> ZMUserEntry? in
                let clientsEntries = user.clients.flatMap { client -> ZMClientEntry? in
                if client != selfClient {
                    let corruptedClient = client.failedToEstablishSession
                    client.failedToEstablishSession = false
                    
                    let hasSessionWithClient = sessionDirectory.hasSessionForID(client.remoteIdentifier)
                    if !hasSessionWithClient {
                        // if the session is corrupted, will send a special payload
                        if corruptedClient {
                            let data = ZMFailedToCreateEncryptedMessagePayloadString.dataUsingEncoding(NSUTF8StringEncoding)!
                            return ZMClientEntry.entry(withClient: client, data: data)
                        }
                        else {
                            // does not have session, will need to fetch prekey and create client
                            return nil
                        }
                    }
                    
                    guard let encryptedData = try? sessionDirectory.encrypt(self.data(), recipientClientId: client.remoteIdentifier) else {
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
    private func encryptedMessageDataWithExternalDataBlob(conversation: ZMConversation) -> (data: NSData, strategy: MissingClientsStrategy)? {
        
        let encryptedDataWithKeys = ZMGenericMessage.encryptedDataWithKeysFromMessage(self)
        let externalGenericMessage = ZMGenericMessage.genericMessage(withKeyWithChecksum: encryptedDataWithKeys.keys, messageID: NSUUID().transportString())
        return externalGenericMessage.encryptedMessagePayloadData(conversation, externalData: encryptedDataWithKeys.data)
    }
}

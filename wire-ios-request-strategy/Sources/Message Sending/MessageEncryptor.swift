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
import WireProtos

enum MessageEncryptorError: Error {
    case missingValidSelfClient
    case missingSelfDomain
    case unableToEncryptForExternalData
}

private extension String {
    var hexRemoteIdentifier: UInt64 {
        let pointer = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        defer { pointer.deallocate() }
        Scanner(string: self).scanHexInt64(pointer)
        return UInt64(pointer.pointee)
    }
}

/// Provide the payload information for a message
struct MessagePayloadBuilder {
    var context: NSManagedObjectContext
    var proteusService: ProteusServiceInterface
    
    var useQualifiedIds: Bool = false

    func encryptForTransport(message: GenericMessage, in conversation: ZMConversation, externalData: Data? = nil) async throws -> Data {
        let extractor = MessageInfoExtractor(context: context)
        let messageInfo = try await extractor.infoForTransport(message: message, in: conversation)
        
        let plainText = try message.serializedData()
        var messageData: Data
        if useQualifiedIds {
            messageData = try await qualifiedData(messageInfo: messageInfo, plainText: plainText, externalData: externalData)
        } else {
            messageData = try await unQualifiedData(messageInfo: messageInfo, plainText: plainText, externalData: externalData)
        }
        
        // Message too big?
        if  UInt(messageData.count) > ZMClientMessage.byteSizeExternalThreshold && externalData == nil {
            // The payload is too big, we therefore rollback the session since we won't use the message we just encrypted.
            // This will prevent us advancing sender chain multiple time before sending a message, and reduce the risk of TooDistantFuture.
            messageData = try await encryptForTransportExternalDataBlob(message: message, messageInfo: messageInfo)
        }

        // Reset all failed sessions. -> [F] why do we reset the failedToEstablishSession on all clients ??
//        await context.perform {
//            recipients.values
//                .flatMap { $0 }
//                .forEach { $0.failedToEstablishSession = false }
//        }

        return messageData
    }
    
    private func encryptForTransportExternalDataBlob(message: GenericMessage, messageInfo: MessageInfo) async throws -> Data {
        
        guard
            let encryptedDataWithKeys = GenericMessage.encryptedDataWithKeys(from: message),
            let data = encryptedDataWithKeys.data,
            let keys = encryptedDataWithKeys.keys
        else {
            throw MessageEncryptorError.unableToEncryptForExternalData
        }

        let externalGenericMessage = GenericMessage(content: External(withKeyWithChecksum: keys))
        let plainText = try externalGenericMessage.serializedData()
   
        if useQualifiedIds {
            return try await qualifiedData(messageInfo: messageInfo, plainText: plainText, externalData: data)
        } else {
            return try await unQualifiedData(messageInfo: messageInfo, plainText: plainText, externalData: data)
        }
    }
        
    func unQualifiedData(messageInfo: MessageInfo, plainText: Data, externalData: Data? = nil) async throws -> Data {
        
        var userEntries = [Proteus_UserEntry]()
        for (_, entries) in messageInfo.listClients {

            for (userId, sessionsIds) in entries {
                
                let encryptedDatas = try await proteusService.encryptBatched(data: plainText, forSessions: sessionsIds)
                
                let userId = Proteus_UserId.with({ $0.uuid = userId.uuidData })
                
                let clientEntries = encryptedDatas.map { (sessionID, encryptedData) in
                    let clientId = Proteus_ClientId.with({ $0.client = sessionID.hexRemoteIdentifier })
                    return Proteus_ClientEntry(withClientId: clientId, data: encryptedData)
                }

                userEntries.append(
                    Proteus_UserEntry(withProteusUserId: userId, clientEntries: clientEntries)
                )
            }
        }

        let message = Proteus_NewOtrMessage(
            withSenderId: messageInfo.selfClientID.hexRemoteIdentifier,
            nativePush: messageInfo.nativePush,
            recipients: userEntries,
            missingClientsStrategy: messageInfo.missingClientsStrategy,
            blob: externalData
        )
        
        return try message.serializedData()
    }
        
    func qualifiedData(messageInfo: MessageInfo, plainText: Data, externalData: Data? = nil) async throws -> Data {

        var finalRecipients = [Proteus_QualifiedUserEntry]()
        for (domain, entries) in messageInfo.listClients {

            var userEntries = [Proteus_UserEntry]()

            for (userId, sessionsIds) in entries {
                
                let encryptedDatas = try await proteusService.encryptBatched(data: plainText, forSessions: sessionsIds)
                
                let userId = Proteus_UserId.with({ $0.uuid = userId.uuidData })
                
                let clientEntries = encryptedDatas.map { (sessionID, encryptedData) in
                    let clientId = Proteus_ClientId.with({ $0.client = sessionID.hexRemoteIdentifier })
                    return Proteus_ClientEntry(withClientId: clientId, data: encryptedData)
                }

                userEntries.append(
                    Proteus_UserEntry(withProteusUserId: userId, clientEntries: clientEntries)
                )
            }

            finalRecipients.append(
                Proteus_QualifiedUserEntry(withDomain: domain, userEntries: userEntries)
            )
        }
        
        
        let message = Proteus_QualifiedNewOtrMessage(
            withSenderId: messageInfo.selfClientID.hexRemoteIdentifier,
            nativePush: messageInfo.nativePush,
            recipients: finalRecipients,
            missingClientsStrategy: messageInfo.missingClientsStrategy,
            blob: externalData
        )
        
        return try message.serializedData()
    }
   

    
    /* TODO: handle failedToEstablishSession
     
     guard await !client.failedToEstablishSession else {
         // If the session is corrupted, we will send a special payload.
         let data = ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8)!
         WireLogger.proteus.error("Failed to encrypt payload: session is not established with client: \(await client.loggedId)")
         return await client.proteusClientEntry(with: data)
     }
   
     do {
         let plainText = try serializedData()
         let encryptedData = try await encryptionFunction(sessionID, plainText)
         guard let data = encryptedData else { return nil }
         return await client.proteusClientEntry(with: data)
     } catch {
         // this is handled by message sender, it's just that we don't throw the errors
         return nil
     }
     */
    

}

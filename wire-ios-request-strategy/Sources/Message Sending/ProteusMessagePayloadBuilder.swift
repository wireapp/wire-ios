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
    case emptyEncryptedData
}

private extension String {
    var hexRemoteIdentifier: UInt64 {
        let pointer = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        defer { pointer.deallocate() }
        Scanner(string: self).scanHexInt64(pointer)
        return UInt64(pointer.pointee)
    }
}

/// Provide the payload for a given proteus message
struct ProteusMessagePayloadBuilder {
    var context: NSManagedObjectContext
    var proteusService: ProteusServiceInterface

    var useQualifiedIds: Bool = false

    func encryptForTransport(with messageInfo: MessageInfo, externalData: Data? = nil) async throws -> Data {

        // 1) encrypt the data with proteusService
        let plainText = try messageInfo.genericMessage.serializedData()
        let allSessionIds = messageInfo.allSessionIds()
    
        // if a sessionId does not exist / not established, no data (key,value) is return for the sessionId!
        let encryptedDatas = try await proteusService.encryptBatched(data: plainText, forSessions: allSessionIds)

        guard !encryptedDatas.isEmpty else {
            throw MessageEncryptorError.emptyEncryptedData
        }
        
        // 2) Wrap the encryptedData in protobuf object that will be serialized
        var messageData: Data
        if useQualifiedIds {
            messageData = try await qualifiedData(messageInfo: messageInfo, encryptedDatas: encryptedDatas, externalData: externalData)
        } else {
            messageData = try await unQualifiedData(messageInfo: messageInfo, encryptedDatas: encryptedDatas, externalData: externalData)
        }

        // Message too big?
        if  UInt(messageData.count) > ZMClientMessage.byteSizeExternalThreshold && externalData == nil {
            // The payload is too big, we therefore rollback the session since we won't use the message we just encrypted.
            // This will prevent us advancing sender chain multiple time before sending a message, and reduce the risk of TooDistantFuture.
            messageData = try await encryptForTransportExternalDataBlob(message: messageInfo.genericMessage, messageInfo: messageInfo)
        }

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
        let allSessionIds = messageInfo.allSessionIds()
        let encryptedDatas = try await proteusService.encryptBatched(data: plainText, forSessions: allSessionIds)

        if useQualifiedIds {
            return try await qualifiedData(messageInfo: messageInfo, encryptedDatas: encryptedDatas, externalData: data)
        } else {
            return try await unQualifiedData(messageInfo: messageInfo, encryptedDatas: encryptedDatas, externalData: data)
        }
    }

    private func unQualifiedData(messageInfo: MessageInfo, encryptedDatas: [String: Data], externalData: Data? = nil) async throws -> Data {
        var userEntries = [Proteus_UserEntry]()
        for (_, entries) in messageInfo.listClients {

            for (userId, userClientDatas) in entries {

                let userEntry = proteusUserEntry(userClientDatas: userClientDatas, for: userId, encryptedDatas: encryptedDatas)
                userEntries.append(userEntry)
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

    private func qualifiedData(messageInfo: MessageInfo, encryptedDatas: [String: Data], externalData: Data? = nil) async throws -> Data {

        var finalRecipients = [Proteus_QualifiedUserEntry]()
        for (domain, entries) in messageInfo.listClients {

            var userEntries = [Proteus_UserEntry]()
            for (userId, userClientDatas) in entries {

                let userEntry = proteusUserEntry(userClientDatas: userClientDatas, for: userId, encryptedDatas: encryptedDatas)
                userEntries.append(userEntry)
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

    private func proteusUserEntry(userClientDatas: [UserClientData],
                                  for userID: UUID,
                                  encryptedDatas: [String: Data]) -> Proteus_UserEntry {
        let proteusUserID = Proteus_UserId.with({ $0.uuid = userID.uuidData })

        let clientEntries = userClientDatas.compactMap { userClientData in
            let clientId = Proteus_ClientId.with({ $0.client = userClientData.sessionID.clientID.hexRemoteIdentifier })

            if let data = userClientData.data {
                return Proteus_ClientEntry(withClientId: clientId, data: data)
            }
            if let encryptedData = encryptedDatas[userClientData.sessionID.rawValue] {
                return Proteus_ClientEntry(withClientId: clientId, data: encryptedData)
            } else {
                // all clients here don't have established sessions, this will be handled in MessageSender
                return nil
            }
        }
        return Proteus_UserEntry(withProteusUserId: proteusUserID, clientEntries: clientEntries)
    }
}

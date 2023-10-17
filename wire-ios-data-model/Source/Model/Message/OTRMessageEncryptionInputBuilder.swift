////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

typealias Domain = String
typealias UserId_ClientIds = [UUID: [Proteus_ClientId]]

struct OTRMessageQualifiedEncryptionInput {
    var info: [Domain: UserId_ClientIds]
    var plainData: Data
    var proteusSessionId: ProteusSessionID
    var senderId: Proteus_ClientId
    var nativePush: Bool // !hasConfirmation
    var blob: Data?
    var missingClientsStrategy: MissingClientsStrategy
}

struct OTRMessageEncryptionInput {
    //    UUID = Proteus_UserId
    var info: UserId_ClientIds
    var plainData: Data
    var proteusSessionId: ProteusSessionID
    var senderId: Proteus_ClientId
    var nativePush: Bool // !hasConfirmation
    var blob: Data?
}

enum OTRMessageEncryptionInputError: Error {
    case missingDomain
    case missingPreConditions
}

class OTRMessageEncryptionInputBuilder {

    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Extract info

    public func createInput(from genericMessage: GenericMessage, for conversation: ZMConversation) throws -> OTRMessageEncryptionInput {
        return try context.performAndWait { [context] in
            let selfUser = ZMUser.selfUser(in: context)

            guard let selfClient = selfUser.selfClient(), selfClient.remoteIdentifier != nil,
                    let sessionId = selfClient.proteusSessionID else {
                throw OTRMessageEncryptionInputError.missingPreConditions
            }

            let (users, _) = genericMessage.recipientUsersForMessage(in: conversation, selfUser: selfUser)
            let recipients = users.mapToDictionary { $0.clients }

            let userIds_ClientIds = users.compactMapToDictionary(with: { $0.remoteIdentifier }, valueBlock: { $0.clients.map { client in client.clientId } })

            let plainText = try genericMessage.serializedData()
            return .init(info: userIds_ClientIds,
                         plainData: plainText,
                         proteusSessionId: sessionId,
                         senderId: selfClient.clientId,
                         nativePush: !genericMessage.hasConfirmation,
                         blob: nil)
        }
    }

    public func createQualifiedInput(from genericMessage: GenericMessage, for conversation: ZMConversation) throws -> OTRMessageQualifiedEncryptionInput {

        return try context.performAndWait {
            let selfUser = ZMUser.selfUser(in: self.context)

            guard let selfDomain = selfUser.domain else {
                // no domain cannot do qualified input
                throw OTRMessageEncryptionInputError.missingDomain
            }

            guard let selfClient = selfUser.selfClient(), selfClient.remoteIdentifier != nil,
                  let sessionId = selfClient.proteusSessionID else {
                throw OTRMessageEncryptionInputError.missingPreConditions
            }

            let (users, missingClientsStrategy) = genericMessage.recipientUsersForMessage(in: conversation, selfUser: selfUser)

            let domain_UserIdsClientIds: [Domain: UserId_ClientIds] = users.compactMapToDictionary(with: {
                guard $0.isAccountDeleted else { return nil }
                return $0.domain ?? selfDomain
            }, valueBlock: { user in
                guard let id = user.remoteIdentifier else { return nil }

                return [id: user.clients.compactMap { client in
                    guard client != selfClient else { return nil }
                    return client.clientId
                }]
            })

            let plainText = try genericMessage.serializedData()
            return .init(info: domain_UserIdsClientIds,
                         plainData: plainText,
                         proteusSessionId: sessionId,
                         senderId: selfClient.clientId,
                         nativePush: !genericMessage.hasConfirmation,
                         blob: nil,
                         missingClientsStrategy: missingClientsStrategy)
        }
    }
}

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

/*

 encrypt(usingProteusService
 otrMessage
 userEntriesWithEncryptedData
 clientEntriesWithEncryptedData
 clientEntry which uses the encryptionFunction (proteusService.)
 */

class EncryptOTRMessageUseCase {

    let proteusService: ProteusService
    let context: NSManagedObjectContext

    init(proteusService: ProteusService, context: NSManagedObjectContext) {
        self.proteusService = proteusService
        self.context = context
    }

    // MARK: - Extract info

    public func createInput(from genericMessage: GenericMessage, for conversation: ZMConversation) -> OTRMessageEncryptionInput? {
        var input: OTRMessageEncryptionInput?
        context.performAndWait {
            let selfUser = ZMUser.selfUser(in: context)

            guard let selfClient = selfUser.selfClient(), selfClient.remoteIdentifier != nil,
                    let sessionId = selfClient.proteusSessionID else {
                return
            }

            let (users, _) = genericMessage.recipientUsersForMessage(in: conversation, selfUser: selfUser)
            let recipients = users.mapToDictionary { $0.clients }

            let userIds_ClientIds = users.compactMapToDictionary(with: { $0.remoteIdentifier }, valueBlock: { $0.clients.map { client in client.clientId } })

            do {
                let plainText = try genericMessage.serializedData()
                input = .init(info: userIds_ClientIds,
                              plainData: plainText,
                              proteusSessionId: sessionId,
                              senderId: selfClient.clientId,
                              nativePush: !genericMessage.hasConfirmation,
                              blob: nil)
            } catch {
                WireLogger.proteus.error("could not serialized generic message to encrypt")
                input = nil
            }
        }

        /*
         encryptedData = encrypt(
             using: proteusService,
             for: recipients,
             with: missingClientsStrategy,
             externalData: externalData,
             useQualifiedIdentifiers: useQualifiedIdentifiers,
             in: context
         )
         */
        return input
    }

    public func createQualifiedInput(from genericMessage: GenericMessage) -> OTRMessageEncryptionInput {

    }

    // MARK: - Encryption

    public func encrypt(_ input: OTRMessageEncryptionInput) -> Proteus_NewOtrMessage {

        let userEntries = userEntries(for: input.info, plainData: input.plainData, sessionId: input.proteusSessionId)
        return Proteus_NewOtrMessage(withSenderId: input.senderId,
                                     nativePush: input.nativePush,
                                     recipients: userEntries,
                                     blob: input.blob)
    }

    public func encrypt(_ input: OTRMessageQualifiedEncryptionInput) -> Proteus_QualifiedNewOtrMessage {

        var qualifiedUserEntries = [Proteus_QualifiedUserEntry]()
        for (domain, users) in input.info {
            let userEntries = userEntries(for: users,
                                          plainData: input.plainData,
                                          sessionId: input.proteusSessionId)
            qualifiedUserEntries.append(.init(withDomain: domain, userEntries: userEntries))
        }

        return Proteus_QualifiedNewOtrMessage(withProteusSenderId: input.senderId,
                                              nativePush: input.nativePush,
                                              recipients: qualifiedUserEntries,
                                              missingClientsStrategy: .doNotIgnoreAnyMissingClient,// TODO: replace me
                                              blob: input.blob)
    }

    // MARK: - Helpers

    private func userEntries(for users: UserId_ClientIds,
                             plainData: Data,
                             sessionId: ProteusSessionID) -> [Proteus_UserEntry] {
        var userEntries = [Proteus_UserEntry]()
        for (userId, clients) in users {
            var clientEntries = [Proteus_ClientEntry]()
            for client in clients {
                if let clientEntry = encryptedData(plainData,
                                                   with: client,
                                                   and: sessionId) {
                    clientEntries.append(clientEntry)
                }
            }
            userEntries.append(.init(withUserId: userId, clientEntries: clientEntries))
        }
        return userEntries
    }

    private func encryptedData(_ plainText: Data, with clientId: Proteus_ClientId, and sessionID: ProteusSessionID) -> Proteus_ClientEntry? {
        do {
            let encryptedData = try proteusService.encrypt(data: plainText, forSession: sessionID)
            return Proteus_ClientEntry(withClientId: clientId, data: encryptedData)
        } catch {
            WireLogger.proteus.error("failed to encrypt payload for a client: \(String(describing: error))")
            return nil
        }
    }
}

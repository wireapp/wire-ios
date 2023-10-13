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

struct OTRMessageQualifiedEncryptionInput {
    var info: [Domain: [UUID: [Proteus_ClientId]]]
    var plainData: Data
    var proteusSessionId: ProteusSessionID
    var senderId: Proteus_ClientId
    var nativePush: Bool // !hasConfirmation
    var blob: Data?
}

struct OTRMessageEncryptionInput {
    //    UUID = Proteus_UserId
    var info: [UUID: [Proteus_ClientId]]
    var plainData: Data
    var proteusSessionId: ProteusSessionID
    var senderId: Proteus_ClientId
    var nativePush: Bool // !hasConfirmation
    var blob: Data?
}

class EncryptOTRMessageUseCase {
    typealias QualifiedInput = [Domain: [UUID: [Proteus_ClientId]]]
    typealias Input = [UUID: [Proteus_ClientId]]

    var proteusService: ProteusService!
    var context: NSManagedObjectContext!

    func encrypt(_ input: OTRMessageEncryptionInput) -> Proteus_NewOtrMessage {

        var userEntries = [Proteus_UserEntry]()

        for (userId, clients) in input.info {
            var clientEntries = [Proteus_ClientEntry]()
            for client in clients {
                if let clientEntry = encryptedData(input.plainData,
                                                   with: client,
                                                   and: input.proteusSessionId) {
                    clientEntries.append(clientEntry)
                }
            }
            userEntries.append(.init(withUserId: userId, clientEntries: clientEntries))
        }
        return Proteus_NewOtrMessage(withSenderId: input.senderId,
                                     nativePush: input.nativePush,
                                     recipients: userEntries,
                                     blob: input.blob)
    }

    func encrypt(_ input: OTRMessageQualifiedEncryptionInput) -> Proteus_QualifiedNewOtrMessage {

        var qualifiedUserEntries = [Proteus_QualifiedUserEntry]()
        for (domain, users) in input.info {
            var userEntries = [Proteus_UserEntry]()
            for (userId, clients) in users {
                var clientEntries = [Proteus_ClientEntry]()
                for client in clients {
                    if let clientEntry = encryptedData(input.plainData,
                                                       with: client,
                                                       and: input.proteusSessionId) {
                        clientEntries.append(clientEntry)
                    }
                }
                userEntries.append(.init(withUserId: userId, clientEntries: clientEntries))
            }
            qualifiedUserEntries.append(.init(withDomain: domain, userEntries: userEntries))
        }

        return Proteus_QualifiedNewOtrMessage(withProteusSenderId: input.senderId,
                                              nativePush: input.nativePush,
                                              recipients: qualifiedUserEntries,
                                              missingClientsStrategy: .doNotIgnoreAnyMissingClient,// TODO: replace me
                                              blob: input.blob)
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
//
// extension
//    private func clientEntry(
//        for client: UserClient,
//        using encryptionFunction: EncryptionFunction
//    ) -> Proteus_ClientEntry? {
//        guard let sessionID = client.proteusSessionID else {
//            return nil
//        }
//
//        guard !client.failedToEstablishSession else {
//            // If the session is corrupted, we will send a special payload.
//            let data = ZMFailedToCreateEncryptedMessagePayloadString.data(using: String.Encoding.utf8)!
//            WireLogger.proteus.error("Failed to encrypt payload: session is not established with client: \(client.remoteIdentifier)", attributes: nil)
//            return Proteus_ClientEntry(withClient: client, data: data)
//        }
//
//        do {
//            let plainText = try serializedData()
//            let encryptedData = try encryptionFunction(sessionID, plainText)
//            guard let data = encryptedData else { return nil }
//            return Proteus_ClientEntry(withClient: client, data: data)
//        } catch {
//            WireLogger.proteus.error("failed to encrypt payload for a client: \(String(describing: error))")
//            return nil
//        }
//    }
    /*

     encrypt(usingProteusService
        otrMessage
            userEntriesWithEncryptedData
                clientEntriesWithEncryptedData
                    clientEntry which uses the encryptionFunction (proteusService.)

     */

//
//    func encrypt(for c_ genericMessage: GenericMessage) -> Proteus_NewOtrMessage {
//
//        // 1) extract values from NSManagedObject
//
//
//        context.performAndWait {
//            let user = ZMUser.selfUser(in: context)
//            guard
//                let selfClient = user.selfClient(),
//                selfClient.remoteIdentifier != nil
//            else {
//                return nil
//            }
//        }
////        genericMessage
////        let userEntries: [Proteus_UserEntry]
////        let qualifiedUserEntries = qualifiedUserEntriesWithEncryptedData(
////            selfClient,
////            selfDomain: selfDomain,
////            recipients: recipients,
////            using: encryptionFunction
////        )
////
////        // We do not want to send pushes for delivery receipts.
////        let nativePush = !hasConfirmation
////
////        return Proteus_QualifiedNewOtrMessage(
////            withSender: selfClient,
////            nativePush: nativePush,
////            recipients: qualifiedUserEntries,
////            missingClientsStrategy: missingClientsStrategy,
////            blob: externalData
//
//    }
//
//
//    func encrypt(_ genericMessage: GenericMessage) throws ->  Proteus_QualifiedNewOtrMessage {
//
//
//
//

//
//        var plainText: Data
//        var sessionID: ProteusSessionID
//        let result = try proteusService.encrypt(
//            data: plainText,
//            forSession: sessionID
//        )
//
////        return Proteus_QualifiedNewOtrMessage(withProteusSenderId: Proteus_ClientId,
////                                              nativePush: <#T##Bool#>,
////                                              recipients: <#T##[Proteus_QualifiedUserEntry]#>,
////                                              missingClientsStrategy: <#T##MissingClientsStrategy#>,
////                                              blob: <#T##Data?#>)
//    }

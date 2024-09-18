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

struct UserClientData {
    var sessionID: ProteusSessionID
    var data: Data?
}

struct MessageInfo {
    typealias Domain = String
    typealias UserID = UUID
    typealias ClientList = [Domain: [UserID: [UserClientData]]]

    var genericMessage: GenericMessage
    /// list of clients divided per domain and userId
    var listClients: ClientList
    var missingClientsStrategy: MissingClientsStrategy
    var selfClientID: String
    var nativePush: Bool
    private var userClients: [UserClient]
    
    internal init(genericMessage: GenericMessage,
                  listClients: MessageInfo.ClientList,
                  missingClientsStrategy: MissingClientsStrategy,
                  selfClientID: String,
                  nativePush: Bool,
                  userClients: [UserClient]
    ) {
        self.genericMessage = genericMessage
        self.listClients = listClients
        self.missingClientsStrategy = missingClientsStrategy
        self.selfClientID = selfClientID
        self.nativePush = nativePush
        self.userClients = userClients
    }
    
    func allSessionIds() -> [ProteusSessionID] {
        var result = [ProteusSessionID]()
        for (_, userClientIdAndSessionIds) in listClients {
            for (_, userClientDatas) in userClientIdAndSessionIds {
                let sessionIds = userClientDatas.compactMap( { $0.data == nil ? $0.sessionID : nil })
                result.append(contentsOf: sessionIds)
            }
        }
        return result
    }
    
    func resetAllUserClientsFailedSessions(in context: NSManagedObjectContext) async {
        await context.perform {
            userClients.forEach { $0.failedToEstablishSession = false }
            context.saveOrRollback()
        }
    }
}

enum MessageInfoExtractorError: Error {
    case missingConversation
    case missingGenericMessage
}

/// Pull out of coredata object info to send a message
struct MessageInfoExtractor {
    var context: NSManagedObjectContext

    func infoForTransport(message: any ProteusMessage, conversationID: QualifiedID) async throws -> MessageInfo {
        let (conversation, genericMessage) = await context.perform { [context] in
            (ZMConversation.fetch(with: conversationID.uuid, domain: conversationID.domain, in: context),
             message.underlyingMessage)
        }

        guard let conversation else {
            throw MessageInfoExtractorError.missingConversation
        }

        guard let genericMessage else {
            throw MessageInfoExtractorError.missingGenericMessage
        }

        return try await infoForTransport(message: genericMessage, in: conversation)
    }

    private func infoForTransport(message: GenericMessage, in conversation: ZMConversation) async throws -> MessageInfo {
        let (selfUser, selfDomain) = await context.perform {
            let user = ZMUser.selfUser(in: context)
            return (user, user.domain)
        }
        let selfClientID = try await selfClientID()
        guard let selfDomain else {
            throw MessageEncryptorError.missingSelfDomain
        }

        // get the recipients and the missing clientsStrategy
        let (recipients, missingClientsStrategy) = await self.recipients(for: message, selfUser: selfUser, in: conversation)

        // get the list of clients
        let clients = await listOfClients(for: recipients, selfDomain: selfDomain, selfClientID: selfClientID)
        let userClients = await context.perform { recipients.map { $1 }.flatMap { $0 } }
        return MessageInfo(
            genericMessage: message,
            listClients: clients,
            missingClientsStrategy: missingClientsStrategy,
            selfClientID: selfClientID,
            // We do not want to send pushes for delivery receipts.
            nativePush: !message.hasConfirmation,
            userClients: userClients
        )
    }

    private func selfClientID() async throws -> String {
        let selfClientID = await context.perform {
            ZMUser.selfUser(in: context).selfClient()?.remoteIdentifier
        }
        guard let id = selfClientID else { throw MessageEncryptorError.missingValidSelfClient }
        return id
    }

    private func recipients(for message: GenericMessage, selfUser: ZMUser, in conversation: ZMConversation) async -> ([ZMUser: Set<UserClient>], MissingClientsStrategy) {
        let (users, missingClientsStrategy) = await context.perform { message.recipientUsersForMessage(in: conversation, selfUser: selfUser) }

        return (users , missingClientsStrategy)
    }

    private func listOfClients(for recipients: [ZMUser: Set<UserClient>], selfDomain: String, selfClientID: String) async -> MessageInfo.ClientList {

        let recipientsByDomain = await context.perform {
            Dictionary(grouping: recipients) { element -> String in
                element.key.domain ?? selfDomain
                // is there really a need to keep selfDomain as backup values
            }
        }

        var qualifiedUserEntries = MessageInfo.ClientList()
        for (domain, recipients) in recipientsByDomain {

            var userEntries = [MessageInfo.UserID: [UserClientData]]()
            for (user, clients) in recipients {
                guard let userId = await context.perform({
                    !user.isAccountDeleted ? user.remoteIdentifier : nil
                }) else { continue }

                let userClientDatas = await userClientDatas(selfClientID: selfClientID, userClients: clients)
                userEntries[userId] = userClientDatas
            }
            qualifiedUserEntries[domain] = userEntries
        }
        return qualifiedUserEntries
    }

    private func userClientDatas(selfClientID: String, userClients: Set<UserClient>) async -> [UserClientData] {

        return await context.perform {
            userClients.compactMap {
                guard let sessionID = $0.proteusSessionID,
                      $0.remoteIdentifier != selfClientID else {
                    // skips self client session
                    WireLogger.proteus.warn("skips cliend id: \(String(describing: $0.remoteIdentifier)), proteusSession id: \(String(describing: $0.proteusSessionID))")
                    return nil
                }

                guard !$0.failedToEstablishSession else {
                    let data = ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8)!
                    WireLogger.proteus.error("Failed to encrypt payload: session is not established with client: \(String(describing: $0.remoteIdentifier))")
                    return UserClientData(sessionID: sessionID, data: data)
                }

                return UserClientData(sessionID: sessionID, data: nil)
            }
        }
    }
}

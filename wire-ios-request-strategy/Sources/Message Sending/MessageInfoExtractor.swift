//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import GenericMessageProtocol
import WireLogging

enum MessageInfoExtractorError: Error {
    case contextUnavailable
    case missingConversation
    case missingGenericMessage
    case missingValidSelfClient
    case missingSelfDomain
    case unsupportedBroadcastMessage
    case unsupportedTargetRecipient

}

/// Pull out of coredata object info to send a message
struct MessageInfoExtractor {
    var context: NSManagedObjectContext

    func infoForBroadcast(message: any ProteusMessage) async throws -> MessageInfo {
        try Task.checkCancellation()
        guard let message = message as? GenericMessageEntity else {
            throw MessageInfoExtractorError.unsupportedBroadcastMessage
        }

        return try await context.perform {
            try requireActiveContext()
            guard let genericMessage = message.underlyingMessage else {
                throw MessageInfoExtractorError.missingGenericMessage
            }
            switch message.targetRecipients {
            case let .users(users):
                var info = try infoForTransport(message: genericMessage, for: users)
                let userQualifiedIDs = Set(users.compactMap(\.qualifiedID))
                info.missingClientsStrategy = MissingClientsStrategy
                    .ignoreAllMissingClientsNotFromUsers(userIds: userQualifiedIDs)
                return info
            case .conversationParticipants, .clients:
                throw MessageInfoExtractorError.unsupportedTargetRecipient
            }
        }

    }

    func infoForSending(message: any ProteusMessage, conversationID: QualifiedID) async throws -> MessageInfo {
        try Task.checkCancellation()
        return try await context.perform {
            try requireActiveContext()
            if let row = message as? ZMMessage {
                guard row.managedObjectContext === context, !row.isDeleted, !row.hasBeenDeleted else {
                    throw MessageInfoExtractorError.missingGenericMessage
                }
            }
            guard let conversation = ZMConversation.fetch(
                with: conversationID.uuid, domain: conversationID.domain, in: context
            ) else { throw MessageInfoExtractorError.missingConversation }
            guard let genericMessage = message.underlyingMessage else {
                throw MessageInfoExtractorError.missingGenericMessage
            }
            switch message.targetRecipients {
            case .conversationParticipants:
                return try infoForTransport(message: genericMessage, in: conversation)
            case let .users(users):
                return try infoForTransport(message: genericMessage, for: users)
            case let .clients(messageRecipients):
                return try infoForTransport(message: genericMessage, for: messageRecipients)
            }
        }
    }

    // MARK: - Private

    // These helpers run synchronously inside the entry point's context block. No managed rows
    // cross an async suspension while extracting the immutable transport information.
    private func requireActiveContext() throws {
        guard context.zm_isValidContext else { throw MessageInfoExtractorError.contextUnavailable }
    }

    private func infoForTransport(message: GenericMessage, for users: Set<ZMUser>) throws -> MessageInfo {
        let messageRecipients = users.mapToDictionary { $0.clients }

        return try infoForTransport(message: message, for: messageRecipients)
    }

    private func infoForTransport(
        message: GenericMessage,
        for messageRecipients: [ZMUser: Set<UserClient>]
    ) throws -> MessageInfo {
        let selfDomain = ZMUser.selfUser(in: context).domain
        let selfClientID = try selfClientID()
        guard let selfDomain else {
            throw MessageInfoExtractorError.missingSelfDomain
        }
        let listClients = listOfClients(
            for: messageRecipients,
            selfDomain: selfDomain,
            selfClientID: selfClientID
        )

        return MessageInfo(
            genericMessage: message,
            listClients: listClients,
            missingClientsStrategy: .ignoreAllMissingClients,
            selfClientID: selfClientID
        )
    }

    private func infoForTransport(
        message: GenericMessage,
        in conversation: ZMConversation
    ) throws -> MessageInfo {
        let selfUser = ZMUser.selfUser(in: context)
        let selfDomain = selfUser.domain
        let selfClientID = try selfClientID()
        guard let selfDomain else {
            throw MessageInfoExtractorError.missingSelfDomain
        }

        // get the recipients and the missing clientsStrategy
        let (recipients, missingClientsStrategy) = self.recipients(
            for: message,
            selfUser: selfUser,
            in: conversation
        )

        // get the list of clients
        let clients = listOfClients(for: recipients, selfDomain: selfDomain, selfClientID: selfClientID)
        return MessageInfo(
            genericMessage: message,
            listClients: clients,
            missingClientsStrategy: missingClientsStrategy,
            selfClientID: selfClientID
        )
    }

    private func selfClientID() throws -> String {
        let selfClientID = ZMUser.selfUser(in: context).selfClient()?.remoteIdentifier
        guard let id = selfClientID else { throw MessageInfoExtractorError.missingValidSelfClient }
        return id
    }

    private func recipients(
        for message: GenericMessage,
        selfUser: ZMUser,
        in conversation: ZMConversation
    ) -> ([ZMUser: Set<UserClient>], MissingClientsStrategy) {
        message.recipientUsersForMessage(
            in: conversation,
            selfUser: selfUser
        )
    }

    private func listOfClients(
        for recipients: [ZMUser: Set<UserClient>],
        selfDomain: String,
        selfClientID: String
    ) -> MessageInfo.ClientList {

        let recipientsByDomain = Dictionary(grouping: recipients) { element -> String in
            element.key.domain ?? selfDomain
            // is there really a need to keep selfDomain as backup values
        }

        var qualifiedUserEntries = MessageInfo.ClientList()
        for (domain, recipients) in recipientsByDomain {

            var userEntries = [MessageInfo.UserID: [UserClientData]]()
            for (user, clients) in recipients {
                guard !user.isAccountDeleted, let userId = user.remoteIdentifier else { continue }

                let userClientDatas = userClientDatas(selfClientID: selfClientID, userClients: clients)
                if !userClientDatas.isEmpty {
                    userEntries[userId] = userClientDatas
                }
            }
            qualifiedUserEntries[domain] = userEntries
        }
        return qualifiedUserEntries
    }

    private func userClientDatas(selfClientID: String, userClients: Set<UserClient>) -> [UserClientData] {

        userClients.compactMap {
            guard let sessionID = $0.proteusSessionID,
                  $0.remoteIdentifier != selfClientID else {
                // skips self client session
                WireLogger.proteus
                    .warn(
                        "skips cliend id: \(String(describing: $0.remoteIdentifier)), proteusSession id: \(String(describing: $0.proteusSessionID))"
                    )
                return nil
            }

            guard !$0.failedToEstablishSession else {
                let data = ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8)!
                WireLogger.proteus
                    .error(
                        "Failed to encrypt payload: session couldn't be established with client: \(String(describing: $0.remoteIdentifier))"
                    )
                return UserClientData(sessionID: sessionID, data: data)
            }

            return UserClientData(sessionID: sessionID, data: nil)
        }
    }
}

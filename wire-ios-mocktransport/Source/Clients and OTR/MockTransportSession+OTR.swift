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

import WireProtos

extension MockTransportSession {
    @objc(missedClients:users:sender:onlyForUserId:)
    public func missedClients(
        _ recipients: [AnyHashable: Any]?,
        users: Set<MockUser>,
        sender: MockUserClient?,
        onlyForUserId: String?
    ) -> [AnyHashable: Any]? {
        var missedClients: [AnyHashable: Any] = [:]
        for user in users {
            if let onlyForUserId,
               UUID(transportString: user.identifier) != UUID(transportString: onlyForUserId) {
                continue
            }
            let recipientClients = (recipients?[user.identifier] as? [String: Any] ?? [:]).keys
            let clients: Set<MockUserClient> = user.userClients
            let userClients = clients
                .filter { $0 != sender }
                .compactMap(\.identifier)

            var userMissedClients = Set(userClients)
            userMissedClients.subtract(recipientClients)
            if userMissedClients.isEmpty == false {
                missedClients[user.identifier] = Array(userMissedClients)
            }
        }
        return missedClients
    }

    func otrMessageSender(fromClientId sender: Proteus_ClientId) -> MockUserClient? {
        let senderClientId = String(format: "%llx", CLongLong(sender.client))

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserClient")
        request.predicate = NSPredicate(format: "identifier == %@", senderClientId)
        return try! managedObjectContext.fetch(request).first as? MockUserClient
    }

    func missedClients(
        fromRecipients recipients: [Proteus_UserEntry],
        conversation: MockConversation,
        sender: MockUserClient,
        onlyForUserId: String?
    ) -> [String: [String]] {
        let users = conversation.activeUsers.set as! Set<MockUser>
        return missedClients(fromRecipients: recipients, users: users, sender: sender, onlyForUserId: onlyForUserId)
    }

    func missedClients(
        fromRecipients recipients: [Proteus_UserEntry],
        sender: MockUserClient,
        onlyForUserId: String?
    ) -> [String: [String]] {
        missedClients(
            fromRecipients: recipients,
            users: selfUser.connectionsAndTeamMembers,
            sender: sender,
            onlyForUserId: onlyForUserId
        )
    }

    /// Returns a list of missing clients in the conversation that were not included in the list of intendend recipients
    /// - Parameters:
    ///   - recipients: list of intended recipients
    ///   - users: list of users to get clients from
    ///   - sender: will be excluded from list
    ///   - onlyForUserId: if not nil, only return missing recipients matching this user ID
    /// - Returns: missing clients
    func missedClients(
        fromRecipients recipients: [Proteus_UserEntry],
        users: Set<MockUser>,
        sender: MockUserClient,
        onlyForUserId: String?
    ) -> [String: [String]] {
        var missedClients = [String: [String]]()

        for user in users {
            if let id = onlyForUserId, UUID(uuidString: user.identifier) != UUID(uuidString: id) {
                continue
            }

            let userEntry = recipients.first { recipient in
                guard
                    let uuid = UUID(data: recipient.user.uuid),
                    let userId = UUID(uuidString: user.identifier) else {
                    return false
                }
                return uuid == userId && (onlyForUserId == nil || UUID(uuidString: onlyForUserId!) == userId)
            }

            let recipientClients = userEntry?.clients.map { entry in
                String(format: "%llx", CUnsignedLongLong(entry.client.client))
            }

            var userClients: Set<String> = Set(user.userClients.compactMap { client in
                if client != sender {
                    return client.identifier
                }
                return nil
            })

            if let recipientClients {
                userClients.subtract(recipientClients)
            }

            if !userClients.isEmpty {
                missedClients[user.identifier] = Array(userClients)
            }
        }
        return missedClients
    }

    func deletedClients(
        fromRecipients recipients: [Proteus_UserEntry],
        conversation: MockConversation
    ) -> [String: [String]] {
        let users = conversation.activeUsers.set as! Set<MockUser>
        return deletedClients(fromRecipients: recipients, users: users)
    }

    func deletedClients(fromRecipients recipients: [Proteus_UserEntry]) -> [String: [String]] {
        deletedClients(fromRecipients: recipients, users: selfUser.connectionsAndTeamMembers)
    }

    /// Returns a list of deleted clients for broascasting that were included in the list of intendend recipients
    /// - Parameters:
    ///   - recipients: list of intended recipients
    ///   - users: set of users to get clients from
    /// - Returns: deleted clients
    func deletedClients(fromRecipients recipients: [Proteus_UserEntry], users: Set<MockUser>) -> [String: [String]] {
        var deletedClients = [String: [String]]()

        for user in users {
            guard let userEntry = recipients.first(where: { recipient in
                guard
                    let uuid = UUID(data: recipient.user.uuid),
                    let userId = UUID(uuidString: user.identifier) else {
                    return false
                }
                return uuid == userId
            }) else {
                continue
            }

            let recipientClients = userEntry.clients.map { entry in
                String(format: "%llx", CUnsignedLongLong(entry.client.client))
            }

            let userClients: Set<String> = Set(user.userClients.compactMap { client in
                client.identifier
            })

            var deletedUserClients = Set(recipientClients)
            deletedUserClients.subtract(userClients)

            if !deletedUserClients.isEmpty {
                deletedClients[user.identifier] = Array(deletedUserClients)
            }
        }

        return deletedClients
    }

    func insertOTRMessageEvents(
        toConversation conversation: MockConversation,
        recipients: [Proteus_UserEntry],
        senderClient: MockUserClient,
        createEventBlock: (MockUserClient, Data, Data) -> MockEvent
    ) {
        let activeUsers = conversation.activeUsers.array as? [MockUser]
        guard let activeClients = activeUsers?.flatMap({ user in
            user.userClients.compactMap(\.identifier)
        }) else {
            return
        }

        let allClientsRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserClient")
        allClientsRequest.predicate = NSPredicate(format: "identifier IN %@", activeClients)
        let allClients1 = try! managedObjectContext.fetch(allClientsRequest)
        let allClients = allClients1 as? [MockUserClient]

        let clientsEntries = recipients.flatMap(\.clients)

        for entry in clientsEntries {
            guard let client = allClients?.first(where: { client in
                let clientId = String(format: "%llx", CUnsignedLongLong(entry.client.client))
                return client.identifier == clientId
            }) else {
                return
            }

            let decryptedData = MockUserClient.decryptMessage(data: entry.text, from: senderClient, to: client)
            _ = createEventBlock(client, entry.text, decryptedData)
        }
    }
}

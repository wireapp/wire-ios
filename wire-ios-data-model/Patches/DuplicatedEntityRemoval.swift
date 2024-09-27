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

private let zmLog = ZMSLog(tag: "DuplicateEntity")

// MARK: - DuplicatedEntityRemoval

enum DuplicatedEntityRemoval {
    static func removeDuplicated(in moc: NSManagedObjectContext) {
        // will skip this during test unless on disk
        guard moc.persistentStoreCoordinator!.persistentStores.first!.type != NSInMemoryStoreType else {
            return
        }
        deleteDuplicatedClients(in: moc)
        moc.saveOrRollback()
    }

    static func deleteDuplicatedClients(in context: NSManagedObjectContext) {
        // Fetch clients having the same remote identifiers
        // swiftformat:disable:next preferForLoop
        context.findDuplicated(by: #keyPath(UserClient.remoteIdentifier)).forEach { (
            _: String?,
            clients: [UserClient]
        ) in
            // Group clients having the same remote identifiers by user
            clients.filter { !($0.user?.isSelfUser ?? true) }.group(by: ZMUserClientUserKey).forEach { (
                _: ZMUser,
                clients: [UserClient]
            ) in
                UserClient.merge(clients)
            }
        }
    }
}

extension UserClient {
    static func merge(_ clients: [UserClient]) {
        guard let firstClient = clients.first, let context = firstClient.managedObjectContext, clients.count > 1 else {
            return
        }
        let tail = clients.dropFirst()
        // Merge clients having the same remote identifier and same user

        for item in tail {
            firstClient.merge(with: item)
            context.delete(item)
        }
    }

    // Migration method for merging two duplicated @c UserClient entities
    func merge(with client: UserClient) {
        precondition(!(user?.isSelfUser ?? false), "Cannot merge self user's clients")
        precondition(
            client.remoteIdentifier == remoteIdentifier,
            "UserClient's remoteIdentifier should be equal to merge"
        )
        precondition(client.user == user, "UserClient's Users should be equal to merge")

        let addedOrRemovedInSystemMessages = client.addedOrRemovedInSystemMessages
        let ignoredByClients = client.ignoredByClients
        let messagesMissingRecipient = client.messagesMissingRecipient
        let trustedByClients = client.trustedByClients

        self.addedOrRemovedInSystemMessages.formUnion(addedOrRemovedInSystemMessages)
        self.ignoredByClients.formUnion(ignoredByClients)
        self.messagesMissingRecipient.formUnion(messagesMissingRecipient)
        self.trustedByClients.formUnion(trustedByClients)

        if let missedByClient = client.missedByClient {
            self.missedByClient = missedByClient
        }
    }
}

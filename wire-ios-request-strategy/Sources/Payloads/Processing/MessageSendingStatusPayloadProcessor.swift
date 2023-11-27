//
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

final class MessageSendingStatusPayloadProcessor {

    /// Updates the reported client changes after an attempt to send the message
    ///
    /// - Parameter message: message for which the message sending status was created
    /// - Returns reported missing clients
    ///
    /// If a message was missing clients we should attempt to send the message again
    /// after establishing sessions with the missing clients.

    @discardableResult
    func updateClientsChanges(
        from payload: Payload.MessageSendingStatus,
        for message: any ProteusMessage
    ) -> [ZMUser: [UserClient]] {
        WireLogger.messaging.debug("update client changes for message \(message.debugInfo)")

        let deletedClients = payload.deleted.fetchClients(in: message.context)

        if !deletedClients.isEmpty {
            WireLogger.messaging.debug("detected deleted clients")
        }

        for (_, deletedClients) in deletedClients {
            deletedClients.forEach { $0.deleteClientAndEndSession() }
        }

        let redundantUsers = payload.redundant.fetchUsers(in: message.context)
        if !redundantUsers.isEmpty {
            WireLogger.messaging.debug("detected redundant users")

            // if the BE tells us that these users are not in the
            // conversation anymore, it means that we are out of sync
            // with the list of participants
            message.conversation?.needsToBeUpdatedFromBackend = true

            // The missing users might have been deleted so we need re-fetch their profiles
            // to verify if that's the case.
            redundantUsers.forEach { $0.needsToBeUpdatedFromBackend = true }

            message.detectedRedundantUsers(redundantUsers)
        }

        let missingClients = payload.missing.fetchOrCreateClients(in: message.context)

        if !missingClients.isEmpty {
            WireLogger.messaging.debug("detected missing clients")
        }

        for (_, userClients) in missingClients {
            userClients.forEach({ $0.discoveredByMessage = message as? ZMOTRMessage })
            message.registersNewMissingClients(Set(userClients))
            message.conversation?.decreaseSecurityLevelIfNeededAfterDiscovering(clients: Set(userClients), causedBy: message as? ZMOTRMessage)
        }

        let failedToConfirmUsers = payload.failedToConfirm.fetchUsers(in: message.context)
        if !failedToConfirmUsers.isEmpty {
            message.addFailedToSendRecipients(failedToConfirmUsers)
        }

        return missingClients
    }

    func missingClientListByUser(
        from payload: Payload.MessageSendingStatus,
        context: NSManagedObjectContext
    ) -> Payload.ClientListByUser {
        let clientIDsByUser = payload.missing.flatMap { domain, clientIDsByUserID in
            materializingUsers(
                from: clientIDsByUserID,
                withDomain: domain,
                in: context
            )
        }

        return Payload.ClientListByUser(clientIDsByUser, uniquingKeysWith: +)
    }

    func materializingUsers(
        from clientsListByUserID: Payload.ClientListByUserID,
        withDomain domain: String?,
        in context: NSManagedObjectContext
    ) -> [ZMUser: Payload.ClientList] {
        return clientsListByUserID.reduce(into: Payload.ClientListByUser()) { result, next in
            guard let userID = UUID(uuidString: next.key) else {
                return
            }

            let user = ZMUser.fetchOrCreate(
                with: userID,
                domain: domain,
                in: context
            )

            result[user] = next.value
        }
    }

}

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

final class ConnectionPayloadProcessor {

    let resolver: OneOnOneResolverInterface?

    convenience init(context: NSManagedObjectContext) {
        self.init(resolver: OneOnOneResolver(syncContext: context))
    }

    init(resolver: OneOnOneResolverInterface?) {
        self.resolver = resolver
    }

    func processPayload(
        _ payload: Payload.UserConnectionEvent,
        in context: NSManagedObjectContext
    ) {
        updateOrCreateConnection(
            from: payload.connection,
            in: context
        )
    }

    func updateOrCreateConnection(
        from payload: Payload.Connection,
        in context: NSManagedObjectContext,
        delay: TimeInterval = 3
    ) {
        guard let userID = payload.to ?? payload.qualifiedTo?.uuid else {
            Logging.eventProcessing.error("Missing to field in connection payload, aborting...")
            return
        }

        let connection = ZMConnection.fetchOrCreate(
            userID: userID,
            domain: payload.qualifiedTo?.domain,
            in: context
        )

        guard let conversationID = payload.conversationID ?? payload.qualifiedConversationID?.uuid else {
            Logging.eventProcessing.error("Missing conversation field in connection payload, aborting...")
            return
        }

        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: payload.qualifiedConversationID?.domain,
            in: context
        )

        conversation.needsToBeUpdatedFromBackend = true
        conversation.lastModifiedDate = payload.lastUpdate
        conversation.addParticipantAndUpdateConversationState(user: connection.to, role: nil)

        let previousStatus = connection.status

        connection.conversation = conversation
        connection.status = payload.status.internalStatus

        let threeSecDelay: TimeInterval = delay

        if previousStatus == .pending, connection.status == .accepted {
            WaitingGroupTask(context: context) {
                try? await Task.sleep(nanoseconds: UInt64(threeSecDelay))
                if let resolver = self.resolver,
                   let qualifiedTo = payload.qualifiedTo {
                    do {
                        try await resolver.resolveOneOnOneConversation(with: qualifiedTo, in: context)

                    } catch {
                        assertionFailure("Error resolving one-on-one conversation: \(error)")
                    }
                } else {
                    assertionFailure("OneOnOneResolver initialization failed")
                }
            }
        }

        connection.lastUpdateDateInGMT = payload.lastUpdate
    }

}

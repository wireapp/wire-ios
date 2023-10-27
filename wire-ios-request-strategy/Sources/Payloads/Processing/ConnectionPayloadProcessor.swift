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
        in context: NSManagedObjectContext
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

        connection.conversation = conversation
        connection.lastUpdateDateInGMT = payload.lastUpdate

        let previousConnectionStatus = connection.status
        connection.status = payload.status.internalStatus
        let newConnectionStatus = connection.status

        if 
            previousConnectionStatus != .accepted && newConnectionStatus == .accepted,
            let otherUser = connection.to
        {
            let selfUser = ZMUser.selfUser(in: context)
            let commonProtocols = selfUser.supportedProtocols.intersection(otherUser.supportedProtocols)

            if commonProtocols.contains(.mls) {
                // establsh mls group
                if conversation.mlsGroupID == nil {
                    // fetch it via GET /conversations/one2one/{userdomain}/{userId} (persists other meta data too)
                }

                // check with cc if group already exists, if yes, done.
                // in mls service...
                // claim key packages for other user
                // create group
                // add client to group
                fatalError("not implemented")
            } else if commonProtocols.contains(.proteus) {
                // nothing more to do
            } else {
                conversation.isForcedReadOnly = true
            }
        }
    }

}

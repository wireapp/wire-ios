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
import WireLogging

final class ConnectionPayloadProcessor {

    private let isFederationEnabled: Bool

    init(isFederationEnabled: Bool) {
        self.isFederationEnabled = isFederationEnabled
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
        in context: NSManagedObjectContext
    ) {
        guard let userID = payload.to ?? payload.qualifiedTo?.uuid else {
            WireLogger.eventProcessing.error("Missing to field in connection payload, aborting...")
            return
        }

        let connection = ZMConnection.fetchOrCreate(
            userID: userID,
            domain: payload.qualifiedTo?.domain,
            in: context
        )

        guard let conversationID = payload.conversationID ?? payload.qualifiedConversationID?.uuid else {
            WireLogger.eventProcessing.error("Missing conversation field in connection payload, aborting...")
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

        // `ConnectionValidator` cleans up stale connections between users, so we normally (re)set this link here.
        // But when the two users already have an established MLS conversation, we keep it: overwriting it with the
        // Proteus connection conversation would break the link and hide the conversation from the list.
        //
        // `migratedToMLS` is only set on the proteus→MLS migration path, so it misses MLS one-on-ones that were
        // established directly. Relying on it alone lets the proteus connection conversation overwrite the MLS
        // link, which surfaces the proteus (read-only) conversation instead of the MLS one — including on the
        // side of a user who was blocked, since that side is never notified and should keep messaging. [WPB-24403]
        let existing = connection.to.oneOnOneConversation
        let isEstablishedMLS = existing?.messageProtocol == .mls
            && (existing?.mlsStatus == .ready || existing?.migratedToMLS == true)
        if !isEstablishedMLS {
            connection.to.oneOnOneConversation = conversation
        }
        connection.status = payload.status.internalStatus
        connection.lastUpdateDateInGMT = payload.lastUpdate
    }

}

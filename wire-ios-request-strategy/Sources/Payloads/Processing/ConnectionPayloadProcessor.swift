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

        // Don't clobber an existing MLS 1:1 link with the Proteus conversation reference
        // carried by the connection payload. After MLS migration the user's 1:1 is the
        // MLS conversation; the Proteus conversation is retained only for legacy reasons.
        // Overwriting the link on every connection update (block/unblock in particular)
        // causes the conversation list to flip between the two rows and can briefly hide
        // the conversation entirely. [WPB-24403]
        // The conversation we link here may be wrong and may need to be unset using `ConnectionValidator`.
        let existing = connection.to.oneOnOneConversation
        if existing?.messageProtocol != .mls || existing?.migratedToMLS != true {
            connection.to.oneOnOneConversation = conversation
        }
        connection.status = payload.status.internalStatus
        connection.lastUpdateDateInGMT = payload.lastUpdate
    }

}

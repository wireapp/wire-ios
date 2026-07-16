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

        let previousConversationID = connection.to.oneOnOneConversation?.remoteIdentifier
        let previousConversationDomain = connection.to.oneOnOneConversation?.domain
        var didCreateConversation = false
        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: payload.qualifiedConversationID?.domain,
            in: context,
            created: &didCreateConversation
        )
        // TEMP DEBUG [WPB-24403 duplicate-user]: confirm whether the backend sends a different
        // conversation id on connection status changes (e.g. block/unblock).
        WireLogger.eventProcessing.warn(
            "[legacy] updateOrCreateConnection status=\(payload.status) userID=\(userID) userDomain=\(payload.qualifiedTo?.domain ?? "nil") conversationID=\(conversationID) conversationDomain=\(payload.qualifiedConversationID?.domain ?? "nil") previousConversationID=\(previousConversationID?.uuidString ?? "nil") previousConversationDomain=\(previousConversationDomain ?? "nil") didCreateConversation=\(didCreateConversation)"
        )

        conversation.needsToBeUpdatedFromBackend = true
        conversation.lastModifiedDate = payload.lastUpdate
        conversation.addParticipantAndUpdateConversationState(user: connection.to, role: nil)

        // The conversation we link here may be wrong and may need to be unset using `ConnectionValidator`.
        connection.to.oneOnOneConversation = conversation
        connection.status = payload.status.internalStatus
        connection.lastUpdateDateInGMT = payload.lastUpdate
    }

}

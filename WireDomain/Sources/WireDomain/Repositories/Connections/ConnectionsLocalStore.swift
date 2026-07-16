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

import WireDataModel
import WireLogging

final class ConnectionsLocalStore: ConnectionsLocalStoreProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let isFederationEnabled: Bool

    // MARK: - Object lifecycle

    init(
        context: NSManagedObjectContext,
        isFederationEnabled: Bool
    ) {
        self.context = context
        self.isFederationEnabled = isFederationEnabled
    }

    // MARK: - Public

    public func storeConnection(_ connectionInfo: ConnectionInfo) async throws {
        try await context.perform { [self] in

            let connection = try storedConnection(from: connectionInfo)

            let previousConversationID = connection.to.oneOnOneConversation?.remoteIdentifier
            let previousConversationDomain = connection.to.oneOnOneConversation?.domain
            let (conversation, didCreateConversation) = try storedConversation(from: connectionInfo, with: connection)
            // TEMP DEBUG [WPB-24403 duplicate-user]: confirm whether the backend sends a different
            // conversation id on connection status changes (e.g. block/unblock).
            WireLogger.eventProcessing.warn(
                "[domain] storeConnection status=\(connectionInfo.status) userID=\((connectionInfo.receiverID ?? connectionInfo.receiverQualifiedID?.uuid)?.uuidString ?? "nil") userDomain=\(connectionInfo.receiverQualifiedID?.domain ?? "nil") conversationID=\(conversation.remoteIdentifier?.uuidString ?? "nil") conversationDomain=\(connectionInfo.qualifiedConversationID?.domain ?? "nil") previousConversationID=\(previousConversationID?.uuidString ?? "nil") previousConversationDomain=\(previousConversationDomain ?? "nil") didCreateConversation=\(didCreateConversation)"
            )

            conversation.needsToBeUpdatedFromBackend = false
            conversation.lastModifiedDate = connectionInfo.lastUpdate
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
            connection.status = connectionInfo.status
            connection.lastUpdateDateInGMT = connectionInfo.lastUpdate

            try context.save()
        }
    }

    public func markConversationAsNeedUpdatedFromBackend(_ connectionInfo: ConnectionInfo) async throws {
        guard let conversationID = connectionInfo.qualifiedConversationID else {
            throw ConnectionsRepositoryError.missingConversationId
        }

        try await context.perform { [context] in
            let conversation = ZMConversation.fetch(
                with: conversationID.uuid,
                domain: conversationID.domain,
                in: context
            )
            conversation?.needsToBeUpdatedFromBackend = true

            try context.save()
        }
    }

    /// Create or update conversation related to the connection's sender
    /// - Parameters:
    ///   - connection: connection payload from WireNetwork
    ///   - storedConnection: ZMConnection object stored locally
    /// - Returns: conversation object stored locally

    private func storedConversation(
        from connection: ConnectionInfo,
        with storedConnection: ZMConnection
    ) throws -> (ZMConversation, created: Bool) {
        guard let conversationID = connection.conversationID ?? connection.qualifiedConversationID?.uuid else {
            throw ConnectionsRepositoryError.missingConversationId
        }

        var created = false
        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: connection.qualifiedConversationID?.domain,
            in: context,
            created: &created
        )
        return (conversation, created)
    }

    /// Create or update  connection locally related to the connection's sender
    /// - Parameter connection: connection payload from WireNetwork
    /// - Returns: connection object stored locally

    private func storedConnection(
        from connection: ConnectionInfo
    ) throws -> ZMConnection {
        guard let userID = connection.receiverID ?? connection.receiverQualifiedID?.uuid else {
            throw ConnectionsRepositoryError.missingReceiverId
        }

        return ZMConnection.fetchOrCreate(
            userID: userID,
            domain: connection.receiverQualifiedID?.domain,
            in: context
        )
    }
}

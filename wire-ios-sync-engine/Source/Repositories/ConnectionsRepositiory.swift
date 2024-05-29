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
import WireAPI
import WireDataModel

/// Facilitate access to connections related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
protocol ConnectionsRepositoryProtocol {

    /// Pull self team metadata frmo the server and store locally.

    func pullConnections() async throws
}

final class ConnectionsRepository: ConnectionsRepositoryProtocol {

    private let connectionsAPI: any ConnectionsAPI
    private let context: NSManagedObjectContext

    init(
        connectionsAPI: any ConnectionsAPI,
        context: NSManagedObjectContext
    ) {
        self.connectionsAPI = connectionsAPI
        self.context = context
    }

    public func pullConnections() async throws {
        let connectionsPager = try await connectionsAPI.getConnections()

        for try await connections in connectionsPager {
            await withThrowingTaskGroup(of: Void.self) { taskGroup in
                for connection in connections {
                    taskGroup.addTask {
                        try await self.storeConnection(connection)
                    }
                }
            }
        }
    }

    private func storeConnection(_ connection: Connection) async throws {
        try await context.perform { [self] in

            guard let userID = connection.receiverId ?? connection.receiverQualifiedId?.uuid else {
                throw ConnectionsRepositoryError.missingReceiverId
            }

            let storedConnection = ZMConnection.fetchOrCreate(
                userID: userID,
                domain: connection.receiverQualifiedId?.domain,
                in: context
            )

            guard let conversationID = connection.conversationId ?? connection.qualifiedConversationId?.uuid else {
                throw ConnectionsRepositoryError.missingConversationId
            }

            let conversation = ZMConversation.fetchOrCreate(
                with: conversationID,
                domain: connection.qualifiedConversationId?.domain,
                in: context
            )

            conversation.needsToBeUpdatedFromBackend = true
            conversation.lastModifiedDate = connection.lastUpdate
            conversation.addParticipantAndUpdateConversationState(user: storedConnection.to, role: nil)

            storedConnection.to.oneOnOneConversation = conversation
            storedConnection.status = status(from: connection.status)
            storedConnection.lastUpdateDateInGMT = connection.lastUpdate

            try context.save()
        }
    }

    private func status(from connectionStatus: ConnectionStatus) -> ZMConnectionStatus {
        switch connectionStatus {
        case .sent:
            return .sent
        case .accepted:
            return .accepted
        case .pending:
            return .pending
        case .blocked:
            return .blocked
        case .cancelled:
            return .cancelled
        case .ignored:
            return .ignored
        case .missingLegalholdConsent:
            return .blockedMissingLegalholdConsent
        }
    }
}

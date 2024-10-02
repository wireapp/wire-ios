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

// sourcery: AutoMockable
/// Facilitate access to connections related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol ConnectionsRepositoryProtocol {

    /// Pull self team metadata from the server and store locally.

    func pullConnections() async throws

    /// Updates a connection locally.
    ///
    /// - parameters:
    ///     - connection: The connection to update.

    func updateConnection(
        _ connection: Connection
    ) async throws
}

struct ConnectionsRepository: ConnectionsRepositoryProtocol {

    private let connectionsAPI: any ConnectionsAPI
    private let context: NSManagedObjectContext

    init(
        connectionsAPI: any ConnectionsAPI,
        context: NSManagedObjectContext
    ) {
        self.connectionsAPI = connectionsAPI
        self.context = context
    }

    /// Retrieve from backend and store connections locally

    public func pullConnections() async throws {
        let connectionsPager = try await connectionsAPI.getConnections()

        for try await connections in connectionsPager {
            await withThrowingTaskGroup(of: Void.self) { taskGroup in
                for connection in connections {
                    taskGroup.addTask {
                        try await storeConnection(connection)
                    }
                }
            }
        }
    }

    func updateConnection(
        _ connection: Connection
    ) async throws {
        try await storeConnection(connection)
    }

    /// Save connection and related objects to local storage.
    /// - Parameter connectionPayload: connection object from WireAPI

    private func storeConnection(_ connectionPayload: Connection) async throws {
        try await context.perform { [self] in

            let connection = try storedConnection(from: connectionPayload)

            let conversation = try storedConversation(from: connectionPayload, with: connection)

            connection.to.oneOnOneConversation = conversation

            try context.save()
        }
    }

    /// Create or update conversation related to the connection's sender
    /// - Parameters:
    ///   - connection: connection payload from WireAPI
    ///   - storedConnection: ZMConnection object stored locally
    /// - Returns: conversation object stored locally

    private func storedConversation(from connection: Connection, with storedConnection: ZMConnection) throws -> ZMConversation {
        guard let conversationID = connection.conversationID ?? connection.qualifiedConversationID?.uuid else {
            throw ConnectionsRepositoryError.missingConversationId
        }

        let conversation = ZMConversation.fetchOrCreate(
            with: conversationID,
            domain: connection.qualifiedConversationID?.domain,
            in: context
        )

        conversation.needsToBeUpdatedFromBackend = true
        conversation.lastModifiedDate = connection.lastUpdate
        conversation.addParticipantAndUpdateConversationState(user: storedConnection.to, role: nil)
        return conversation
    }

    /// Create or update  connection locally related to the connection's sender
    /// - Parameter connection: connection payload from WireAPI
    /// - Returns: connection object stored locally

    private func storedConnection(from connection: Connection) throws -> ZMConnection {
        guard let userID = connection.receiverID ?? connection.receiverQualifiedID?.uuid else {
            throw ConnectionsRepositoryError.missingReceiverId
        }

        let storedConnection = ZMConnection.fetchOrCreate(
            userID: userID,
            domain: connection.receiverQualifiedID?.domain,
            in: context
        )

        storedConnection.status = connection.status.toDomainModel()
        storedConnection.lastUpdateDateInGMT = connection.lastUpdate
        return storedConnection
    }
}

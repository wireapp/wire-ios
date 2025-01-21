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

import CoreData

// TODO: Run on launch all connections - user session setup
// TODO: During event processing - targeted (user.update)

/// An object responsible for correcting invalid state regarding
/// user connections.

public class ConnectionValidator {

    struct SearchResult {
        let invalidConnections: [NSManagedObjectID]
        let connectionsToCancel: [NSManagedObjectID]
        let connectionsToIgnore: [NSManagedObjectID]

        init(
            invalidConnections: [NSManagedObjectID] = [],
            connectionsToCancel: [NSManagedObjectID] = [],
            connectionsToIgnore: [NSManagedObjectID] = []
        ) {
            self.invalidConnections = invalidConnections
            self.connectionsToCancel = connectionsToCancel
            self.connectionsToIgnore = connectionsToIgnore
        }
    }

    public enum Failure: Error {

        case userNotFound

    }

    private let context: NSManagedObjectContext

    /// Create a new `ConnectionValidator`.

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Clean up all invalid connections.
    ///
    /// Invoking this method will search the local database for invalid
    /// invalid connections and reject them all. As a result, only valid
    /// connections will remain in the database.
    ///
    /// A connection is considered invalid if it is pending (i.e not accepted,
    /// not blocked) and between the self user and a fellow team member. This
    /// can happen if the a pending connection exists between the self user
    /// and another user while both users are not in the same team, but then
    /// later become part of the same team (e.g via invitation). Already
    /// established connections with users that later become team members are
    /// honored, and any new communciation with team members are via implicit
    /// team connections.

    public func cleanUpAllInvalidConnections() async throws {
        let teamID = await context.perform { [context] in
            ZMUser.selfUser(in: context).teamIdentifier
        }

        // If there's no self team, all connections are consider
        // valid.
        guard let teamID else {
            return
        }

        // Fetch ids of invalid connections.
        let searchResult = try await context.perform { [context] in
            let fetchRequest = NSFetchRequest<ZMConnection>(entityName: ZMConnection.entityName())
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "NOT (status IN %@)", Self.keepConnectionStatuses().map(\.rawValue)),
                NSPredicate(format: "to.teamIdentifier_data == %@", teamID.uuidData as NSData) // TODO: Do we need to check `to` is not nil?
            ])

            let connections = try context.fetch(fetchRequest)
            var invalidConnections: [NSManagedObjectID] = []
            var connectionsToCancel: [NSManagedObjectID] = []
            var connectionsToIgnore: [NSManagedObjectID] = []

            for invalidConnection in connections {
                invalidConnections.append(invalidConnection.objectID)
                switch invalidConnection.status {
                case .pending:
                    connectionsToIgnore.append(invalidConnection.objectID)
                case .sent:
                    connectionsToCancel.append(invalidConnection.objectID)
                default:
                    // TODO: Consider blocked for legal hold?
                    break
                }
            }

            return SearchResult(
                invalidConnections: invalidConnections,
                connectionsToCancel: connectionsToCancel,
                connectionsToIgnore: connectionsToIgnore
            )
        }

        try await cleanUpState(for: searchResult)
    }


    /// Clean up the invalid connection to the given user if needed.
    ///
    /// - Parameter userObjectID: An object id to another user.

    public func cleanUpInvalidConnectionIfNeeded(userObjectID: NSManagedObjectID) async throws {
        let searchResult = try await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)

            // If there is no team, there are no invalid connections.
            guard let teamID = selfUser.teamIdentifier else {
                return SearchResult()
            }

            guard let user = try context.existingObject(with: userObjectID) as? ZMUser else {
                throw Failure.userNotFound
            }

            // Ensure this is an invalid connection.
            guard
                user.teamIdentifier == teamID,
                let connection = user.connection,
                !connection.status.isOne(of: .accepted, .blocked)
            else {
                return SearchResult()
            }

            var invalidConnections = [connection.objectID]
            var connectionsToCancel: [NSManagedObjectID] = []
            var connectionsToIgnore: [NSManagedObjectID] = []

            switch connection.status {
            case .sent:
                connectionsToCancel = [connection.objectID]
            case .pending:
                connectionsToIgnore = [connection.objectID]
            default:
                // TODO: Consider blocked for legal hold?
                break
            }

            return SearchResult(
                invalidConnections: invalidConnections,
                connectionsToCancel: connectionsToCancel,
                connectionsToIgnore: connectionsToIgnore
            )
        }

        try await cleanUpState(for: searchResult)
    }

    private func cleanUpState(for searchResult: SearchResult) async throws {
        // Cancel outgoing connections.
        for connectionID in searchResult.connectionsToCancel {
            try await updateConnectionStatus(
                connectionID: connectionID,
                newStatus: .cancelled,
                context: context
            )
        }

        // Ignore incoming connections.
        for connectionID in searchResult.connectionsToIgnore {
            try await updateConnectionStatus(
                connectionID: connectionID,
                newStatus: .ignored,
                context: context
            )
        }

        // Invalidate and unlink the associated conversation.
        try await context.perform { [context] in
            let connections = try searchResult.invalidConnections.map {
                try context.existingObject(with: $0) as! ZMConnection
            }

            for connection in connections {
                guard let existinOneOnOne = connection.to?.oneOnOneConversation else {
                    continue
                }

                // We also check for `invalid` because rejecting the connection may change
                // the conversation type to invalid.
                guard existinOneOnOne.conversationType.isOne(of: .invalid, .connection) else {
                    continue
                }

                existinOneOnOne.conversationType = .invalid
                existinOneOnOne.oneOnOneUser = nil
            }

            try context.save()
        }
    }

    static private func keepConnectionStatuses() -> [ZMConnectionStatus] {
        [.accepted, .blocked]
    }

    private func updateConnectionStatus(
        connectionID: NSManagedObjectID,
        newStatus: ZMConnectionStatus,
        context: NSManagedObjectContext
    ) async throws {
        var action = UpdateConnectionAction(connectionID: connectionID, newStatus: newStatus)
        try await action.perform(in: context.notificationContext)
    }

}

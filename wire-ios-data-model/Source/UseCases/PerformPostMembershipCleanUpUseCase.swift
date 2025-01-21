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
    }

    private let context: NSManagedObjectContext

    /// Create a new `ConnectionValidator`.

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Reject invalid connections.
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

    public func rejectInvalidConnections() async throws {
        let teamID = await context.perform { [context] in
            ZMUser.selfUser(in: context).teamIdentifier
        }

        // If there's no self team, all connections are consider
        // valid.
        guard let teamID else {
            return
        }

        // Fetch ids of invalid connections.
        let connectionIDs = try await context.perform { [context] in
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
                default: // TODO: Consider blocked for legal hold?
                    break
                }
            }

            return SearchResult(
                invalidConnections: invalidConnections,
                connectionsToCancel: connectionsToCancel,
                connectionsToIgnore: connectionsToIgnore
            )
        }

        // Cancel outgoing connections.
        for connectionID in connectionIDs.connectionsToCancel {
            try await updateConnectionStatus(
                connectionID: connectionID,
                newStatus: .cancelled,
                context: context
            )
        }

        // Ignore incoming connections.
        for connectionID in connectionIDs.connectionsToIgnore {
            try await updateConnectionStatus(
                connectionID: connectionID,
                newStatus: .ignored,
                context: context
            )
        }

        // Invalidate and unlink the associated conversation.
        try await context.perform { [context] in
            let connections = try connectionIDs.invalidConnections.map {
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

public class PerformPostMembershipCleanUpUseCase {

    public enum Failure: Swift.Error, Equatable {
        case userNotFound
    }

    private let context: NSManagedObjectContext
    private let userID: NSManagedObjectID?

    public init(
        context: NSManagedObjectContext,
        userID: NSManagedObjectID?
    ) {
        self.context = context
        self.userID = userID
    }

    public func invoke() async throws {
        return

        try await context.perform { [self] in
            try internalInvoke()
        }
    }

    public func invoke() throws {
        return

        try context.performAndWait { [self] in
            try internalInvoke()
        }
    }

    // MARK: - Private

    private func keepConnectionStatuses() -> [ZMConnectionStatus] {
        [.accepted, .blocked]
    }

    private func internalInvoke() throws {
        guard let teamID = ZMUser.selfUser(in: context).teamIdentifier else { return }

        if let userID {
            try invokeForSingleUser(userID: userID, selfUserTeamID: teamID)
        } else {
            try invokeForAllUsers(selfUserTeamID: teamID)
        }

        try context.save()
    }

    private func invokeForSingleUser(userID: NSManagedObjectID, selfUserTeamID: UUID) throws {
        guard let user = try context.existingObject(with: userID) as? ZMUser else {
            throw Failure.userNotFound
        }

        if user.isSelfUser {
            try invokeForAllUsers(selfUserTeamID: selfUserTeamID)
        } else if let connection = user.connection, !keepConnectionStatuses().contains(connection.status) {
            try removeConnections([connection], withTeamID: selfUserTeamID)
        }
    }

    private func invokeForAllUsers(selfUserTeamID: UUID) throws {
        try removeSameTeamConnections(selfUserTeamID: selfUserTeamID)
        try createMissingMemberships(selfUserTeamID: selfUserTeamID)
    }

    private func removeSameTeamConnections(selfUserTeamID: UUID) throws {
        let fetchRequest = NSFetchRequest<ZMConnection>(entityName: ZMConnection.entityName())
        fetchRequest.predicate = NSPredicate(format: "NOT (status IN %@)", keepConnectionStatuses().map(\.rawValue))

        let connections = try context.fetch(fetchRequest)
        try removeConnections(connections, withTeamID: selfUserTeamID)
    }

    private func removeConnections(_ connections: [ZMConnection], withTeamID teamID: UUID) throws {
        let removeConversationTypes: [ZMConversationType] = [.invalid, .connection]
        for connection in connections where connection.to.teamIdentifier == teamID {
            if
                let conversation = connection.to.oneOnOneConversation,
                removeConversationTypes.contains(conversation.conversationType) {
                context.delete(conversation)
            }
            context.delete(connection)
        }
    }

    /// Creates `ZMMemberships` for users which belong to `selfUsers` team but have no membership.
    private func createMissingMemberships(selfUserTeamID: UUID) throws {
        let fetchRequest = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
        fetchRequest.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                NSPredicate(format: "membership == nil"),
                NSPredicate(format: "teamIdentifier_data != nil"),
                NSPredicate(format: "isAccountDeleted == NO") // Avoid a loop of creating / deleting memberships
            ]
        )

        let users = try context.fetch(fetchRequest)
        for user in users where user.teamIdentifier == selfUserTeamID {
            user.createOrDeleteMembershipIfBelongingToTeam()
        }
    }
}

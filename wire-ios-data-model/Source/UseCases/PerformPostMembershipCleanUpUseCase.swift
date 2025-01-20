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

/// Searches and corrects invalid connections in the database.

// Run on launch all connections - user session setup
// During event processing - targeted (user.update)
public class ConnectionValidator {

    struct SearchResult {
        let invalidConnections: [NSManagedObjectID]
        let connectionsToCancel: [NSManagedObjectID]
        let connectionsToIgnore: [NSManagedObjectID]
    }

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func run() async throws {
        let teamID = await context.perform { [context] in
            ZMUser.selfUser(in: context).teamIdentifier
        }

        guard let teamID else { return }

        let connectionIDs = try await context.perform { [context] in
            let fetchRequest = NSFetchRequest<ZMConnection>(entityName: ZMConnection.entityName())
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "NOT (status IN %@)", Self.keepConnectionStatuses().map(\.rawValue)),
                NSPredicate(format: "to.teamIdentifier_data == %@", teamID.uuidData as NSData) // Do we need to check `to` is not nil?
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



        for connectionID in connectionIDs.connectionsToCancel {
            try await Self.updateConnectionStatus(connectionID: connectionID, newStatus: .cancelled, context: context)
        }

        for connectionID in connectionIDs.connectionsToIgnore {
            try await Self.updateConnectionStatus(connectionID: connectionID, newStatus: .ignored, context: context)
        }

        try await context.perform { [context] in
            let connections = try connectionIDs.invalidConnections.map { try context.existingObject(with: $0) as! ZMConnection }
            for connection in connections {
                if connection.to?.oneOnOneConversation?.conversationType.isOne(of: .invalid, .connection) == true {
                    connection.to?.oneOnOneConversation?.conversationType = .invalid
                    connection.to?.oneOnOneConversation = nil
                }
            }

            try context.save()
        }



        // find invalid connections
        // - search for pending connections
        // - checking user
        // - are they part of same team
        // - If they are then considered invalid
        // - result is array

        // correct invalid connection
        // for each invalid connection
        // reject (cancel or ignore)

        // Deal with 1 on 1
        // If there is 1 on 1 conversation and type connection we should mark as invalid and unlink

        // Leave conversation fixing to 1 on 1 resolver
    }

    static private func keepConnectionStatuses() -> [ZMConnectionStatus] {
        [.accepted, .blocked]
    }

    static private func updateConnectionStatus(
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

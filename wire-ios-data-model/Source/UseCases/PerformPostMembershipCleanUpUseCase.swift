//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

public class PerformPostMembershipCleanUpUseCase {

    enum Failure: Swift.Error {
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
        try await context.perform { [self] in
            try internalInvoke()
        }
    }

    public func invoke() throws {
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

        if let userID = userID {
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
        let keepStatuses: [ZMConnectionStatus] = [.accepted, .blocked]
        let fetchRequest = NSFetchRequest<ZMConnection>(entityName: ZMConnection.entityName())
        fetchRequest.predicate = NSPredicate(format: "NOT (status IN %@)", keepStatuses.map { $0.rawValue })

        let connections = try context.fetch(fetchRequest)
        try removeConnections(connections, withTeamID: selfUserTeamID)
    }

    private func removeConnections(_ connections: [ZMConnection], withTeamID teamID: UUID) throws {
        let removeConversationTypes: [ZMConversationType] = [.invalid, .connection]
        for connection in connections where connection.to.teamIdentifier == teamID {
            if
                let conversation = connection.to.oneOnOneConversation,
                removeConversationTypes.contains(conversation.conversationType)  {
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
                NSPredicate(format: "isAccountDeleted == NO"), // Avoid a loop of creating / deleting memberships
            ]
        )

        let users = try context.fetch(fetchRequest)
        for user in users where user.teamIdentifier == selfUserTeamID {
            user.createOrDeleteMembershipIfBelongingToTeam()
        }
    }
}

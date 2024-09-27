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

// MARK: - TeamOrConversation

public enum TeamOrConversation {
    case team(Team)
    case conversation(ZMConversation)

    // MARK: Public

    /// Creates a team if the conversation belongs to a team, or a conversation otherwise
    public static func matching(_ conversation: ZMConversation) -> TeamOrConversation {
        fromTeamOrConversation(team: conversation.team, conversation: conversation)
    }

    // MARK: Internal

    /// Creates a team or a conversation
    static func fromTeamOrConversation(
        team: Team?,
        conversation: ZMConversation?
    ) -> TeamOrConversation {
        if let team {
            return .team(team)

        } else if let conversation {
            return .conversation(conversation)
        }
        fatal("No team and no conversation")
    }
}

// MARK: - Role

@objcMembers
public final class Role: ZMManagedObject {
    // MARK: Public

    public static let nameKey = #keyPath(Role.name)
    public static let teamKey = #keyPath(Role.team)
    public static let conversationKey = #keyPath(Role.conversation)
    public static let actionsKey = #keyPath(Role.actions)
    public static let participantRolesKey = #keyPath(Role.participantRoles)

    @NSManaged public var name: String?

    @NSManaged public var actions: Set<Action>
    @NSManaged public var participantRoles: Set<ParticipantRole>
    @NSManaged public var team: Team?
    @NSManaged public var conversation: ZMConversation?

    override public static func entityName() -> String {
        String(describing: Role.self)
    }

    override public static func isTrackingLocalModifications() -> Bool {
        false
    }

    @discardableResult
    public static func create(
        managedObjectContext: NSManagedObjectContext,
        name: String,
        conversation: ZMConversation
    ) -> Role {
        create(
            managedObjectContext: managedObjectContext,
            name: name,
            teamOrConversation: .conversation(conversation)
        )
    }

    @discardableResult
    public static func create(
        managedObjectContext: NSManagedObjectContext,
        name: String,
        team: Team
    ) -> Role {
        create(
            managedObjectContext: managedObjectContext,
            name: name,
            teamOrConversation: .team(team)
        )
    }

    public static func create(
        managedObjectContext: NSManagedObjectContext,
        name: String,
        teamOrConversation: TeamOrConversation
    ) -> Role {
        let entry = Role.insertNewObject(in: managedObjectContext)
        entry.name = name
        switch teamOrConversation {
        case let .team(team):
            entry.team = team
        case let .conversation(conversation):
            entry.conversation = conversation
        }
        return entry
    }

    public static func fetchOrCreateRole(
        with name: String,
        teamOrConversation: TeamOrConversation,
        in context: NSManagedObjectContext
    ) -> Role {
        let existingRole = fetchExistingRole(
            with: name,
            teamOrConversation: teamOrConversation,
            in: context
        )
        return existingRole ?? create(managedObjectContext: context, name: name, teamOrConversation: teamOrConversation)
    }

    public static func fetchOrCreate(
        name: String,
        teamOrConversation: TeamOrConversation,
        context: NSManagedObjectContext
    ) -> Role {
        if let role = fetchExistingRole(
            with: name,
            teamOrConversation: teamOrConversation,
            in: context
        ) {
            return role
        }

        return Role.insertNewObject(in: context)
    }

    @discardableResult
    public static func createOrUpdate(
        with payload: [String: Any],
        teamOrConversation: TeamOrConversation,
        context: NSManagedObjectContext
    ) -> Role? {
        guard let conversationRole = payload["conversation_role"] as? String,
              let actionNames = payload["actions"] as? [String]
        else {
            return nil
        }

        let fetchedRole = fetchExistingRole(
            with: conversationRole,
            teamOrConversation: teamOrConversation,
            in: context
        )

        let role = fetchedRole ?? Role.insertNewObject(in: context)

        for actionName in actionNames {
            let action = Action.fetchOrCreate(
                name: actionName,
                in: context
            )

            role.actions.insert(action)
        }

        switch teamOrConversation {
        case let .team(team):
            role.team = team
        case let .conversation(conversation):
            role.conversation = conversation
        }
        role.name = conversationRole

        return role
    }

    // MARK: Internal

    static func fetchExistingRole(
        with name: String,
        teamOrConversation: TeamOrConversation,
        in context: NSManagedObjectContext
    ) -> Role? {
        let fetchRequest = NSFetchRequest<Role>(entityName: Role.entityName())
        let namePredicate = NSPredicate(format: "%K == %@", Role.nameKey, name)
        let teamOrConvoPredicate = switch teamOrConversation {
        case let .team(team):
            NSPredicate(format: "%K == %@", Role.teamKey, team)
        case let .conversation(convo):
            NSPredicate(format: "%K == %@", Role.conversationKey, convo)
        }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            namePredicate,
            teamOrConvoPredicate,
        ])
        fetchRequest.fetchLimit = 1

        return context.fetchOrAssert(request: fetchRequest).first
    }
}

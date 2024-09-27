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
import Foundation

// MARK: - MockRole

@objc
public final class MockRole: NSManagedObject, EntityNamedProtocol {
    public static let nameKey = #keyPath(MockRole.name)
    public static let teamKey = #keyPath(MockRole.team)
    public static let conversationKey = #keyPath(MockRole.conversation)

    @objc public static var adminRole: MockRole?
    @objc public static var memberRole: MockRole?

    public static var entityName = "Role"

    @NSManaged public var name: String
    @NSManaged public var actions: Set<MockAction>
    @NSManaged public var team: MockTeam?
    @NSManaged public var conversation: MockConversation?
    @NSManaged public var participantRoles: Set<MockParticipantRole>
}

extension MockRole {
    @objc
    public static func insert(in context: NSManagedObjectContext, name: String, actions: Set<MockAction>) -> MockRole {
        let role: MockRole = insert(in: context)
        role.name = name
        role.actions = actions

        return role
    }

    var payloadValues: [String: Any?] {
        [
            "conversation_role": name,
            "actions": actions.map(\.payload),
        ]
    }

    var payload: ZMTransportData {
        payloadValues as NSDictionary
    }
}

extension MockRole {
    @objc
    public static func createConversationRoles(context: NSManagedObjectContext) {
        adminRole = MockRole.insert(
            in: context,
            name: MockConversation.admin,
            actions: MockTeam.createAdminActions(context: context)
        )
        memberRole = MockRole.insert(
            in: context,
            name: MockConversation.member,
            actions: MockTeam.createMemberActions(context: context)
        )
    }
}

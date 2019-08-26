//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension MockConversation {
    @objc public static func insertConversationInto(context: NSManagedObjectContext, withCreator creator: MockUser, forTeam team: MockTeam, users:[MockUser]) -> MockConversation {
        let conversation = NSEntityDescription.insertNewObject(forEntityName: "Conversation", into: context) as! MockConversation
        conversation.type = .group
        (conversation.accessMode, conversation.accessRole) = defaultAccess(conversationType: .group, team: team)
        conversation.team = team
        conversation.identifier = UUID.create().transportString()
        conversation.creator = creator
        conversation.mutableOrderedSetValue(forKey: #keyPath(MockConversation.activeUsers)).addObjects(from: users)
        return conversation
    }

    @objc public static func defaultAccessMode(conversationType: ZMTConversationType, team: MockTeam?) -> [String] {
        let (accessMode, _) = defaultAccess(conversationType: conversationType, team: team)
        return accessMode
    }

    @objc public static func defaultAccessRole(conversationType: ZMTConversationType, team: MockTeam?) -> String {
        let (_, accessRole) = defaultAccess(conversationType: conversationType, team: team)
        return accessRole
    }

    public static func defaultAccess(conversationType: ZMTConversationType, team: MockTeam?) -> ([String], String) {
        switch (team, conversationType) {
        case (.some, .group):
            return (["invite"], "activated")
        case (.some, _):
            return (["private"], "private")
        case (.none, .group):
            return (["invite"], "activated")
        case (.none, _):
            return (["private"], "private")
        }
    }

    @objc public func set(allowGuests: Bool) {
        guard type == .group, team != nil else {
             return
        }
        accessRole = MockConversationAccessRole.value(forAllowGuests: allowGuests).rawValue
        accessMode = MockConversationAccessMode.value(forAllowGuests: allowGuests).stringValue
    }

    @objc var changePushPayload: [String: Any]? {
        let accessModeKeyPath = #keyPath(MockConversation.accessMode)
        let accessRoleKeyPath = #keyPath(MockConversation.accessRole)

        if changedValues()[accessModeKeyPath] != nil || changedValues()[accessRoleKeyPath] != nil {
            return [ "access_role" : self.accessRole, "access" : self.accessMode ]
        } else {
            return nil
        }
    }
}

extension MockConversation: EntityNamedProtocol {
    public static var entityName: String {
        return "Conversation"
    }
}

@objc public extension MockConversation {
    static func existingConversation(with identifier: String, managedObjectContext: NSManagedObjectContext) -> MockConversation? {
        let conversationPredicate = NSPredicate(format: "%K == %@", #keyPath(MockConversation.identifier), identifier)
        return MockConversation.fetch(in: managedObjectContext, withPredicate: conversationPredicate)

    }
}

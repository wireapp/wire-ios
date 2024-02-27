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
import CoreData
import WireDataModel

// MARK: - factory methods

extension ZMConversation {
    static func createOtherUserConversation(moc: NSManagedObjectContext, otherUser: ZMUser) -> ZMConversation {

        let otherUserConversation = ZMConversation.insertNewObject(in: moc)
        otherUserConversation.add(participants: [ZMUser.selfUser(in: moc), otherUser])

        otherUserConversation.conversationType = .oneOnOne
        otherUserConversation.remoteIdentifier = UUID.create()
        let connection = ZMConnection.insertNewObject(in: moc)
        connection.to = otherUser
        connection.status = .accepted

        otherUser.oneOnOneConversation = otherUserConversation

        return otherUserConversation
    }

    static func createGroupConversationOnlyAdmin(moc: NSManagedObjectContext, selfUser: ZMUser) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: moc)
        conversation.remoteIdentifier = UUID.create()
        conversation.conversationType = .group

        let role = Role(context: moc)
        role.name = ZMConversation.defaultAdminRoleName
        conversation.addParticipantsAndUpdateConversationState(users: [selfUser], role: role)

        return conversation
    }

    static func createGroupConversation(moc: NSManagedObjectContext,
                                        otherUser: ZMUser,
                                        selfUser: ZMUser) -> ZMConversation {
        let conversation = createGroupConversationOnlyAdmin(moc: moc, selfUser: selfUser)
        conversation.add(participants: otherUser)
        return conversation
    }

    static func createTeamGroupConversation(moc: NSManagedObjectContext,
                                            otherUser: ZMUser,
                                            selfUser: ZMUser) -> ZMConversation {
        let conversation = createGroupConversation(moc: moc, otherUser: otherUser, selfUser: selfUser)
        conversation.teamRemoteIdentifier = UUID.create()
        conversation.userDefinedName = "Group conversation"
        return conversation
    }
}

// swiftlint:disable todo_requires_jira_link
// TODO: retire this extension
// swiftlint:enable todo_requires_jira_link
extension ZMConversation {

    func add(participants: Set<ZMUser>) {
        addParticipantsAndUpdateConversationState(users: participants, role: nil)
    }

    func add(participants: [ZMUser]) {
        add(participants: Set(participants))
    }

    func add(participants: ZMUser...) {
        add(participants: Set(participants))
    }
}

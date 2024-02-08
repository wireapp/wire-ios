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
import WireDataModel

/// A helper object to make it easy to create and relate model objects.

public struct ModelHelper {

    public init() {

    }

    // MARK: - Users

    @discardableResult
    public func createUser(
        id: UUID = .init(),
        domain: String? = nil,
        in context: NSManagedObjectContext
    ) -> ZMUser {
        let user = ZMUser.insertNewObject(in: context)
        user.remoteIdentifier = id
        user.domain = domain
        return user
    }

    // MARK: - Teams

    @discardableResult
    public func createSelfTeam(
        id: UUID = .init(),
        numberOfUsers: UInt,
        in context: NSManagedObjectContext
    ) -> (Team, selfUser: ZMUser, otherUsers: Set<ZMUser>) {
        let (team, otherUsers) = createTeam(id: id, numberOfUsers: numberOfUsers, in: context)
        let selfUser = ZMUser.selfUser(in: context)
        selfUser.remoteIdentifier = selfUser.remoteIdentifier ?? UUID()
        addUser(selfUser, to: team, in: context)
        return (team, selfUser, otherUsers)
    }

    @discardableResult
    public func createTeam(
        id: UUID = .init(),
        numberOfUsers: UInt,
        in context: NSManagedObjectContext
    ) -> (Team, Set<ZMUser>) {
        let team = createTeam(id: id, in: context)

        var users = (0..<numberOfUsers).map { _ in
            let user = self.createUser(in: context)
            addUser(user, to: team, in: context)
            return user
        }

        return (team, Set(users))
    }

    @discardableResult
    public func createTeam(
        id: UUID = .init(),
        in context: NSManagedObjectContext
    ) -> Team {
        let team = Team.insertNewObject(in: context)
        team.remoteIdentifier = id
        return team
    }

    public func addUsers(
        _ users: [ZMUser],
        to team: Team,
        in context: NSManagedObjectContext
    ) {
        for user in users {
            addUser(
                user,
                to: team,
                in: context
            )
        }
    }

    @discardableResult
    public func addUser(
        _ user: ZMUser,
        to team: Team,
        in context: NSManagedObjectContext
    ) -> Member {
        let member = Member.insertNewObject(in: context)
        member.user = user
        member.team = team
        return member
    }

    // MARK: - Conversations

    @discardableResult
    public func createOneOnOne(
        with user: ZMUser,
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let selfUser = ZMUser.selfUser(in: context)
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .oneOnOne
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        conversation.oneOnOneUser = user
        return conversation
    }

}

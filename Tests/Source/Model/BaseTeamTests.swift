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


import WireTesting
@testable import WireDataModel


class BaseTeamTests: ZMConversationTestsBase {

    @discardableResult func createTeamAndMember(for user: ZMUser, with permissions: Permissions? = nil) -> (Team, Member) {
        let member = Member.insertNewObject(in: uiMOC)
        member.team = .insertNewObject(in: uiMOC)
        member.team?.remoteIdentifier = .create()
        member.user = user
        if let permissions = permissions {
            member.permissions = permissions
        }
        return (member.team!, member)
    }

    @discardableResult func createUserAndAddMember(to team: Team) -> (ZMUser, Member) {
        let member = Member.insertNewObject(in: uiMOC)
        member.user = .insertNewObject(in: uiMOC)
        member.user?.remoteIdentifier = .create()
        member.team = team
        return (member.user!, member)
    }

}

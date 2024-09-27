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

import WireDataModel
import XCTest

final class ZMSearchUserTests_TeamUser: ModelObjectsTests {
    // MARK: Internal

    func testThatSearchUserIsRecognizedAsTeamMember_WhenBelongingToTheSameTeam() {
        // given
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)
        let searchUser = makeSearchUser(teamIdentifier: team.remoteIdentifier)

        // then
        XCTAssertTrue(searchUser.isTeamMember)
        XCTAssertTrue(searchUser.isConnected)
    }

    func testThatSearchUserIsNotRecognizedAsTeamMember_WhenNotBelongingToTheSameTeam() {
        // given
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)
        let searchUser = makeSearchUser(teamIdentifier: UUID())

        // then
        XCTAssertFalse(searchUser.isTeamMember)
        XCTAssertFalse(searchUser.isConnected)
    }

    func testThatOneToOneConversationIsNotCreated_WhenNotBelongingToTheSameTeam() {
        // given
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)
        let searchUser = makeSearchUser(teamIdentifier: UUID())
        uiMOC.saveOrRollback()

        // then
        XCTAssertNil(searchUser.oneToOneConversation)
    }

    func testThatSearchUserCanBeUpdatedTeamMembershipDetails() {
        // given
        let creator = UUID()
        let team = createTeam(in: uiMOC)
        _ = createMembership(in: uiMOC, user: selfUser, team: team)
        let searchUser = makeSearchUser(teamIdentifier: team.remoteIdentifier)

        // when
        searchUser.updateWithTeamMembership(permissions: .partner, createdBy: creator)

        // then
        XCTAssertEqual(searchUser.teamRole, .partner)
        XCTAssertEqual(searchUser.teamCreatedBy, creator)
    }

    // MARK: Private

    // MARK: Helpers

    private func makeSearchUser(teamIdentifier: UUID?) -> ZMSearchUser {
        ZMSearchUser(
            contextProvider: coreDataStack,
            name: "Foo",
            handle: "foo",
            accentColor: .amber,
            remoteIdentifier: teamIdentifier,
            teamIdentifier: teamIdentifier,
            searchUsersCache: nil
        )
    }
}

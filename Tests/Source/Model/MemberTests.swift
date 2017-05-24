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


class MemberTests: BaseTeamTests {

    func testThatItStoresThePermissionsOfAMember() {
        // given
        let sut = Member.insertNewObject(in: uiMOC)

        // when
        sut.permissions = .member
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertEqual(sut.permissions, .member)
    }

    func testThatItReturnsThePermissionsOfAUser() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)

        // when
        let (team, _) = createTeamAndMember(for: user, with: .member)

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertEqual(user.permissions(in: team), .member)
    }

    func testThatItReturnsIfAUserIsMemberOfATeam() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)

        // when
        let (team1, _) = createTeamAndMember(for: user, with: .member)
        let team2 = Team.insertNewObject(in: uiMOC)

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertTrue(user.isMember(of: team1))
        XCTAssertFalse(user.isMember(of: team2))
    }

    func testThatItReturnsIfAUserIsNotAMemberOfATeam() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)

        // when
        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertFalse(user.hasTeams)
    }

    func testThatItReturnsIfAUserHasTeams() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)

        // when
        createTeamAndMember(for: user, with: .member)

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertTrue(user.hasTeams)
    }

    func testThatItReturnsTheTeamsOfAUser() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)

        // when
        let (team1, _) = createTeamAndMember(for: user, with: .member)
        let (team2, _) = createTeamAndMember(for: user, with: .admin)

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertTrue(user.isMember(of: team1))
        XCTAssertTrue(user.isMember(of: team2))
        XCTAssertEqual(user.teams, [team1, team2])
        XCTAssertTrue(user.hasTeams)
        XCTAssertEqual(user.permissions(in: team1), .member)
        XCTAssertEqual(user.permissions(in: team2), .admin)
    }

    func testThatItReturnsActiveTeams() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        let (team1, _) = createTeamAndMember(for: user)
        let (team2, _) = createTeamAndMember(for: user)

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // when
        team1.isActive = true

        // then
        XCTAssertEqual(user.activeTeams, [team1])

        // when
        team2.isActive = true

        // then
        XCTAssertEqual(user.activeTeams, [team1, team2])

        // when
        team1.isActive = false

        // then
        XCTAssertEqual(user.activeTeams, [team2])
    }

    func testThatItReturnsExistingMemberOfAUserInATeam() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        let (team, existingMember) = createTeamAndMember(for: user)

        // when
        let member = Member.getOrCreateMember(for: user, in: team, context: uiMOC)

        // then
        XCTAssertEqual(member, existingMember)
    }

    func testThatItCreatesNewMemberIfUserHasNoMemberInTeam() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        let team = Team.insertNewObject(in: uiMOC)

        // when
        let member = Member.getOrCreateMember(for: user, in: team, context: uiMOC)

        // then
        XCTAssertNotNil(member)
        XCTAssertEqual(member.user, user)
        XCTAssertEqual(member.team, team)
    }
    
}

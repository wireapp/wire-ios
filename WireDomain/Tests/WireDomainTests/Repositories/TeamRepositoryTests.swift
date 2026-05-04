//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireDataModelSupport
import WireNetwork
import WireNetworkSupport
import WireTestingPackage
import XCTest
@testable import WireDomain
@testable import WireDomainSupport

final class TeamRepositoryTests: XCTestCase {

    private var sut: TeamRepository!
    private var userRespository: MockUserRepositoryProtocol!
    private var teamsAPI: MockTeamsAPI!
    private var teamLocalStore: MockTeamLocalStoreProtocol!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        userRespository = MockUserRepositoryProtocol()
        teamsAPI = MockTeamsAPI()
        teamLocalStore = MockTeamLocalStoreProtocol()

        sut = TeamRepository(
            userRepository: userRespository,
            teamLocalStore: teamLocalStore,
            teamsAPI: teamsAPI
        )

        teamLocalStore.selfTeamID_MockValue = Scaffolding.selfTeamID
    }

    override func tearDown() async throws {
        stack = nil
        modelHelper = nil
        userRespository = nil
        teamsAPI = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testPullSelfTeam_It_Invokes_Local_Store_And_Team_API_Methods() async throws {
        // Mock

        teamsAPI.getTeamFor_MockValue = WireNetwork.Team(
            id: Scaffolding.selfTeamID,
            name: Scaffolding.teamName,
            creatorID: Scaffolding.teamCreatorID,
            logoID: Scaffolding.logoID,
            logoKey: Scaffolding.logoKey,
            splashScreenID: Scaffolding.splashScreenID
        )

        teamLocalStore.storeTeamIdNameCreatorIDLogoIDLogoKey_MockMethod = { _, _, _, _, _ in }

        // When

        try await sut.pullSelfTeam()

        // Then

        XCTAssertEqual(teamsAPI.getTeamFor_Invocations.count, 1)
        XCTAssertEqual(teamLocalStore.storeTeamIdNameCreatorIDLogoIDLogoKey_Invocations.count, 1)
    }

    func testPullSelfTeamRoles_It_Invokes_Local_Store_And_Team_API_Methods() async throws {
        // Mock

        teamsAPI.getTeamRolesFor_MockValue = [
            ConversationRole(
                name: "admin",
                actions: [
                    .addConversationMember,
                    .deleteConversation
                ]
            ),
            ConversationRole(
                name: "member",
                actions: [
                    .addConversationMember
                ]
            )
        ]

        teamLocalStore.storeTeamRolesSelfTeamIDTeamRolesInfo_MockMethod = { _, _ in }

        // When

        try await sut.pullSelfTeamRoles()

        // Then

        XCTAssertEqual(teamsAPI.getTeamRolesFor_Invocations.count, 1)
        XCTAssertEqual(teamLocalStore.storeTeamRolesSelfTeamIDTeamRolesInfo_Invocations.count, 1)
    }

    func testPullSelfTeamMembers_It_Invokes_Local_Store_And_Team_API_Methods() async throws {
        // Mock

        teamsAPI.getTeamMembersForMaxResults_MockValue = [
            TeamMember(
                userID: Scaffolding.member1ID,
                creationDate: Scaffolding.member1CreationDate,
                creatorID: Scaffolding.member1CreatorID,
                legalholdStatus: Scaffolding.member1legalholdStatus,
                permissions: TeamMemberPermissions(
                    copyPermissions: Scaffolding.member1Permissions,
                    selfPermissions: Scaffolding.member1Permissions
                )
            ),
            TeamMember(
                userID: Scaffolding.member2ID,
                creationDate: Scaffolding.member2CreationDate,
                creatorID: Scaffolding.member2CreatorID,
                legalholdStatus: Scaffolding.member2legalholdStatus,
                permissions: TeamMemberPermissions(
                    copyPermissions: Scaffolding.member2Permissions,
                    selfPermissions: Scaffolding.member2Permissions
                )
            )
        ]

        teamLocalStore.storeTeamMembersSelfTeamIDTeamMembersInfo_MockMethod = { _, _ in }

        // When

        try await sut.pullSelfTeamMembers()

        // Then

        XCTAssertEqual(teamsAPI.getTeamMembersForMaxResults_Invocations.count, 1)
        XCTAssertEqual(teamLocalStore.storeTeamMembersSelfTeamIDTeamMembersInfo_Invocations.count, 1)
    }

    func testFetchSelfLegalholdStatus_It_Invokes_Local_Store_And_Teams_API_Methods_And_Legal_Hold_Status_Is_Pending(
    ) async throws {
        // Mock

        teamsAPI.getLegalholdInfoForUserID_MockValue = Scaffolding.teamMemberLegalhold
        teamLocalStore.selfUserID_MockValue = UUID()

        // When

        let result = try await sut.fetchSelfLegalholdStatus()

        // Then

        XCTAssertEqual(teamLocalStore.selfUserID_Invocations.count, 1)
        XCTAssertEqual(teamsAPI.getLegalholdInfoForUserID_Invocations.count, 1)
        XCTAssertEqual(result, .pending)
    }

    func testDeleteTeamMembership_It_Invokes_Local_Store_And_User_Repo_Methods() async throws {
        // Mock

        let (user, member) = try await context.perform { [self] in
            let (team, users, _) = modelHelper.createTeam(
                id: Scaffolding.teamID,
                withMembers: [Scaffolding.userID],
                context: context
            )

            let user = try XCTUnwrap(users.first)
            let member = try XCTUnwrap(team.members.first)
            XCTAssertEqual(user.membership, member)

            return (user, member)
        }

        userRespository.deleteUserAccountIdDomainAt_MockMethod = { _, _, _ in }
        userRespository.fetchUserIdDomain_MockValue = user
        teamLocalStore.userMembershipUser_MockValue = member
        teamLocalStore.userDomainUser_MockValue = Scaffolding.domain
        teamLocalStore.deleteMember_MockMethod = { _ in }

        // When

        try await sut.deleteMembership(
            userID: Scaffolding.userID,
            domain: nil,
            date: .distantPast
        )

        // Then

        XCTAssertEqual(userRespository.deleteUserAccountIdDomainAt_Invocations.count, 1)
        XCTAssertEqual(userRespository.fetchUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(teamLocalStore.userMembershipUser_Invocations.count, 1)
        XCTAssertEqual(teamLocalStore.userDomainUser_Invocations.count, 1)
        XCTAssertEqual(teamLocalStore.deleteMember_Invocations.count, 1)
    }

    func testStoreTeamMemberNeedsBackendUpdate_It_Invokes_Local_Store_Methods() async throws {
        // Mock

        let member = await context.perform { [self] in

            let team = modelHelper.createTeam(
                id: Scaffolding.teamID,
                in: context
            )

            let user = modelHelper.createUser(
                id: Scaffolding.membershipID,
                domain: Scaffolding.domain,
                in: context
            )

            return modelHelper.addUser(
                user,
                to: team,
                in: context
            )
        }

        teamLocalStore.fetchMemberId_MockValue = member
        teamLocalStore.storeMemberNeedsBackendUpdateMember_MockMethod = { _, _ in }

        // When

        try await sut.storeTeamMemberNeedsBackendUpdate(
            membershipID: Scaffolding.membershipID
        )

        // Then

        XCTAssertEqual(teamLocalStore.fetchMemberId_Invocations.count, 1)
        XCTAssertEqual(teamLocalStore.storeMemberNeedsBackendUpdateMember_Invocations.count, 1)
    }

    func testStoreTeamMemberNeedsBackendUpdate_It_Throws_Error_When_Member_Was_Not_Found() async throws {
        // Mock

        teamLocalStore.fetchMemberId_MockMethod = { _ in nil }

        // Then

        await XCTAssertThrowsErrorAsync { [self] in
            // When

            try await sut.storeTeamMemberNeedsBackendUpdate(
                membershipID: Scaffolding.membershipID
            )
        }
    }

    func testCreateOrUpdateTeam_It_Invokes_Local_Store_And_User_Repo_Methods() async throws {
        // Mock

        teamLocalStore.createOrUpdateTeamIdentifierNameCreatorIconIconKey_MockMethod = { _, _, _, _, _ in }

        // When

        await sut.createOrUpdateTeam(
            identifier: Scaffolding.teamID,
            name: Scaffolding.teamName,
            creator: Scaffolding.teamCreatorID,
            icon: Scaffolding.logoID,
            iconKey: Scaffolding.logoKey
        )

        // Then

        XCTAssertEqual(teamLocalStore.createOrUpdateTeamIdentifierNameCreatorIconIconKey_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let userID = UUID.mockID1
        static let selfUserID = UUID.mockID2
        static let teamID = UUID.mockID3
        static let selfTeamID = UUID.mockID4
        static let domain = "example.com"
        static let membershipID = UUID.mockID5
        static let teamCreatorID = UUID.mockID6
        static let teamName = "Team Foo"
        static let logoID = UUID.mockID1.uuidString
        static let logoKey = UUID.mockID2.uuidString
        static let splashScreenID = UUID.mockID3.uuidString
        static let conversationID = UUID()

        static let member1ID = UUID.mockID4
        static let member1CreationDate = Date()
        static let member1CreatorID = UUID.mockID2
        static let member1legalholdStatus = LegalholdStatus.enabled
        static let member1Permissions = Permissions.admin.rawValue

        static let member2ID = UUID.mockID2
        static let member2CreationDate = Date()
        static let member2CreatorID = UUID.mockID4
        static let member2legalholdStatus = LegalholdStatus.pending
        static let member2Permissions = Permissions.member.rawValue

        static let teamMemberLegalhold = TeamMemberLegalholdInfo(
            status: .pending,
            clientID: "abc123",
            prekey: prekey
        )

        static let prekey = LegalholdPrekey(id: 2330, base64EncodedKey: "foo")
    }
}

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

import WireAPI
import WireAPISupport
import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireDomain
@testable import WireDomainSupport

final class TeamRepositoryTests: XCTestCase {

    var sut: TeamRepository!
    var userRespository: MockUserRepositoryProtocol!
    var teamsAPI: MockTeamsAPI!

    var stack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()

        stack = try await coreDataStackHelper.createStack()
        userRespository = MockUserRepositoryProtocol()
        teamsAPI = MockTeamsAPI()
        sut = TeamRepository(
            selfTeamID: Scaffolding.selfTeamID,
            userRepository: userRespository,
            teamsAPI: teamsAPI,
            context: context
        )

        let selfUser = await context.perform { [context, modelHelper] in
            modelHelper.createSelfUser(
                id: Scaffolding.selfUserID,
                in: context
            )
        }

        userRespository.fetchSelfUser_MockValue = selfUser
    }

    override func tearDown() async throws {
        stack = nil
        userRespository = nil
        teamsAPI = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()

        try await super.tearDown()
    }

    // MARK: - Tests

    func testPullSelfTeam() async throws {
        // Given
        await context.perform { [context] in
            // There is no team in the database.
            XCTAssertNil(Team.fetch(with: Scaffolding.selfTeamID, in: context))
        }

        // Mock
        teamsAPI.getTeamFor_MockValue = WireAPI.Team(
            id: Scaffolding.selfTeamID,
            name: Scaffolding.teamName,
            creatorID: Scaffolding.teamCreatorID,
            logoID: Scaffolding.logoID,
            logoKey: Scaffolding.logoKey,
            splashScreenID: Scaffolding.splashScreenID
        )

        // When
        try await sut.pullSelfTeam()

        // Then
        try await context.perform { [context] in
            // There is a team in the database.
            let team = try XCTUnwrap(Team.fetch(with: Scaffolding.selfTeamID, in: context))
            XCTAssertEqual(team.remoteIdentifier, Scaffolding.selfTeamID)
            XCTAssertEqual(team.name, Scaffolding.teamName)
            XCTAssertEqual(team.creator?.remoteIdentifier, Scaffolding.teamCreatorID)
            XCTAssertEqual(team.pictureAssetId, Scaffolding.logoID)
            XCTAssertEqual(team.pictureAssetKey, Scaffolding.logoKey)
            XCTAssertFalse(team.needsToBeUpdatedFromBackend)
        }
    }

    func testPullSelfTeamRoles() async throws {
        // Given
        let team = try await context.perform { [context, modelHelper] in
            // Make sure we have no roles to begin with.
            let request = Role.fetchRequest()
            let roles = try context.fetch(request)
            XCTAssertTrue(roles.isEmpty)

            // A team is needed to store new roles.
            return modelHelper.createTeam(
                id: Scaffolding.selfTeamID,
                in: context
            )
        }

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

        // When
        try await sut.pullSelfTeamRoles()

        // Then
        try await context.perform { [context] in
            XCTAssertFalse(team.needsToDownloadRoles)

            // There are two roles.
            let request = NSFetchRequest<Role>(entityName: Role.entityName())
            request.sortDescriptors = [NSSortDescriptor(key: Role.nameKey, ascending: true)]
            let roles = try context.fetch(request)
            guard roles.count == 2 else { return XCTFail("roles.count != 2") }

            // One is for the admin.
            let firstRole = try XCTUnwrap(roles[0])
            XCTAssertEqual(firstRole.name, "admin")
            XCTAssertEqual(firstRole.team?.remoteIdentifier, Scaffolding.selfTeamID)
            XCTAssertNil(firstRole.conversation)
            XCTAssertEqual(
                Set(firstRole.actions.map(\.name)),
                [
                    "add_conversation_member",
                    "delete_conversation"
                ]
            )

            // One is for the member.
            let secondRole = try XCTUnwrap(roles[1])
            XCTAssertEqual(secondRole.name, "member")
            XCTAssertEqual(secondRole.team?.remoteIdentifier, Scaffolding.selfTeamID)
            XCTAssertNil(secondRole.conversation)
            XCTAssertEqual(Set(secondRole.actions.map(\.name)), ["add_conversation_member"])
        }
    }

    func testPullSelfTeamMembers() async throws {
        // Given
        let team = await context.perform { [context, modelHelper] in
            let team = modelHelper.createTeam(
                id: Scaffolding.selfTeamID,
                in: context
            )

            XCTAssertTrue(team.members.isEmpty)
            return team
        }

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

        // When
        try await sut.pullSelfTeamMembers()

        // Then
        try await context.perform {
            XCTAssertEqual(team.members.count, 2)

            let member1 = try XCTUnwrap(team.members.first(where: {
                $0.remoteIdentifier == Scaffolding.member1ID
            }))

            XCTAssertEqual(member1.createdAt, Scaffolding.member1CreationDate)
            XCTAssertEqual(member1.createdBy?.remoteIdentifier, Scaffolding.member1CreatorID)
            XCTAssertEqual(member1.permissions.rawValue, Scaffolding.member1Permissions)
            XCTAssertFalse(member1.needsToBeUpdatedFromBackend)

            let member2 = try XCTUnwrap(team.members.first(where: {
                $0.remoteIdentifier == Scaffolding.member2ID
            }))

            XCTAssertEqual(member2.createdAt, Scaffolding.member2CreationDate)
            XCTAssertEqual(member2.createdBy?.remoteIdentifier, Scaffolding.member2CreatorID)
            XCTAssertEqual(member2.permissions.rawValue, Scaffolding.member2Permissions)
            XCTAssertFalse(member2.needsToBeUpdatedFromBackend)
        }
    }

    func testFetchSelfLegalholdStatus() async throws {
        // Mock
        teamsAPI.getLegalholdInfoForUserID_MockValue = Scaffolding.teamMemberLegalhold

        // When
        let result = try await sut.fetchSelfLegalholdInfo()

        // Then
        XCTAssertEqual(result, Scaffolding.teamMemberLegalhold)
    }

}

private enum Scaffolding {

    static let selfUserID = UUID()

    static let selfTeamID = UUID()
    static let teamCreatorID = UUID()
    static let teamName = "Team Foo"
    static let logoID = UUID().uuidString
    static let logoKey = UUID().uuidString
    static let splashScreenID = UUID().uuidString

    static let member1ID = UUID()
    static let member1CreationDate = Date()
    static let member1CreatorID = UUID()
    static let member1legalholdStatus = LegalholdStatus.enabled
    static let member1Permissions = Permissions.admin.rawValue

    static let member2ID = UUID()
    static let member2CreationDate = Date()
    static let member2CreatorID = UUID()
    static let member2legalholdStatus = LegalholdStatus.pending
    static let member2Permissions = Permissions.member.rawValue

    static let teamMemberLegalhold = TeamMemberLegalholdInfo(
        status: .pending,
        prekey: prekey
    )

    static let prekey = LegalholdPrekey(id: 2_330, base64EncodedKey: "foo")
}

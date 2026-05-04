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
import WireTestingPackage
import XCTest
@testable import WireDomain
@testable import WireDomainSupport

final class TeamLocalStoreTests: XCTestCase {

    private var sut: TeamLocalStore!
    private var userLocalStore: MockUserLocalStoreProtocol!
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
        userLocalStore = MockUserLocalStoreProtocol()

        sut = TeamLocalStore(
            context: context,
            userLocalStore: userLocalStore
        )
    }

    override func tearDown() async throws {
        stack = nil
        modelHelper = nil
        userLocalStore = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testStoreTeam_It_Stores_Team_Locally() async throws {
        // Mock

        let user = await context.perform { [self] in
            let user = modelHelper.createUser(in: context)

            // There is no team in the database.
            XCTAssertNil(Team.fetch(with: Scaffolding.teamID, in: context))

            return user
        }

        userLocalStore.fetchSelfUser_MockValue = user

        // When

        await sut.storeTeam(
            id: Scaffolding.teamID,
            name: Scaffolding.teamName,
            creatorID: Scaffolding.teamCreatorID,
            logoID: Scaffolding.logoID,
            logoKey: Scaffolding.logoKey
        )

        // Then

        try await context.perform { [context] in
            // There is a team in the database.
            let team = try XCTUnwrap(Team.fetch(with: Scaffolding.teamID, in: context))
            XCTAssertEqual(team.remoteIdentifier, Scaffolding.teamID)
            XCTAssertEqual(team.name, Scaffolding.teamName)
            XCTAssertEqual(team.creator?.remoteIdentifier, Scaffolding.teamCreatorID)
            XCTAssertEqual(team.pictureAssetId, Scaffolding.logoID)
            XCTAssertEqual(team.pictureAssetKey, Scaffolding.logoKey)
            XCTAssertFalse(team.needsToBeUpdatedFromBackend)
        }
    }

    func testStoreTeamRoles_It_Store_Team_Roles_Locally() async throws {
        // Mock

        let team = try await context.perform { [context, modelHelper] in
            // Make sure we have no roles to begin with.
            let request = Role.fetchRequest()
            let roles = try context.fetch(request)
            XCTAssertTrue(roles.isEmpty)

            // A team is needed to store new roles.
            return modelHelper!.createTeam(
                id: Scaffolding.selfTeamID,
                in: context
            )
        }

        // When

        try await sut.storeTeamRoles(
            selfTeamID: Scaffolding.selfTeamID,
            teamRolesInfo: Scaffolding.teamRolesInfo
        )

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

    func testStoreTeamMembers_It_Stores_Team_Members_Locally() async throws {
        // Mock

        let team = await context.perform { [context, modelHelper] in
            let team = modelHelper!.createTeam(
                id: Scaffolding.selfTeamID,
                in: context
            )

            XCTAssertTrue(team.members.isEmpty)
            return team
        }

        // When

        try await sut.storeTeamMembers(
            selfTeamID: Scaffolding.selfTeamID,
            teamMembersInfo: Scaffolding.teamMembersInfo
        )

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

    func testDeleteTeamMembership_It_Deletes_Member_From_Team_Locally() async throws {
        // Mock

        let member = try await context.perform { [self] in
            let (team, users, _) = modelHelper.createTeam(
                id: Scaffolding.teamID,
                withMembers: [Scaffolding.userID],
                context: context
            )

            let user = try XCTUnwrap(users.first)
            let member = try XCTUnwrap(team.members.first)
            XCTAssertEqual(user.membership, member)

            return try XCTUnwrap(user.membership)
        }

        // When

        await sut.deleteMember(member)

        // Then

        try await context.perform { [context] in
            /// users won't be deleted as we might be in other (non-team) conversations with them
            XCTAssertNotNil(ZMUser.fetch(with: Scaffolding.userID, in: context))

            let team = try XCTUnwrap(Team.fetch(with: Scaffolding.teamID, in: context), "No team")

            XCTAssertEqual(team.members, [])
        }
    }

    func testStoreTeamMemberNeedsBackendUpdate_It_Updates_Flag_Locally() async throws {
        // Mock

        let member = await context.perform { [context, modelHelper] in

            let team = modelHelper!.createTeam(
                id: Scaffolding.teamID,
                in: context
            )

            let user = modelHelper!.createUser(
                id: Scaffolding.membershipID,
                domain: Scaffolding.domain,
                in: context
            )

            let member = modelHelper!.addUser(
                user,
                to: team,
                in: context
            )

            XCTAssertEqual(member.needsToBeUpdatedFromBackend, false)

            return member
        }

        // When

        await sut.storeMember(
            needsBackendUpdate: true,
            member: member
        )

        await context.perform { [context] in
            let user = ZMUser.fetch(with: Scaffolding.membershipID, in: context)
            let team = Team.fetch(with: Scaffolding.teamID, in: context)

            guard let user, let team, let member = user.membership else {
                return XCTFail()
            }

            // Then

            XCTAssertEqual(member.needsToBeUpdatedFromBackend, true)
            XCTAssertEqual(member.team, team)
        }
    }

    func testCreateOrUpdateTeam_It_Creates_Team_Locally() async throws {

        // Given

        await context.perform { [context] in
            let team = Team.fetch(with: Scaffolding.teamID, in: context)
            XCTAssertNil(team)
        }

        // When

        await sut.createOrUpdateTeam(
            identifier: Scaffolding.teamID,
            name: Scaffolding.teamName,
            creator: Scaffolding.teamCreatorID,
            icon: Scaffolding.logoID,
            iconKey: Scaffolding.logoKey
        )

        // Then

        try await context.perform { [context] in
            let team = try XCTUnwrap(
                Team.fetch(with: Scaffolding.teamID, in: context)
            )

            let creator = try XCTUnwrap(
                ZMUser.fetch(with: Scaffolding.teamCreatorID, in: context)
            )

            XCTAssertEqual(team.remoteIdentifier, Scaffolding.teamID)
            XCTAssertEqual(team.name, Scaffolding.teamName)
            XCTAssertEqual(team.creator, creator)
            XCTAssertEqual(team.pictureAssetId, Scaffolding.logoID)
            XCTAssertEqual(team.pictureAssetKey, Scaffolding.logoKey)

        }
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
        static let logoKey = UUID.mockID1.uuidString
        static let conversationID = UUID()

        static let member1ID = UUID.mockID1
        static let member1CreationDate = Date()
        static let member1CreatorID = UUID.mockID2
        static let member1Permissions = Permissions.admin.rawValue

        static let member2ID = UUID.mockID2
        static let member2CreationDate = Date()
        static let member2CreatorID = UUID.mockID4
        static let member2Permissions = Permissions.member.rawValue

        static let teamRolesInfo: [TeamRoleInfo] = [
            .init(
                role: "admin",
                actions: ["add_conversation_member", "delete_conversation"]
            ),
            .init(
                role: "member",
                actions: ["add_conversation_member"]
            )
        ]

        static let teamMembersInfo: [TeamMemberInfo] = [
            .init(
                id: member1ID,
                selfPermission: Scaffolding.member1Permissions,
                creatorID: Scaffolding.member1CreatorID,
                creationDate: Scaffolding.member1CreationDate
            ),
            .init(
                id: member2ID,
                selfPermission: Scaffolding.member2Permissions,
                creatorID: Scaffolding.member2CreatorID,
                creationDate: Scaffolding.member2CreationDate
            )
        ]
    }
}

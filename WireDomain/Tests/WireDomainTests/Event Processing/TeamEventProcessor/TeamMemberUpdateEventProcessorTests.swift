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
import WireAPI
import WireAPISupport
import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import XCTest

@testable import WireDomain

final class TeamMemberUpdateEventProcessorTests: XCTestCase {

    var sut: TeamMemberUpdateEventProcessor!

    var coreDataStack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    var teamRepository: TeamRepositoryProtocol!
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        coreDataStack = try await coreDataStackHelper.createStack()
        teamRepository = TeamRepository(
            selfTeamID: UUID(),
            userRepository: MockUserRepositoryProtocol(),
            teamsAPI: MockTeamsAPI(),
            context: context
        )
        sut = TeamMemberUpdateEventProcessor(repository: teamRepository)
        try await super.setUp()
    }

    override func tearDown() async throws {
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Tests

    func testProcessEvent_Member_Needs_To_Be_Updated_From_Backend_Is_True() async throws {
        // Given

        try await context.perform { [context, modelHelper] in

            let team = modelHelper.createTeam(
                id: Scaffolding.teamID,
                in: context
            )

            let user = modelHelper.createUser(
                id: Scaffolding.membershipID,
                domain: Scaffolding.domain,
                in: context
            )

            let member = modelHelper.addUser(
                user,
                to: team,
                in: context
            )

            XCTAssertEqual(member.needsToBeUpdatedFromBackend, false)

            try context.save()
        }

        // When

        try await sut.processEvent(Scaffolding.event)

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

    func testProcessEvent_Throws_Error_When_Member_Was_Not_Found() async throws {
        // Then
        await XCTAssertThrowsError { [self] in
            // When
            try await sut.processEvent(Scaffolding.event)
        }
    }

}

// MARK: - Scaffolding

private enum Scaffolding {

    static let domain = "example.com"
    static let teamID = UUID()
    static let membershipID = UUID()

    nonisolated(unsafe) static let event = TeamMemberUpdateEvent(
        teamID: teamID,
        membershipID: membershipID
    )

}

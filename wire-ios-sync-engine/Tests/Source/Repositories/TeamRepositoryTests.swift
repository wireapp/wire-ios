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
import WireDataModelSupport
@testable import WireSyncEngine
import XCTest

final class TeamRepositoryTests: XCTestCase {

    enum Scaffolding {

        static let selfTeamID = UUID()
        static let teamCreatorID = UUID()
        static let teamName = "Team Foo"
        static let logoID = UUID().uuidString
        static let logoKey = UUID().uuidString
        static let splashScreenID = UUID().uuidString

    }

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
        teamsAPI = MockTeamsAPI()
    }

    override func tearDown() async throws {
        stack = nil
        teamsAPI = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    func testFetchSelfTeam() async throws {
        // Given
        await context.perform { [context] in
            XCTAssertNil(Team.fetch(with: Scaffolding.selfTeamID, in: context))
        }

        let sut = TeamRepository(
            selfTeamID: Scaffolding.selfTeamID,
            teamsAPI: teamsAPI,
            context: context
        )

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
        try await sut.fetchSelfTeam()

        // Then
        try await context.perform { [context] in
            let team = try XCTUnwrap(Team.fetch(with: Scaffolding.selfTeamID, in: context))
            XCTAssertEqual(team.remoteIdentifier, Scaffolding.selfTeamID)
            XCTAssertEqual(team.name, Scaffolding.teamName)
            XCTAssertEqual(team.creator?.remoteIdentifier, Scaffolding.teamCreatorID)
            XCTAssertEqual(team.pictureAssetId, Scaffolding.logoID)
            XCTAssertEqual(team.pictureAssetKey, Scaffolding.logoKey)
        }
    }

}

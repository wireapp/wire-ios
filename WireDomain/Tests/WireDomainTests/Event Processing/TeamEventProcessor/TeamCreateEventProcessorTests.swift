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

import WireDomainSupport
import WireNetwork
import XCTest
@testable import WireDomain

final class TeamCreateEventProcessorTests: XCTestCase {

    private var sut: TeamCreateEventProcessor!
    private var teamRepository: MockTeamRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        teamRepository = MockTeamRepositoryProtocol()
        sut = TeamCreateEventProcessor(
            repository: teamRepository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        teamRepository = nil
        sut = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Create_Or_Update_Team_Repo_Method() async throws {
        // Mock

        teamRepository.createOrUpdateTeamIdentifierNameCreatorIconIconKey_MockMethod = { _, _, _, _, _ in }

        // When

        await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(teamRepository.createOrUpdateTeamIdentifierNameCreatorIconIconKey_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let event = TeamCreateEvent(
            identifier: .mockID1,
            name: "teamName",
            creator: .mockID2,
            icon: "iconID",
            iconKey: "iconKey",
            splashScreen: nil
        )
    }
}

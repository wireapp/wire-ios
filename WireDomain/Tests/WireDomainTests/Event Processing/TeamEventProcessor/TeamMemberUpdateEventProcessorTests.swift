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
@testable import WireDomain
import WireDomainSupport
import XCTest

final class TeamMemberUpdateEventProcessorTests: XCTestCase {

    var sut: TeamMemberUpdateEventProcessor!
    var teamRepository: MockTeamRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        teamRepository = MockTeamRepositoryProtocol()
        sut = TeamMemberUpdateEventProcessor(repository: teamRepository)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        sut = nil
        teamRepository = nil
    }

    // MARK: - Tests

    func testProcessEvent_Member_Needs_To_Be_Updated_From_Backend_Is_True() async throws {
        // Given

        let event = TeamMemberUpdateEvent(
            teamID: Scaffolding.teamID,
            membershipID: Scaffolding.membershipID
        )

        // Mock

        teamRepository.storeTeamMemberNeedsBackendUpdateMembershipID_MockMethod = { _ in }

        // When

        try await sut.processEvent(event)

        // Then

        XCTAssertEqual(teamRepository.storeTeamMemberNeedsBackendUpdateMembershipID_Invocations, [Scaffolding.membershipID])
    }

    private enum Scaffolding {

        static let domain = "example.com"
        static let teamID = UUID()
        static let membershipID = UUID()

    }

}

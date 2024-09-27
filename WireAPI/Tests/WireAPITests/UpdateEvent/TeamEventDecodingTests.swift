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

import XCTest
@testable import WireAPI

final class TeamEventDecodingTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        decoder = .init()
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    func testDecodingTeamMemberLeaveEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "TeamMemberLeave")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .team(.memberLeave(Scaffolding.memberLeaveEvent))
        )
    }

    func testDecodingTeamMemberUpdateEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "TeamMemberUpdate")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .team(.memberUpdate(Scaffolding.memberUpdateEvent))
        )
    }

    // MARK: Private

    private enum Scaffolding {
        static let memberLeaveEvent = TeamMemberLeaveEvent(
            teamID: UUID(uuidString: "6f96e56c-8b3b-4821-925a-457f62f9de32")!,
            userID: UUID(uuidString: "d6344976-f86c-4010-afe2-bc07447ab412")!
        )

        static let memberUpdateEvent = TeamMemberUpdateEvent(
            teamID: UUID(uuidString: "6f96e56c-8b3b-4821-925a-457f62f9de32")!,
            membershipID: UUID(uuidString: "d6344976-f86c-4010-afe2-bc07447ab412")!
        )
    }

    private var decoder: JSONDecoder!
}

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

@testable import WireAPI
import XCTest

final class TeamEventDecodingTests: XCTestCase {

    func testDecodingTeamMemberLeaveEvent() async throws {
        // Given event data.
        let resource = try MockEventDataResource(name: "TeamMemberLeave")

        // When decode update event.
        let updateEvent = try JSONDecoder.defaultDecoder.decode(
            UpdateEvent.self,
            from: resource.jsonData
        )

        // Then it decoded the correct event.
        guard case .team(.memberLeave(let payload)) = updateEvent else {
            return XCTFail("unexpected event: \(updateEvent)")
        }

        XCTAssertEqual(payload, Scaffolding.memberLeaveEventPayload)
    }

    func testDecodingTeamMemberUpdateEvent() async throws {
        // Given event data.
        let resource = try MockEventDataResource(name: "TeamMemberUpdate")

        // When decode update event.
        let updateEvent = try JSONDecoder.defaultDecoder.decode(
            UpdateEvent.self,
            from: resource.jsonData
        )

        // Then it decoded the correct event.
        guard case .team(.memberUpdate(let payload)) = updateEvent else {
            return XCTFail("unexpected event: \(updateEvent)")
        }

        XCTAssertEqual(payload, Scaffolding.memberUpdateEventPayload)
    }

    private enum Scaffolding {

        static let memberLeaveEventPayload = TeamMemberLeaveEvent(
            teamID: UUID(uuidString: "6f96e56c-8b3b-4821-925a-457f62f9de32")!,
            userID: UUID(uuidString: "d6344976-f86c-4010-afe2-bc07447ab412")!
        )

        static let memberUpdateEventPayload = TeamMemberUpdateEvent(
            teamID: UUID(uuidString: "6f96e56c-8b3b-4821-925a-457f62f9de32")!,
            membershipID: UUID(uuidString: "d6344976-f86c-4010-afe2-bc07447ab412")!
        )

    }

}

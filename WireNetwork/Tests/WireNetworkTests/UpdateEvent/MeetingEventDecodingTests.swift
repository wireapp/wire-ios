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

import XCTest

@testable import WireNetwork

final class MeetingEventDecodingTests: XCTestCase {

    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = .init()
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    func testDecodingMeetingCreateEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "MeetingCreate")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .meeting(.create(MeetingCreateEvent(meetingID: Scaffolding.meetingID)))
        )
    }

    func testDecodingMeetingDeleteEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "MeetingDelete")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .meeting(.delete(MeetingDeleteEvent(meetingID: Scaffolding.meetingID)))
        )
    }

    func testDecodingMeetingMemberAddEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "MeetingMemberAdd")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .meeting(.update(MeetingUpdateEvent(meetingID: Scaffolding.meetingID)))
        )
    }

    func testDecodingMeetingUpdateEvent() throws {
        // Given
        let mockEventData = try MockJSONPayloadResource(name: "MeetingUpdate")

        // When
        let decodedEvent = try decoder.decode(
            UpdateEventDecodingProxy.self,
            from: mockEventData.jsonData
        ).updateEvent

        // Then
        XCTAssertEqual(
            decodedEvent,
            .meeting(.update(MeetingUpdateEvent(meetingID: Scaffolding.meetingID)))
        )
    }

    private enum Scaffolding {

        static let meetingID = QualifiedID(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            domain: "example.com"
        )

    }

}

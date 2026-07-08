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
import WireNetworkSupport
import XCTest

@testable import WireDomain

final class MeetingUpdateEventProcessorTests: XCTestCase {

    private var sut: MeetingUpdateEventProcessor!
    private var meetingsAPI: MockMeetingsAPI!
    private var localStore: MockMeetingLocalStoreProtocol!

    override func setUp() async throws {
        try await super.setUp()
        meetingsAPI = MockMeetingsAPI()
        localStore = MockMeetingLocalStoreProtocol()
        sut = MeetingUpdateEventProcessor(
            meetingsAPI: meetingsAPI,
            localStore: localStore
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        meetingsAPI = nil
        localStore = nil
        sut = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Stores_Meeting_Contained_In_Backend_Response() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = [Scaffolding.meeting]
        localStore.storeMeeting_MockMethod = { _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(localStore.storeMeeting_Invocations.count, 1)
        XCTAssertEqual(localStore.storeMeeting_Invocations.first?.id, Scaffolding.meetingID)
        XCTAssertTrue(localStore.deleteMeetingIdDomain_Invocations.isEmpty)
    }

    func testProcessEvent_It_Deletes_Meeting_Missing_From_Backend_Response() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = []
        localStore.deleteMeetingIdDomain_MockMethod = { _, _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertTrue(localStore.storeMeeting_Invocations.isEmpty)
        XCTAssertEqual(localStore.deleteMeetingIdDomain_Invocations.count, 1)
        XCTAssertEqual(localStore.deleteMeetingIdDomain_Invocations.first?.id, Scaffolding.meetingID.id)
        XCTAssertEqual(localStore.deleteMeetingIdDomain_Invocations.first?.domain, Scaffolding.meetingID.domain)
    }

    func testProcessEvent_It_Throws_When_Listing_Meetings_Fails() async {
        // Mock

        meetingsAPI.listMeetings_MockError = MeetingsAPIError.meetingNotFound

        // When / Then

        do {
            try await sut.processEvent(Scaffolding.event)
            XCTFail("expected an error to be thrown")
        } catch {
            XCTAssertTrue(localStore.storeMeeting_Invocations.isEmpty)
            XCTAssertTrue(localStore.deleteMeetingIdDomain_Invocations.isEmpty)
        }
    }

    private enum Scaffolding {

        static let meetingID = WireNetwork.QualifiedID(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            domain: "example.com"
        )

        static let event = MeetingUpdateEvent(meetingID: meetingID)

        static let meeting = MeetingResponse(
            id: meetingID,
            title: "Weekly Sync",
            creatorID: WireNetwork.QualifiedID(id: UUID(), domain: "example.com"),
            startTime: Date(timeIntervalSince1970: 1_000_000),
            endTime: Date(timeIntervalSince1970: 1_003_600),
            conversationID: WireNetwork.QualifiedID(id: UUID(), domain: "example.com"),
            invitedEmails: [],
            isTrial: false,
            createdAt: Date(timeIntervalSince1970: 900_000),
            updatedAt: Date(timeIntervalSince1970: 900_000)
        )

    }

}

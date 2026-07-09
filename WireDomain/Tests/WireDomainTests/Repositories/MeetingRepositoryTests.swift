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

import WireCallingDomain
import WireDomainSupport
import WireNetwork
import WireNetworkSupport
import XCTest

@testable import WireDomain

final class MeetingRepositoryTests: XCTestCase {

    private var sut: MeetingRepository!
    private var meetingsAPI: MockMeetingsAPI!
    private var localStore: MockMeetingLocalStoreProtocol!

    override func setUp() async throws {
        try await super.setUp()
        meetingsAPI = MockMeetingsAPI()
        localStore = MockMeetingLocalStoreProtocol()
        sut = MeetingRepository(
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

    // MARK: - pullMeeting

    func testPullMeeting_It_Stores_Meeting_Contained_In_Backend_Response() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = [Scaffolding.meetingResponse]
        localStore.storeMeeting_MockMethod = { _ in }

        // When

        try await sut.pullMeeting(id: Scaffolding.meetingID)

        // Then

        XCTAssertEqual(localStore.storeMeeting_Invocations.count, 1)
        XCTAssertEqual(localStore.storeMeeting_Invocations.first?.id, Scaffolding.meetingID)
        XCTAssertEqual(localStore.storeMeeting_Invocations.first?.title, Scaffolding.meetingResponse.title)
        XCTAssertEqual(localStore.storeMeeting_Invocations.first?.creatorID, Scaffolding.meetingResponse.creatorID)
        XCTAssertTrue(localStore.deleteMeetingId_Invocations.isEmpty)
    }

    func testPullMeeting_It_Deletes_Meeting_Missing_From_Backend_Response() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = []
        localStore.deleteMeetingId_MockMethod = { _ in }

        // When

        try await sut.pullMeeting(id: Scaffolding.meetingID)

        // Then

        XCTAssertTrue(localStore.storeMeeting_Invocations.isEmpty)
        XCTAssertEqual(localStore.deleteMeetingId_Invocations, [Scaffolding.meetingID])
    }

    func testPullMeeting_It_Throws_When_Listing_Meetings_Fails() async {
        // Mock

        meetingsAPI.listMeetings_MockError = MeetingsAPIError.meetingNotFound

        // When / Then

        do {
            try await sut.pullMeeting(id: Scaffolding.meetingID)
            XCTFail("expected an error to be thrown")
        } catch {
            XCTAssertTrue(localStore.storeMeeting_Invocations.isEmpty)
            XCTAssertTrue(localStore.deleteMeetingId_Invocations.isEmpty)
        }
    }

    // MARK: - deleteLocalMeeting

    func testDeleteLocalMeeting_It_Deletes_Meeting_From_Local_Store() async {
        // Mock

        localStore.deleteMeetingId_MockMethod = { _ in }

        // When

        await sut.deleteLocalMeeting(id: Scaffolding.meetingID)

        // Then

        XCTAssertEqual(localStore.deleteMeetingId_Invocations, [Scaffolding.meetingID])
    }

    // MARK: - fetchMeetingsStarting

    func testFetchMeetingsStarting_It_Refreshes_Store_And_Returns_Sorted_Upcoming_Meetings() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = [Scaffolding.meetingResponse]
        localStore.replaceAllMeetingsWith_MockMethod = { _ in }
        localStore.storedMeetings_MockValue = [
            Scaffolding.meeting(title: "B", start: Scaffolding.referenceDate.addingTimeInterval(3600)),
            Scaffolding.meeting(title: "A", start: Scaffolding.referenceDate.addingTimeInterval(3600)),
            Scaffolding.meeting(title: "Past", start: Scaffolding.referenceDate.addingTimeInterval(-3600))
        ]

        // When

        let meetings = try await sut.fetchMeetingsStarting(
            after: Scaffolding.referenceDate,
            offset: 0,
            limit: 10
        )

        // Then

        XCTAssertEqual(localStore.replaceAllMeetingsWith_Invocations.count, 1)
        XCTAssertEqual(meetings.map(\.title), ["A", "B"])
    }

    func testFetchMeetingsStarting_It_Serves_Stored_Meetings_When_Backend_Is_Unreachable() async throws {
        // Mock

        meetingsAPI.listMeetings_MockError = MeetingsAPIError.meetingNotFound
        localStore.storedMeetings_MockValue = [
            Scaffolding.meeting(title: "Stored", start: Scaffolding.referenceDate.addingTimeInterval(3600))
        ]

        // When

        let meetings = try await sut.fetchMeetingsStarting(
            after: Scaffolding.referenceDate,
            offset: 0,
            limit: 10
        )

        // Then

        XCTAssertEqual(meetings.map(\.title), ["Stored"])
    }

    func testFetchMeetingsStarting_It_Throws_When_Backend_Is_Unreachable_And_Store_Is_Empty() async {
        // Mock

        meetingsAPI.listMeetings_MockError = MeetingsAPIError.meetingNotFound
        localStore.storedMeetings_MockValue = []

        // When / Then

        do {
            _ = try await sut.fetchMeetingsStarting(
                after: Scaffolding.referenceDate,
                offset: 0,
                limit: 10
            )
            XCTFail("expected an error to be thrown")
        } catch {
            // expected
        }
    }

    // MARK: - hasUpcomingMeetings

    func testHasUpcomingMeetings_It_Returns_True_When_A_Stored_Meeting_Is_Upcoming() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = []
        localStore.replaceAllMeetingsWith_MockMethod = { _ in }
        localStore.storedMeetings_MockValue = [
            Scaffolding.meeting(title: "Upcoming", start: Scaffolding.referenceDate.addingTimeInterval(3600))
        ]

        // When / Then

        let hasUpcoming = try await sut.hasUpcomingMeetings(after: Scaffolding.referenceDate)
        XCTAssertTrue(hasUpcoming)
    }

    // MARK: - createMeeting

    func testCreateMeeting_It_Creates_Meeting_Via_API_And_Stores_It() async throws {
        // Mock

        meetingsAPI.createMeetingParameters_MockValue = Scaffolding.meetingResponse
        localStore.storeMeeting_MockMethod = { _ in }

        // When

        let meeting = try await sut.createMeeting(
            title: Scaffolding.meetingResponse.title,
            startTime: Scaffolding.meetingResponse.startTime,
            endTime: Scaffolding.meetingResponse.endTime,
            recurrence: nil
        )

        // Then

        XCTAssertEqual(meetingsAPI.createMeetingParameters_Invocations.count, 1)
        XCTAssertEqual(meeting.id, Scaffolding.meetingID)
        XCTAssertEqual(localStore.storeMeeting_Invocations.count, 1)
        XCTAssertEqual(localStore.storeMeeting_Invocations.first?.id, Scaffolding.meetingID)
    }

    private enum Scaffolding {

        static let referenceDate = Date(timeIntervalSince1970: 500_000)

        static let meetingID = WireNetwork.QualifiedID(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            domain: "example.com"
        )

        static let meetingResponse = MeetingResponse(
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

        static func meeting(title: String, start: Date) -> Meeting {
            Meeting(
                id: WireNetwork.QualifiedID(id: UUID(), domain: "example.com"),
                title: title,
                start: start,
                end: start.addingTimeInterval(3600),
                recurrence: nil,
                members: [],
                conversationID: WireNetwork.QualifiedID(id: UUID(), domain: "example.com")
            )
        }

    }

}

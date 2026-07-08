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

    // MARK: - Tests

    func testPullMeeting_It_Stores_Meeting_Contained_In_Backend_Response() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = [Scaffolding.meeting]
        localStore.storeMeeting_MockMethod = { _ in }

        // When

        try await sut.pullMeeting(id: Scaffolding.meetingID)

        // Then

        XCTAssertEqual(localStore.storeMeeting_Invocations.count, 1)
        XCTAssertEqual(localStore.storeMeeting_Invocations.first?.id, Scaffolding.meetingID)
        XCTAssertTrue(localStore.deleteMeetingIdDomain_Invocations.isEmpty)
    }

    func testPullMeeting_It_Deletes_Meeting_Missing_From_Backend_Response() async throws {
        // Mock

        meetingsAPI.listMeetings_MockValue = []
        localStore.deleteMeetingIdDomain_MockMethod = { _, _ in }

        // When

        try await sut.pullMeeting(id: Scaffolding.meetingID)

        // Then

        XCTAssertTrue(localStore.storeMeeting_Invocations.isEmpty)
        XCTAssertEqual(localStore.deleteMeetingIdDomain_Invocations.count, 1)
        XCTAssertEqual(localStore.deleteMeetingIdDomain_Invocations.first?.id, Scaffolding.meetingID.id)
        XCTAssertEqual(localStore.deleteMeetingIdDomain_Invocations.first?.domain, Scaffolding.meetingID.domain)
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
            XCTAssertTrue(localStore.deleteMeetingIdDomain_Invocations.isEmpty)
        }
    }

    func testDeleteLocalMeeting_It_Deletes_Meeting_From_Local_Store() async {
        // Mock

        localStore.deleteMeetingIdDomain_MockMethod = { _, _ in }

        // When

        await sut.deleteLocalMeeting(
            id: Scaffolding.meetingID.id,
            domain: Scaffolding.meetingID.domain
        )

        // Then

        XCTAssertEqual(localStore.deleteMeetingIdDomain_Invocations.count, 1)
        XCTAssertEqual(localStore.deleteMeetingIdDomain_Invocations.first?.id, Scaffolding.meetingID.id)
        XCTAssertEqual(localStore.deleteMeetingIdDomain_Invocations.first?.domain, Scaffolding.meetingID.domain)
    }

    private enum Scaffolding {

        static let meetingID = WireNetwork.QualifiedID(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            domain: "example.com"
        )

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

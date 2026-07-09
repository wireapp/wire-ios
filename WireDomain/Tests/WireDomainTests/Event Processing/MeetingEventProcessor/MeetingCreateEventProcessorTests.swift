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

import WireCallingDomainSupport
import WireNetwork
import XCTest

@testable import WireDomain

final class MeetingCreateEventProcessorTests: XCTestCase {

    private var sut: MeetingCreateEventProcessor!
    private var repository: MeetingRepositoryProtocolMock!

    override func setUp() async throws {
        try await super.setUp()
        repository = MeetingRepositoryProtocolMock()
        sut = MeetingCreateEventProcessor(
            repository: repository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        repository = nil
        sut = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Pulls_Meeting_From_Repository() async throws {
        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(repository.pullMeetingIdQualifiedIDVoidReceivedInvocations, [Scaffolding.meetingID])
    }

    func testProcessEvent_It_Throws_When_Pulling_Meeting_Fails() async {
        // Mock

        repository.pullMeetingIdQualifiedIDVoidThrowableError = MeetingsAPIError.meetingNotFound

        // When / Then

        do {
            try await sut.processEvent(Scaffolding.event)
            XCTFail("expected an error to be thrown")
        } catch {
            XCTAssertEqual(repository.pullMeetingIdQualifiedIDVoidReceivedInvocations, [Scaffolding.meetingID])
        }
    }

    private enum Scaffolding {

        static let meetingID = WireNetwork.QualifiedID(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            domain: "example.com"
        )

        static let event = MeetingCreateEvent(meetingID: meetingID)

    }

}

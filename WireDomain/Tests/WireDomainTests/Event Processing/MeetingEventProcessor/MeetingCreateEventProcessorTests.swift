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

final class MeetingCreateEventProcessorTests: XCTestCase {

    private var sut: MeetingCreateEventProcessor!
    private var repository: MockMeetingRepositoryProtocol!

    override func setUp() async throws {
        try await super.setUp()
        repository = MockMeetingRepositoryProtocol()
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
        // Mock

        repository.pullMeetingId_MockMethod = { _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(repository.pullMeetingId_Invocations, [Scaffolding.meetingID])
    }

    func testProcessEvent_It_Throws_When_Pulling_Meeting_Fails() async {
        // Mock

        repository.pullMeetingId_MockError = MeetingsAPIError.meetingNotFound

        // When / Then

        do {
            try await sut.processEvent(Scaffolding.event)
            XCTFail("expected an error to be thrown")
        } catch {
            XCTAssertEqual(repository.pullMeetingId_Invocations, [Scaffolding.meetingID])
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

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

final class MeetingDeleteEventProcessorTests: XCTestCase {

    private var sut: MeetingDeleteEventProcessor!
    private var localStore: MockMeetingLocalStoreProtocol!

    override func setUp() async throws {
        try await super.setUp()
        localStore = MockMeetingLocalStoreProtocol()
        sut = MeetingDeleteEventProcessor(
            localStore: localStore
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        localStore = nil
        sut = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Deletes_Meeting_From_Local_Store() async {
        // Mock

        localStore.deleteMeetingIdDomain_MockMethod = { _, _ in }

        // When

        await sut.processEvent(Scaffolding.event)

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

        static let event = MeetingDeleteEvent(meetingID: meetingID)

    }

}

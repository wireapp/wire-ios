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
import WireDataModel
import WireDataModelSupport
import WireNetwork
import XCTest

@testable import WireDomain

final class MeetingLocalStoreTests: XCTestCase {

    private var sut: MeetingLocalStore!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()

        sut = MeetingLocalStore(
            context: context
        )
    }

    override func tearDown() async throws {
        sut = nil
        stack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testStoreMeeting_It_Creates_Stored_Meeting_With_Relationships() async throws {
        // Given

        await context.perform { [modelHelper, context] in
            _ = modelHelper!.createUser(
                id: Scaffolding.creatorID.id,
                domain: Scaffolding.creatorID.domain,
                in: context
            )
            _ = modelHelper!.createGroupConversation(
                id: Scaffolding.conversationID.id,
                domain: Scaffolding.conversationID.domain,
                in: context
            )
        }

        // When

        await sut.storeMeeting(Scaffolding.meeting)

        // Then

        try await context.perform { [context] in
            let storedMeetings = try context.fetch(StoredMeeting.fetchRequest())
            XCTAssertEqual(storedMeetings.count, 1)

            let storedMeeting = try XCTUnwrap(storedMeetings.first)
            XCTAssertEqual(storedMeeting.remoteIdentifier, Scaffolding.meetingID.id)
            XCTAssertEqual(storedMeeting.domain, Scaffolding.meetingID.domain)
            XCTAssertEqual(storedMeeting.title, Scaffolding.meeting.title)
            XCTAssertEqual(storedMeeting.start, Scaffolding.meeting.start)
            XCTAssertEqual(storedMeeting.end, Scaffolding.meeting.end)
            XCTAssertEqual(storedMeeting.recurrenceFrequency, .weekly)
            XCTAssertEqual(storedMeeting.recurrenceInterval, 2)
            XCTAssertEqual(storedMeeting.recurrenceUntil, Scaffolding.recurrenceUntil)
            XCTAssertEqual(storedMeeting.conversation?.remoteIdentifier, Scaffolding.conversationID.id)
            XCTAssertEqual(storedMeeting.creator?.remoteIdentifier, Scaffolding.creatorID.id)
        }
    }

    func testStoreMeeting_It_Updates_Existing_Stored_Meeting() async throws {
        // Given

        await sut.storeMeeting(Scaffolding.meeting)

        let updatedMeeting = Meeting(
            id: Scaffolding.meetingID,
            title: "Renamed Meeting",
            start: Scaffolding.meeting.start,
            end: Scaffolding.meeting.end,
            recurrence: nil,
            members: [],
            conversationID: Scaffolding.conversationID,
            creatorID: Scaffolding.creatorID
        )

        // When

        await sut.storeMeeting(updatedMeeting)

        // Then

        try await context.perform { [context] in
            let storedMeetings = try context.fetch(StoredMeeting.fetchRequest())
            XCTAssertEqual(storedMeetings.count, 1)

            let storedMeeting = try XCTUnwrap(storedMeetings.first)
            XCTAssertEqual(storedMeeting.title, "Renamed Meeting")
            XCTAssertNil(storedMeeting.recurrenceFrequency)
        }
    }

    func testDeleteMeeting_It_Removes_Stored_Meeting() async throws {
        // Given

        await sut.storeMeeting(Scaffolding.meeting)

        // When

        await sut.deleteMeeting(id: Scaffolding.meetingID)

        // Then

        try await context.perform { [context] in
            let storedMeetings = try context.fetch(StoredMeeting.fetchRequest())
            XCTAssertTrue(storedMeetings.isEmpty)
        }
    }

    func testDeleteMeeting_It_Does_Nothing_For_Unknown_Meeting() async throws {
        // Given

        await sut.storeMeeting(Scaffolding.meeting)

        // When

        await sut.deleteMeeting(id: .init(id: UUID(), domain: Scaffolding.meetingID.domain))

        // Then

        try await context.perform { [context] in
            let storedMeetings = try context.fetch(StoredMeeting.fetchRequest())
            XCTAssertEqual(storedMeetings.count, 1)
        }
    }

    private enum Scaffolding {

        static let meetingID = WireNetwork.QualifiedID(
            id: UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!,
            domain: "example.com"
        )

        static let creatorID = WireNetwork.QualifiedID(
            id: UUID(uuidString: "b9ac57f4-05ae-46b8-9dbb-14e3e9b5f9c6")!,
            domain: "example.com"
        )

        static let conversationID = WireNetwork.QualifiedID(
            id: UUID(uuidString: "5a4c5b1c-2b5e-4b8a-9d4d-1a6e0e6a1b2c")!,
            domain: "example.com"
        )

        static let recurrenceUntil = Date(timeIntervalSince1970: 2_000_000)

        static let meeting = Meeting(
            id: meetingID,
            title: "Weekly Sync",
            start: Date(timeIntervalSince1970: 1_000_000),
            end: Date(timeIntervalSince1970: 1_003_600),
            recurrence: WireCallingDomain.MeetingRecurrence(
                frequency: .weekly,
                interval: 2,
                until: recurrenceUntil
            ),
            members: [],
            conversationID: conversationID,
            creatorID: creatorID
        )

    }

}

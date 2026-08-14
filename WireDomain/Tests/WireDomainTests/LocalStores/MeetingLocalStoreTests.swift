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

    func testStoredMeetings_It_Populates_Participants_From_The_Conversation() async throws {
        // Given

        await context.perform { [modelHelper, context] in
            let selfUser = modelHelper!.createSelfUser(
                id: UUID(),
                domain: Scaffolding.conversationID.domain,
                in: context
            )
            let bob = modelHelper!.createUser(
                id: Scaffolding.memberBobID.id,
                domain: Scaffolding.memberBobID.domain,
                name: "Bob Baker",
                handle: "bob",
                in: context
            )
            let alice = modelHelper!.createUser(
                id: Scaffolding.memberAliceID.id,
                domain: Scaffolding.memberAliceID.domain,
                name: "Alice Archer",
                handle: "alice",
                in: context
            )
            _ = modelHelper!.createUser(
                id: Scaffolding.creatorID.id,
                domain: Scaffolding.creatorID.domain,
                in: context
            )
            _ = modelHelper!.createGroupConversation(
                id: Scaffolding.conversationID.id,
                with: [selfUser, bob, alice],
                domain: Scaffolding.conversationID.domain,
                in: context
            )
        }

        await sut.storeMeeting(Scaffolding.meeting)

        // When

        let meetings = await sut.storedMeetings()

        // Then

        let meeting = try XCTUnwrap(meetings.first)
        let conversation = try XCTUnwrap(meeting.conversation)
        XCTAssertEqual(meeting.conversationID, Scaffolding.conversationID)
        XCTAssertEqual(conversation.participants.count, 3, "all local participants, including the self user")
        let alice = try XCTUnwrap(conversation.participants.first { $0.qualifiedID == Scaffolding.memberAliceID })
        XCTAssertEqual(alice.name, "Alice Archer")
        XCTAssertEqual(alice.handle, "alice")
        let bob = try XCTUnwrap(conversation.participants.first { $0.qualifiedID == Scaffolding.memberBobID })
        XCTAssertEqual(bob.name, "Bob Baker")
        XCTAssertEqual(bob.handle, "bob")
    }

    func testStoredMeeting_It_Returns_Meeting_With_Participants() async throws {
        // Given

        await context.perform { [modelHelper, context] in
            let alice = modelHelper!.createUser(
                id: Scaffolding.memberAliceID.id,
                domain: Scaffolding.memberAliceID.domain,
                name: "Alice Archer",
                handle: "alice",
                in: context
            )
            _ = modelHelper!.createUser(
                id: Scaffolding.creatorID.id,
                domain: Scaffolding.creatorID.domain,
                in: context
            )
            _ = modelHelper!.createGroupConversation(
                id: Scaffolding.conversationID.id,
                with: [alice],
                domain: Scaffolding.conversationID.domain,
                in: context
            )
        }

        await sut.storeMeeting(Scaffolding.meeting)

        // When

        let meeting = await sut.storedMeeting(id: Scaffolding.meetingID)

        // Then

        let unwrappedMeeting = try XCTUnwrap(meeting)
        XCTAssertEqual(unwrappedMeeting.id, Scaffolding.meetingID)
        XCTAssertEqual(unwrappedMeeting.conversation?.participants.map(\.qualifiedID), [Scaffolding.memberAliceID])
    }

    func testStoredMeeting_It_Returns_Nil_For_Unknown_Meeting() async throws {
        // Given

        await sut.storeMeeting(Scaffolding.meeting)

        // When

        let meeting = await sut.storedMeeting(id: .init(id: UUID(), domain: Scaffolding.meetingID.domain))

        // Then

        XCTAssertNil(meeting)
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

    // MARK: - observeMeetingConversationChanges

    func testObserveMeetingConversationChanges_It_Emits_When_A_Participant_Joins() async throws {
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

        await sut.storeMeeting(Scaffolding.meeting)

        var changes = sut.observeMeetingConversationChanges().makeAsyncIterator()

        // When

        await context.perform { [modelHelper, context] in
            let conversation = ZMConversation.fetch(
                with: Scaffolding.conversationID.id,
                domain: Scaffolding.conversationID.domain,
                in: context
            )
            let member = modelHelper!.createUser(
                id: Scaffolding.memberAliceID.id,
                domain: Scaffolding.memberAliceID.domain,
                in: context
            )
            conversation?.addParticipantAndUpdateConversationState(user: member, role: nil)
            context.processPendingChanges()
        }

        // Then — the yielded event is buffered by the stream

        let change = await changes.next()
        XCTAssertNotNil(change)
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

        static let memberAliceID = WireNetwork.QualifiedID(
            id: UUID(uuidString: "0f8b0c2f-6cb0-4c11-9b0f-1e2d3c4b5a69")!,
            domain: "example.com"
        )

        static let memberBobID = WireNetwork.QualifiedID(
            id: UUID(uuidString: "7c1d2e3f-4a5b-4c6d-8e9f-0a1b2c3d4e5f")!,
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
            conversationID: conversationID,
            creatorID: creatorID
        )

    }

}

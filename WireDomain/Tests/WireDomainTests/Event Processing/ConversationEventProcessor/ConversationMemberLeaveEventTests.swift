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

import WireCallingData
import WireCallingDomain
import WireDomainSupport
import XCTest

@testable import WireDomain
@testable import WireNetwork

final class ConversationMemberLeaveEventProcessorTests: XCTestCase {

    private var sut: ConversationMemberLeaveEventProcessor!
    private var repository: MockConversationRepositoryProtocol!
    private var meetingLocalStore: MeetingLocalStoreSpy!
    private var reminderCanceller: MemberLeaveReminderCancellerSpy!
    private let accountID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!

    override func setUp() async throws {
        try await super.setUp()
        repository = MockConversationRepositoryProtocol()
        meetingLocalStore = MeetingLocalStoreSpy()
        reminderCanceller = MemberLeaveReminderCancellerSpy()
        sut = ConversationMemberLeaveEventProcessor(
            repository: repository,
            meetingLocalStore: meetingLocalStore,
            reminderCanceller: reminderCanceller,
            accountID: accountID
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        repository = nil
        meetingLocalStore = nil
        reminderCanceller = nil
        sut = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Remove_Members_Repo_Method() async throws {
        // Mock

        repository.removeMembersFromInitiatedByAtReason_MockMethod = { _, _, _, _, _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(repository.removeMembersFromInitiatedByAtReason_Invocations.count, 1)
    }

    func testProcessEvent_It_Throws_Error() async throws {
        // Mock

        enum MockError: Error {
            case failed
        }

        repository.removeMembersFromInitiatedByAtReason_MockError = MockError.failed

        do {
            // When
            try await sut.processEvent(Scaffolding.event)
        } catch {
            // Then
            XCTAssertTrue(error is ConversationMemberLeaveEventProcessor.Error)
        }
    }

    func testProcessEvent_CancelsMeetingsWhenSelfUserLeavesTheirConversation() async throws {
        repository.removeMembersFromInitiatedByAtReason_MockMethod = { _, _, _, _, _ in }
        let conversationID = ConversationID(id: UUID(), domain: "domain.com")
        let matchingMeeting = Scaffolding.meeting(conversationID: conversationID)
        let otherDomain = Scaffolding.meeting(
            conversationID: ConversationID(id: conversationID.id, domain: "other.com")
        )
        meetingLocalStore.meetings = [matchingMeeting, otherDomain]
        let event = ConversationMemberLeaveEvent(
            conversationID: conversationID,
            senderID: UserID(id: accountID, domain: "domain.com"),
            timestamp: .now,
            removedUserIDs: [UserID(id: accountID, domain: "domain.com")],
            reason: .userDeleted
        )

        try await sut.processEvent(event)

        XCTAssertEqual(reminderCanceller.cancellations.count, 1)
        XCTAssertEqual(reminderCanceller.cancellations[0].accountID, accountID)
        XCTAssertEqual(reminderCanceller.cancellations[0].meetingID, matchingMeeting.id)
        XCTAssertEqual(meetingLocalStore.deletedMeetingIDs, [matchingMeeting.id])
        XCTAssertEqual(meetingLocalStore.meetings.map(\.id), [otherDomain.id])
    }

    func testProcessEvent_DoesNotCancelWhenAnotherUserLeaves() async throws {
        repository.removeMembersFromInitiatedByAtReason_MockMethod = { _, _, _, _, _ in }
        let conversationID = ConversationID(id: UUID(), domain: "domain.com")
        meetingLocalStore.meetings = [Scaffolding.meeting(conversationID: conversationID)]
        let event = ConversationMemberLeaveEvent(
            conversationID: conversationID,
            senderID: UserID(id: UUID(), domain: "domain.com"),
            timestamp: .now,
            removedUserIDs: [UserID(id: UUID(), domain: "domain.com")],
            reason: .userDeleted
        )

        try await sut.processEvent(event)

        XCTAssertTrue(reminderCanceller.cancellations.isEmpty)
        XCTAssertTrue(meetingLocalStore.deletedMeetingIDs.isEmpty)
    }

    private enum Scaffolding {
        static let event = ConversationMemberLeaveEvent(
            conversationID: ConversationID(id: UUID(), domain: "domain.com"),
            senderID: UserID(id: UUID(), domain: "domain.com"),
            timestamp: .now,
            removedUserIDs: [],
            reason: .userDeleted
        )

        static func meeting(conversationID: ConversationID) -> Meeting {
            Meeting(
                id: WireCallingDomain.QualifiedID(id: UUID(), domain: "domain.com"),
                title: "Meeting",
                start: .now,
                end: .now.addingTimeInterval(3600),
                recurrence: nil,
                conversationID: WireCallingDomain.QualifiedID(
                    id: conversationID.id,
                    domain: conversationID.domain
                ),
                creatorID: WireCallingDomain.QualifiedID(id: UUID(), domain: "domain.com")
            )
        }
    }
}

private final class MeetingLocalStoreSpy: MeetingLocalStoreProtocol, @unchecked Sendable {
    var meetings: [Meeting] = []
    var deletedMeetingIDs: [WireCallingDomain.QualifiedID] = []

    func storedMeetings() async -> [Meeting] { meetings }
    func storedMeeting(id: WireCallingDomain.QualifiedID) async -> Meeting? { meetings.first { $0.id == id } }
    func storeMeeting(_ meeting: Meeting) async {}
    func replaceAllMeetings(with meetings: [Meeting]) async {}
    func deleteMeeting(id: WireCallingDomain.QualifiedID) async {
        deletedMeetingIDs.append(id)
        meetings.removeAll { $0.id == id }
    }
}

private final class MemberLeaveReminderCancellerSpy: MeetingReminderCancelling {
    var cancellations: [(accountID: UUID, meetingID: WireCallingDomain.QualifiedID)] = []

    func cancelAll(accountID: UUID, meetingID: WireCallingDomain.QualifiedID) async {
        cancellations.append((accountID, meetingID))
    }
}

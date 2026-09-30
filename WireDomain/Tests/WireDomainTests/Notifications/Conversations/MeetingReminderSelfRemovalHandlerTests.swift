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

import Foundation
import UserNotifications
import WireCallingDomain
import WireNetwork
import XCTest

@testable import WireDomain

final class MeetingReminderSelfRemovalHandlerTests: XCTestCase {

    private let accountID = UUID()
    private let conversationID = WireNetwork.QualifiedID(id: UUID(), domain: "example.com")

    func testSelfRemovalCancelsStoredMeetingAndMatchingPendingRequests() async {
        let spy = SelfRemovalSpy()
        let meeting = makeMeeting()
        spy.meetings = [meeting, makeMeeting(conversationID: .init(id: UUID(), domain: "example.com"))]

        await makeHandler(spy: spy).handle(event: makeEvent(removedUserID: accountID))

        XCTAssertEqual(spy.cancelledMeetingIDs, [meeting.id])
        XCTAssertEqual(spy.pendingConversationIDs, [conversationID])
    }

    func testMissingLocalMeetingStillChecksPendingRequests() async {
        let spy = SelfRemovalSpy()

        await makeHandler(spy: spy).handle(event: makeEvent(removedUserID: accountID, senderID: accountID))

        XCTAssertTrue(spy.cancelledMeetingIDs.isEmpty)
        XCTAssertEqual(spy.pendingConversationIDs, [conversationID])
    }

    func testRemovalOfAnotherUserDoesNotCancelReminders() async {
        let spy = SelfRemovalSpy()
        spy.meetings = [makeMeeting()]

        await makeHandler(spy: spy).handle(event: makeEvent(removedUserID: UUID()))

        XCTAssertFalse(spy.didReadMeetings)
        XCTAssertTrue(spy.cancelledMeetingIDs.isEmpty)
        XCTAssertTrue(spy.pendingConversationIDs.isEmpty)
    }

    func testPendingRequestMatchingIsScopedToAccountAndQualifiedConversation() {
        let meeting = makeMeeting()
        let occurrenceStart = Date(timeIntervalSince1970: 2_000_000_000)
        let content = MeetingReminderNotificationContentBuilder().build(
            meeting: meeting,
            occurrenceStart: occurrenceStart,
            accountID: accountID,
            showMeetingTitle: false
        )
        let matchingID = MeetingReminder(
            accountID: accountID,
            meetingID: meeting.id,
            occurrenceStart: occurrenceStart
        ).identifier
        let otherAccountID = MeetingReminder(
            accountID: UUID(),
            meetingID: meeting.id,
            occurrenceStart: occurrenceStart
        ).identifier
        let otherDomainMeeting = makeMeeting(conversationID: .init(id: conversationID.id, domain: "other.com"))
        let otherDomainContent = MeetingReminderNotificationContentBuilder().build(
            meeting: otherDomainMeeting,
            occurrenceStart: occurrenceStart,
            accountID: accountID,
            showMeetingTitle: false
        )
        let requests = [
            UNNotificationRequest(identifier: matchingID, content: content, trigger: nil),
            UNNotificationRequest(identifier: otherAccountID, content: content, trigger: nil),
            UNNotificationRequest(identifier: "other-feature", content: content, trigger: nil),
            UNNotificationRequest(identifier: "\(matchingID)-other-domain", content: otherDomainContent, trigger: nil)
        ]

        let identifiers = MeetingReminderPendingRequestCanceller.matchingIdentifiers(
            in: requests,
            accountID: accountID,
            conversationID: conversationID
        )

        XCTAssertEqual(identifiers, [matchingID])
    }

    private func makeHandler(spy: SelfRemovalSpy) -> MeetingReminderSelfRemovalHandler {
        MeetingReminderSelfRemovalHandler(
            accountID: accountID,
            storedMeetings: {
                spy.didReadMeetings = true
                return spy.meetings
            },
            cancelMeeting: { spy.cancelledMeetingIDs.append($0) },
            cancelPendingRequests: { spy.pendingConversationIDs.append($0) }
        )
    }

    private func makeEvent(removedUserID: UUID, senderID: UUID = UUID()) -> ConversationMemberLeaveEvent {
        ConversationMemberLeaveEvent(
            conversationID: conversationID,
            senderID: .init(id: senderID, domain: "example.com"),
            timestamp: .now,
            removedUserIDs: [.init(id: removedUserID, domain: "example.com")],
            reason: .userRemoved
        )
    }

    private func makeMeeting(conversationID: WireNetwork.QualifiedID? = nil) -> Meeting {
        Meeting(
            id: .init(id: UUID(), domain: "example.com"),
            title: "Planning",
            start: Date(timeIntervalSince1970: 2_000_000_000),
            end: Date(timeIntervalSince1970: 2_000_003_600),
            recurrence: nil,
            conversationID: conversationID ?? self.conversationID,
            creatorID: .init(id: UUID(), domain: "example.com")
        )
    }

}

private final class SelfRemovalSpy {
    var meetings: [Meeting] = []
    var didReadMeetings = false
    var cancelledMeetingIDs: [WireNetwork.QualifiedID] = []
    var pendingConversationIDs: [WireNetwork.QualifiedID] = []
}

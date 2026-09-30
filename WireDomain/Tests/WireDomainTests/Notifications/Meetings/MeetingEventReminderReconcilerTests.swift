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
import WireCallingDomain
import WireNetwork
import XCTest

@testable import WireDomain

final class MeetingEventReminderReconcilerTests: XCTestCase {

    private let meetingID = WireNetwork.QualifiedID(id: UUID(), domain: "example.com")

    func testCreateInvitationAndUpdateFetchCurrentMeetingAndReconcile() async {
        let spy = ReminderReconciliationSpy()
        let meeting = makeMeeting()
        spy.meeting = meeting
        let reconciler = makeReconciler(spy: spy)

        await reconciler.reconcile(event: .create(.init(meetingID: meetingID)))
        await reconciler.reconcile(event: .memberAdd(.init(meetingID: meetingID, senderID: meeting.creatorID)))
        await reconciler.reconcile(event: .update(.init(meetingID: meetingID)))

        XCTAssertEqual(spy.pulledIDs, [meetingID, meetingID, meetingID])
        XCTAssertEqual(spy.reconciledMeetings, [meeting, meeting, meeting])
        XCTAssertTrue(spy.cancelledIDs.isEmpty)
    }

    func testDeleteCancelsWithoutFetchingMeeting() async {
        let spy = ReminderReconciliationSpy()

        await makeReconciler(spy: spy).reconcile(event: .delete(.init(meetingID: meetingID)))

        XCTAssertEqual(spy.cancelledIDs, [meetingID])
        XCTAssertTrue(spy.pulledIDs.isEmpty)
    }

    func testMissingMeetingCancelsReminder() async {
        let spy = ReminderReconciliationSpy()

        await makeReconciler(spy: spy).reconcile(event: .update(.init(meetingID: meetingID)))

        XCTAssertEqual(spy.cancelledIDs, [meetingID])
        XCTAssertTrue(spy.reconciledMeetings.isEmpty)
    }

    func testFetchFailurePreservesPendingReminder() async {
        let spy = ReminderReconciliationSpy()
        spy.fetchError = ReminderFetchError.unavailable

        await makeReconciler(spy: spy).reconcile(event: .update(.init(meetingID: meetingID)))

        XCTAssertEqual(spy.pulledIDs, [meetingID])
        XCTAssertTrue(spy.cancelledIDs.isEmpty)
        XCTAssertTrue(spy.reconciledMeetings.isEmpty)
    }

    func testCreateReconcilesWithoutVisibleNotification() async {
        let spy = ReminderReconciliationSpy()
        spy.meeting = makeMeeting()
        let builder = MeetingEventNotificationBuilder(
            meetingDeleteEventBuilder: NoMeetingDeleteNotification(),
            meetingMemberAddEventBuilder: NoMeetingMemberAddNotification(),
            meetingUpdateEventBuilder: NoMeetingUpdateNotification(),
            reminderReconciler: makeReconciler(spy: spy)
        )

        let notification = await builder.buildContent(event: .create(.init(meetingID: meetingID)))

        XCTAssertNil(notification)
        XCTAssertEqual(spy.reconciledMeetings.count, 1)
        XCTAssertEqual(spy.reconciledMeetings.first, spy.meeting)
    }

    private func makeMeeting() -> Meeting {
        Meeting(
            id: meetingID,
            title: "Planning",
            start: Date(timeIntervalSince1970: 1_800_000_000),
            end: Date(timeIntervalSince1970: 1_800_003_600),
            recurrence: nil,
            conversationID: .init(id: UUID(), domain: "example.com"),
            creatorID: .init(id: UUID(), domain: "example.com")
        )
    }

    private func makeReconciler(spy: ReminderReconciliationSpy) -> MeetingEventReminderReconciler {
        MeetingEventReminderReconciler(
            pullMeeting: { meetingID in
                spy.pulledIDs.append(meetingID)
                if let error = spy.fetchError { throw error }
                return spy.meeting
            },
            reconcileMeeting: { spy.reconciledMeetings.append($0) },
            cancelMeeting: { spy.cancelledIDs.append($0) }
        )
    }

}

private final class ReminderReconciliationSpy {
    var meeting: Meeting?
    var fetchError: (any Error)?
    var pulledIDs: [WireNetwork.QualifiedID] = []
    var reconciledMeetings: [Meeting] = []
    var cancelledIDs: [WireNetwork.QualifiedID] = []
}

private enum ReminderFetchError: Error {
    case unavailable
}

private struct NoMeetingDeleteNotification: MeetingDeleteEventNotificationBuilderProtocol {
    func buildContent(event: MeetingDeleteEvent) async -> UserNotification? { nil }
}

private struct NoMeetingMemberAddNotification: MeetingMemberAddEventNotificationBuilderProtocol {
    func buildContent(event: MeetingMemberAddEvent) async -> UserNotification? { nil }
}

private struct NoMeetingUpdateNotification: MeetingUpdateEventNotificationBuilderProtocol {
    func buildContent(event: MeetingUpdateEvent) async -> UserNotification? { nil }
}

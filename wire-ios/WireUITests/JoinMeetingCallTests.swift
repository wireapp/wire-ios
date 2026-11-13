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

import notify
import WireLocators
import WireNetwork
import XCTest

/// [collaboration]
final class JoinMeetingCallTests: WireUITestCase, MeetingJoinTesting {

    @MainActor
    func testHostAndInviteeJoinExistingMeetingCall_TC_12021() async throws {
        executionTimeAllowance = 900
        let start = try tomorrowAtNoon()
        let fixture = try await makeMeeting(
            title: "TC12021 shared call",
            start: start,
            asHost: false,
            withPeer: true,
            now: start.addingTimeInterval(30)
        )
        let peerID = try XCTUnwrap(fixture.peerID)

        // The invitee starts the call. The peer stays connected while the host joins.
        async let accepting: Void = armPeer(peerID)
        let inviteeCall = try join(fixture.meeting, on: fixture.page, start: start)
        try await accepting
        let callID = try await assertPeer(peerID, user: fixture.invitee, meeting: fixture.meeting)
        _ = try leaveCall(inviteeCall)

        let hostPage = try launchMeetings(for: fixture.host, now: start.addingTimeInterval(45))
        let hostCall = try join(fixture.meeting, on: hostPage, start: start)
        _ = try await assertPeer(peerID, user: fixture.host, meeting: fixture.meeting, callID: callID)
        capture("TC12021 host joined the invitee call")
        _ = try leaveCall(hostCall)
        try await callingManager.stopCurrentCall(instanceId: peerID)
    }

    @MainActor
    func testHostAndInviteeJoinFutureMeetingWithJoinNow_TC_12026() async throws {
        executionTimeAllowance = 900
        for isHost in [false, true] {
            let start = try tomorrowAtNoon()
            let fixture = try await makeMeeting(
                title: isHost ? "TC12026 host early join" : "TC12026 invitee early join",
                start: start,
                asHost: isHost,
                withPeer: true
            )
            let peerID = try XCTUnwrap(fixture.peerID)

            // Join now starts the future meeting before its scheduled time.
            async let accepting: Void = armPeer(peerID)
            let call = try join(fixture.meeting, on: fixture.page, start: start, fromMenu: true)
            try await accepting
            let callID = try await assertPeer(peerID, user: fixture.user, meeting: fixture.meeting)
            capture(isHost ? "TC12026 host joined early" : "TC12026 invitee joined early")

            // Leave, then rejoin the existing call through Join now.
            let page = try leaveCall(call)
            let rejoinedCall = try join(fixture.meeting, on: page, start: start, fromMenu: true)
            _ = try await assertPeer(peerID, user: fixture.user, meeting: fixture.meeting, callID: callID)
            _ = try leaveCall(rejoinedCall)
            try await callingManager.stopCurrentCall(instanceId: peerID)
        }
    }

    @MainActor
    func testInviteeRejoinsRescheduledMeetingWithJoinNow_TC_12027() async throws {
        executionTimeAllowance = 900
        let start = try tomorrowAtNoon()
        let fixture = try await makeMeeting(
            title: "TC12027 rejoin rescheduled meeting",
            start: start,
            asHost: false,
            withPeer: true,
            now: start.addingTimeInterval(30)
        )
        let peerID = try XCTUnwrap(fixture.peerID)

        // Join, leave, and rejoin before the host reschedules the meeting.
        async let accepting: Void = armPeer(peerID)
        var page = fixture.page
        let firstCall = try join(fixture.meeting, on: page, start: start)
        try await accepting
        let callID = try await assertPeer(peerID, user: fixture.invitee, meeting: fixture.meeting)
        page = try leaveCall(firstCall)

        let secondCall = try join(fixture.meeting, on: page, start: start, fromMenu: true)
        _ = try await assertPeer(peerID, user: fixture.invitee, meeting: fixture.meeting, callID: callID)
        page = try leaveCall(secondCall)

        let rescheduledStart = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: start))
        let updated = try await fixture.fixtures.update(meeting: fixture.meeting, start: rescheduledStart)
        let row = try page.showRow(updated, start: rescheduledStart)
        let joinButton = row.descendants(matching: .any)[Locators.WireMeetings.MeetingRow.joinButton.rawValue]
        XCTAssertFalse(joinButton.exists, "Normal Join appeared outside the scheduled window")

        // Join now must reconnect to the same active call after the schedule change.
        let rejoinedCall = try join(updated, on: page, start: rescheduledStart, fromMenu: true)
        _ = try await assertPeer(peerID, user: fixture.invitee, meeting: updated, callID: callID)
        XCTAssertEqual(updated.id, fixture.meeting.id)
        XCTAssertEqual(updated.conversationID, fixture.meeting.conversationID)
        capture("TC12027 rejoined the rescheduled meeting")
        _ = try leaveCall(rejoinedCall)
        try await callingManager.stopCurrentCall(instanceId: peerID)
    }

    @MainActor
    func testHostAndInviteeJoinRecurringMeetingWithJoinNow_TC_12028() async throws {
        executionTimeAllowance = 900
        let calendar = Calendar.current
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: Date()))
        let start = try XCTUnwrap(calendar.date(bySettingHour: 12, minute: 0, second: 0, of: tomorrow))
        let futureStart = try XCTUnwrap(calendar.date(byAdding: .weekOfYear, value: 1, to: start))
        let until = try XCTUnwrap(calendar.date(byAdding: .weekOfYear, value: 2, to: start))

        for isHost in [false, true] {
            let id = UUID().uuidString
            let starts = try callControl(id, state: "starts")
            let conversation = try callControl(id, state: "conversation")
            defer { notify_cancel(starts); notify_cancel(conversation) }
            XCTAssertEqual(notify_set_state(starts, 0), UInt32(NOTIFY_STATUS_OK))
            XCTAssertEqual(notify_set_state(conversation, 0), UInt32(NOTIFY_STATUS_OK))
            uiTestConfig.meetingsCallControlID = id
            let fixture = try await makeMeeting(
                title: isHost ? "TC12028 host recurring join" : "TC12028 invitee recurring join",
                start: start,
                recurrence: MeetingRecurrence(frequency: .weekly, interval: 1, until: until),
                asHost: isHost
            )
            try await requireConferenceCalling()
            let row = try fixture.page.showRow(fixture.meeting, start: futureStart)
            XCTAssertEqual(
                row.staticTexts[Locators.WireMeetings.MeetingRow.recurrence.rawValue].label,
                "Weekly"
            )

            // Join now must use this future occurrence of the recurring meeting.
            let call = try join(fixture.meeting, on: fixture.page, start: futureStart, fromMenu: true)
            try assertCallStarts(1, starts: starts, conversation: conversation)

            // Joining must preserve the series saved during setup.
            let stored = try await fixture.fixtures.list()
            let persisted = try XCTUnwrap(stored.first { $0.id == fixture.meeting.id })
            XCTAssertEqual(persisted.conversationID, fixture.meeting.conversationID)
            XCTAssertEqual(persisted.recurrence?.frequency, .weekly)
            XCTAssertEqual(persisted.recurrence?.interval, 1)
            XCTAssertEqual(persisted.recurrence?.until, fixture.meeting.recurrence?.until)
            capture(isHost ? "TC12028 host joined recurring meeting" : "TC12028 invitee joined recurring meeting")
            _ = try leaveCall(call)
        }
    }

    private func tomorrowAtNoon() throws -> Date {
        // Keep both fixture times on one day when the form edits the meeting.
        let calendar = Calendar.current
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: Date()))
        return try XCTUnwrap(calendar.date(bySettingHour: 12, minute: 0, second: 0, of: tomorrow))
    }
}

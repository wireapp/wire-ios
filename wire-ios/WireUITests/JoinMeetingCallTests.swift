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

import WireLocators
import WireNetwork
import XCTest

/// [collaboration]
final class JoinMeetingCallTests: WireUITestCase, MeetingJoinTesting {

    @MainActor
    func testHostAndInviteeJoinExistingMeetingCall_TC_12021() async throws {
        executionTimeAllowance = 900
        let start = Date().addingTimeInterval(3600)
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
            let start = Date().addingTimeInterval(3600)
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
        let start = Date().addingTimeInterval(3600)
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

        let rescheduledStart = Date().addingTimeInterval(86_400)
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

}

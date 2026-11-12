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
import WireFoundation
import WireLocators
import WireNetwork
import XCTest

/// [collaboration]
final class JoinMeetingRetryTests: WireUITestCase, MeetingJoinTesting {

    @MainActor
    func testRepeatedJoinDoesNotStartDuplicateCalls_TC_12030() async throws {
        executionTimeAllowance = 900
        for fromMenu in [false, true] {
            let id = UUID().uuidString
            let starts = try callControl(id, state: "starts")
            let conversation = try callControl(id, state: "conversation")
            defer { notify_cancel(starts); notify_cancel(conversation) }
            XCTAssertEqual(notify_set_state(starts, 0), UInt32(NOTIFY_STATUS_OK))
            XCTAssertEqual(notify_set_state(conversation, 0), UInt32(NOTIFY_STATUS_OK))
            uiTestConfig.meetingsCallControlID = id
            uiTestConfig.meetingsJoinDelay = 2
            let start = Date().addingTimeInterval(3600)
            let fixture = try await makeMeeting(
                title: fromMenu ? "TC12030 Join now" : "TC12030 Join", start: start,
                now: start.addingTimeInterval(60)
            )
            try await requireConferenceCalling()

            // Send a tap burst to the visible action during delayed MLS setup.
            if fromMenu { try fixture.page.openMenu(for: fixture.meeting) }
            let action = fromMenu ? app.buttons["Join now"] : joinButton(fixture.meeting, on: fixture.page)
            guard action.waitForExistence(timeout: 5), action.isEnabled, action.isHittable else {
                throw RuntimeError("The Join action was not available for rapid taps")
            }
            action.tap(withNumberOfTaps: 5, numberOfTouches: 1)
            let call = try waitForCall(title: fixture.meeting.title)
            try assertCallStarts(1, starts: starts, conversation: conversation)
            capture("TC12030 repeated taps")

            // Require one established call and confirm that its controls respond.
            XCTAssertEqual(app.staticTexts.matching(identifier: Locators.OngoingCallPage.timeLabel.rawValue).count, 1)
            _ = try leaveCall(call)
        }
    }

    @MainActor
    func testInviteeRetriesJoinAfterOfflineError_TC_12031() async throws {
        executionTimeAllowance = 900
        for fromMenu in [false, true] {
            let id = UUID().uuidString
            let offline = try callControl(id, state: "offline")
            defer { notify_cancel(offline) }
            XCTAssertEqual(notify_set_state(offline, 0), UInt32(NOTIFY_STATUS_OK))
            uiTestConfig.meetingsCallControlID = id
            let start = Date().addingTimeInterval(3600)
            let fixture = try await makeMeeting(
                title: fromMenu ? "TC12031 Join now" : "TC12031 Join", start: start,
                withPeer: true, now: start.addingTimeInterval(60)
            )
            let peerID = try XCTUnwrap(fixture.peerID)
            async let accepting: Void = armPeer(peerID)

            // Force the existing offline guard and check its alert before any call starts.
            XCTAssertEqual(notify_set_state(offline, 1), UInt32(NOTIFY_STATUS_OK))
            if fromMenu { try fixture.page.openMenu(for: fixture.meeting) }
            let action = fromMenu ? app.buttons["Join now"] : joinButton(fixture.meeting, on: fixture.page)
            guard action.waitAndTap() else { throw RuntimeError("The Join action did not respond") }
            let alert = app.alerts["No Internet Connection"]
            guard alert.waitForExistence(timeout: 10)
            else { throw RuntimeError("The offline call alert did not appear") }
            XCTAssertTrue(alert.staticTexts["You must be online to call. Check your connection and try again."].exists)
            XCTAssertFalse(app.buttons[Locators.OngoingCallPage.endOngoingCallButton.rawValue].exists)
            let status = try await callingServiceClient.getInstanceStatus(instanceIds: [peerID])
            let peer = try XCTUnwrap(status.first)
            XCTAssertTrue(peer.currentCall?.conversationId?.isEmpty ?? true)
            XCTAssertNotEqual(peer.currentCall?.status?.uppercased(), "ACTIVE")
            capture("TC12031 offline alert")
            guard alert.buttons["OK"].waitAndTap() else { throw RuntimeError("The offline alert did not close") }

            // Restore the guard, then repeat the same action through the real call path.
            XCTAssertEqual(notify_set_state(offline, 0), UInt32(NOTIFY_STATUS_OK))
            let call = try join(fixture.meeting, on: fixture.page, fromMenu: fromMenu)
            try await accepting
            _ = try await assertPeer(peerID, user: fixture.user, meeting: fixture.meeting)
            _ = try leaveCall(call)
            try await callingManager.stopCurrentCall(instanceId: peerID)
        }
    }

}

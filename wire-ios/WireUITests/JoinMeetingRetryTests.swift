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
            let requests = try callControl(id, state: "requests")
            defer { notify_cancel(requests) }
            XCTAssertEqual(notify_set_state(requests, 0), UInt32(NOTIFY_STATUS_OK))
            uiTestConfig.meetingsCallControlID = id
            uiTestConfig.meetingsJoinDelay = 15
            let start = Date().addingTimeInterval(3600)
            let fixture = try await makeMeeting(
                title: fromMenu ? "TC12030 Join now" : "TC12030 Join", start: start,
                withPeer: true, now: start.addingTimeInterval(60)
            )
            let peerID = try XCTUnwrap(fixture.peerID)
            async let accepting: Void = armPeer(peerID)

            // Repeat the action while the real call bridge is delayed.
            if fromMenu {
                for _ in 0 ..< 3 {
                    try fixture.page.openMenu(for: fixture.meeting)
                    guard app.buttons["Join now"].waitAndTap() else { throw RuntimeError("Join now did not respond") }
                }
            } else {
                joinButton(fixture.meeting, on: fixture.page).tap(withNumberOfTaps: 5, numberOfTouches: 1)
            }
            let call = try waitForCall(title: fixture.meeting.title)
            var count: UInt64 = 0
            XCTAssertEqual(notify_get_state(requests, &count), UInt32(NOTIFY_STATUS_OK))
            capture("TC12030 repeated taps")
            guard count == 1 else {
                throw RuntimeError("TC-12030 requires one join operation; the call bridge received \(count)")
            }

            // Require one connected peer and one attended meeting.
            try await accepting
            _ = try await assertPeer(peerID, user: fixture.user, meeting: fixture.meeting)
            XCTAssertEqual(app.staticTexts.matching(identifier: Locators.OngoingCallPage.timeLabel.rawValue).count, 1)
            _ = try leaveCall(call)
            try await callingManager.stopCurrentCall(instanceId: peerID)
        }
    }

    private func callControl(_ id: String, state: String) throws -> Int32 {
        let name = "\(UITestConfig.meetingsCallControlNotificationPrefix).\(id).\(state)"
        var token: Int32 = NOTIFY_TOKEN_INVALID
        guard notify_register_check(name, &token) == NOTIFY_STATUS_OK else {
            throw RuntimeError("The Meetings call control could not be registered")
        }
        return token
    }
}

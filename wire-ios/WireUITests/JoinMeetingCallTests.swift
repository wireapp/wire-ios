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

}

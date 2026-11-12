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
final class JoinMeetingVisibilityTests: WireUITestCase, MeetingJoinTesting {

    @MainActor
    func testJoinVisibilityFollowsMeetingWindow_TC_12019() async throws {
        executionTimeAllowance = 900

        // Check both roles with a separate meeting for each user.
        let hostFixture = try await makeMeeting(
            title: "TC12019 host join window",
            start: Date().addingTimeInterval(86_400),
            duration: 60,
            asHost: true
        )
        try await assertJoinWindow(hostFixture)

        let inviteeFixture = try await makeMeeting(
            title: "TC12019 invitee join window",
            start: Date().addingTimeInterval(86_400),
            duration: 60,
            asHost: false
        )
        try await assertJoinWindow(inviteeFixture)
    }

    private func nextMinute(after date: Date) -> Date {
        Calendar.current.nextDate(
            after: date,
            matching: DateComponents(second: 0),
            matchingPolicy: .nextTime
        )!
    }

    @MainActor
    private func assertJoinWindow(
        _ fixture: MeetingJoinFixture
    ) async throws {
        let start = nextMinute(after: Date().addingTimeInterval(90))
        let meeting = try await fixture.fixtures.update(meeting: fixture.meeting, start: start, duration: 60)
        let row = fixture.page.row(meeting, start: start)
        let join = joinButton(meeting, on: fixture.page, start: start)

        // Check before the live window.
        guard row.waitForExistence(timeout: 20) else { throw RuntimeError("The rescheduled meeting did not appear") }
        XCTAssertFalse(join.exists, "Join appeared before the meeting start")
        try assertJoinNow(meeting, on: fixture.page, start: start)
        capture("\(meeting.title) before start")

        // Check when the meeting starts.
        try await wait(until: start)
        XCTAssertTrue(join.waitForExistence(timeout: 10), "Join did not appear at the meeting start")
        try assertJoinNow(meeting, on: fixture.page, start: start)
        capture("\(meeting.title) live")

        // Check when the meeting ends.
        try await wait(until: meeting.endTime)
        XCTAssertTrue(join.waitToDisappear(timeout: 10), "Join remained after the meeting ended")
        try assertJoinNow(meeting, on: fixture.page, start: start)
        capture("\(meeting.title) ended")
    }

    private func wait(until date: Date) async throws {
        while Date() < date {
            try await Task.sleep(for: .seconds(1))
        }
    }

}

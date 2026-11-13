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

    @MainActor
    func testJoinVisibilityRefreshesAfterBackgroundResume_TC_12024() async throws {
        executionTimeAllowance = 600
        let fixture = try await makeMeeting(
            title: "TC12024 resume join",
            start: Date().addingTimeInterval(86_400),
            duration: 60,
            asHost: false
        )
        let start = nextMinute(after: Date().addingTimeInterval(90))
        let meeting = try await fixture.fixtures.update(meeting: fixture.meeting, start: start, duration: 60)
        let row = fixture.page.row(meeting, start: start)
        let join = joinButton(meeting, on: fixture.page, start: start)

        // Check before the live window.
        guard row.waitForExistence(timeout: 20) else { throw RuntimeError("The rescheduled meeting did not appear") }
        XCTAssertFalse(join.exists, "Join appeared before the meeting start")
        capture("TC12024 before start")

        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5))
        try await wait(until: start)
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertTrue(join.waitForExistence(timeout: 15), "Join did not appear after resume at the start")
        capture("TC12024 after start resume")

        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5))
        try await wait(until: meeting.endTime)
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertTrue(join.waitToDisappear(timeout: 15), "Join remained after resume past the meeting end")
        try assertJoinNow(meeting, on: fixture.page, start: start)
        capture("TC12024 after end resume")
    }

    @MainActor
    func testJoinAppearsOnlyForLiveRecurringOccurrence_TC_12022() async throws {
        executionTimeAllowance = 600
        let calendar = Calendar.current
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: Date()))
        let start = try XCTUnwrap(calendar.date(bySettingHour: 12, minute: 0, second: 0, of: tomorrow))
        let now = start.addingTimeInterval(30 * 60)
        let end = try XCTUnwrap(calendar.date(byAdding: .weekOfYear, value: 2, to: start))
        let fixture = try await makeMeeting(
            title: "TC12022 recurring join",
            start: start,
            duration: 3600,
            recurrence: MeetingRecurrence(frequency: .weekly, interval: 1, until: end),
            asHost: false,
            now: now
        )
        let futureStart = try XCTUnwrap(calendar.date(byAdding: .weekOfYear, value: 1, to: start))
        // Check the live occurrence.
        let liveRow = try fixture.page.showRow(fixture.meeting, start: start)
        capture("TC12022 live occurrence")
        // Check the next occurrence.
        let futureRow = try fixture.page.showRow(fixture.meeting, start: futureStart)
        capture("TC12022 future occurrence")

        XCTAssertTrue(
            joinButton(fixture.meeting, on: fixture.page, start: start).exists,
            "The live occurrence did not show Join"
        )
        XCTAssertFalse(
            joinButton(fixture.meeting, on: fixture.page, start: futureStart).exists,
            "A future occurrence showed Join"
        )
        XCTAssertEqual(
            liveRow.staticTexts[Locators.WireMeetings.MeetingRow.recurrence.rawValue].label,
            "Weekly"
        )
        XCTAssertEqual(
            futureRow.staticTexts[Locators.WireMeetings.MeetingRow.recurrence.rawValue].label,
            "Weekly"
        )
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

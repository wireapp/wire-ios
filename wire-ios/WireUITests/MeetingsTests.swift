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
import WireNetwork
import XCTest

/// [calling]
final class MeetingsTests: WireUITestCase {

    private let fixtureDate = Date()

    @MainActor
    func testRecurringMeetingsGroupOccurrencesByLocalDay_TC_11935() async throws {
        let (owner, _, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 0)
        let meetings = try await MeetingsTestHelper(user: owner)
        let now = day(0)
        let daily = try await meetings.create(
            title: "TC11935 daily",
            start: day(2, hour: 9),
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1, until: day(4, hour: 9))
        )
        let weekly = try await meetings.create(
            title: "TC11935 weekly",
            start: day(3, hour: 10),
            recurrence: MeetingRecurrence(frequency: .weekly, interval: 1, until: day(17, hour: 10))
        )
        let everyTwoWeeks = try await meetings.create(
            title: "TC11935 every two weeks",
            start: day(4, hour: 11),
            recurrence: MeetingRecurrence(frequency: .weekly, interval: 2, until: day(32, hour: 11))
        )
        let everyFourWeeks = try await meetings.create(
            title: "TC11935 every four weeks",
            start: day(5, hour: 12),
            recurrence: MeetingRecurrence(frequency: .weekly, interval: 4, until: day(61, hour: 12))
        )

        let meetingsPage = try launchMeetings(for: owner, now: now, locale: "en_GB")
        let expectedRows: [(MeetingResponse, Date)] = [
            (daily, day(2, hour: 9)),
            (daily, day(3, hour: 9)),
            (weekly, day(3, hour: 10)),
            (daily, day(4, hour: 9)),
            (everyTwoWeeks, day(4, hour: 11)),
            (everyFourWeeks, day(5, hour: 12)),
            (weekly, day(10, hour: 10)),
            (weekly, day(17, hour: 10)),
            (everyTwoWeeks, day(18, hour: 11)),
            (everyTwoWeeks, day(32, hour: 11)),
            (everyFourWeeks, day(33, hour: 12)),
            (everyFourWeeks, day(61, hour: 12))
        ]
        try meetingsPage.assertOccurrences(expectedRows)
        try meetingsPage.assertDayHeaders(
            [2, 3, 4, 5, 10, 17, 18, 32, 33, 61].map { day($0) }, now: now, locale: "en_GB"
        )
        try meetingsPage.scrollToTop(first: daily)

        XCTAssertEqual(try meetingsPage.showRow(daily).staticTexts["meetingRecurrence"].label, "Daily")
        XCTAssertTrue(try meetingsPage.showRow(weekly, start: day(3, hour: 10)).staticTexts["Weekly"].exists)
        XCTAssertTrue(
            try meetingsPage.showRow(everyTwoWeeks, start: day(4, hour: 11))
                .staticTexts["Every 2 weeks"].exists
        )
        let fourWeekRow = try meetingsPage.showRow(everyFourWeeks, start: day(5, hour: 12))
        XCTAssertTrue(fourWeekRow.staticTexts["Every 4 weeks"].exists)
        XCTAssertFalse(fourWeekRow.staticTexts["Monthly"].exists)
    }

    private func day(_ offset: Int, hour: Int = 9) -> Date {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: offset + 1, to: calendar.startOfDay(for: fixtureDate))!
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
    }

    @MainActor
    private func launchMeetings(
        for user: UserInfo,
        now: Date,
        locale: String = "en_GB"
    ) throws -> MeetingsPage {
        app.terminate()
        uiTestConfig.meetingsDate = now
        app.launchEnvironment[UITestConfig.environmentKey] = uiTestConfig.encode()
        app.launchArguments = ["-resetData", "--useEnvStaging", "-AppleLanguages", "(en)", "-AppleLocale", locale]
        app.setDeveloperFlags([.useWireAuthentication: true])
        app.launch()
        return try app.loginUser(email: user.email, password: user.password).acceptPopup().openMeetings()
    }

    @MainActor
    func testEmptyMeetingsListShowsCreationOptions_TC_11932() async throws {
        let (teamOwner, _, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 0)
        let meetingsPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .openMeetings()

        XCTAssertTrue(
            meetingsPage.noUpcomingMeetingsText.waitForExistence(timeout: 10),
            "The empty upcoming meetings message did not appear"
        )
        XCTAssertEqual(meetingsPage.meetingRows.count, 0, "The empty list contained meeting rows")
        XCTAssertEqual(meetingsPage.dayHeaders.count, 0, "The empty list contained day headers")
        XCTAssertTrue(meetingsPage.createMeetingButton.isEnabled, "The create meeting button was disabled")

        meetingsPage.createMeetingButton.tap()

        XCTAssertTrue(meetingsPage.meetNowOption.waitForExistence(timeout: 5), "Meet Now did not appear")
        XCTAssertTrue(meetingsPage.scheduleMeetingOption.exists, "Schedule a Meeting did not appear")
    }
}

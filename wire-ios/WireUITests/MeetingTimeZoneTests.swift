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

import WireFoundation
import WireLocators
import WireNetwork
import XCTest

/// [collaboration]
final class MeetingTimeZoneTests: WireUITestCase, MeetingJoinTesting {

    private let berlin = "Europe/Berlin"
    private let newYork = "America/New_York"

    @MainActor
    func testCreationUsesDeviceTimeZone_TC_12033() async throws {
        executionTimeAllowance = 900
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host, apiVersion: .v18)
        try await requireConferenceCalling()
        for (index, zone) in [berlin, newYork].enumerated() {
            let page = try index == 0
                ? launchMeetings(for: host, timeZone: zone, apiVersion: 18)
                : restartMeetings(now: nil, timeZone: zone)
            // Schedule through the form and read the zone saved by the backend.
            let title = "TC12033 scheduled \(index)"
            let schedule = try page.schedule()
            schedule.replaceTitle(with: title)
            _ = try schedule.save()
            let scheduledMeetings = try await fixtures.list()
            let scheduled = try XCTUnwrap(scheduledMeetings.first { $0.title == title })
            XCTAssertEqual(scheduled.timeZoneIdentifier, zone)
            XCTAssertTrue(try page.showRow(scheduled).exists)
            capture(title)

            // Create Meet Now in the same zone, then end the call before checking the record.
            XCTAssertTrue(page.createMeetingButton.waitAndTap())
            XCTAssertTrue(page.meetNowOption.waitAndTap())
            let instantForm = try MeetingFormPage()
            let instantTitle = "TC12033 Meet Now \(index)"
            instantForm.replaceTitle(with: instantTitle)
            XCTAssertTrue(instantForm.saveButton.waitAndTap())
            let call = try waitForCall(title: instantTitle)
            _ = try leaveCall(call)
            let saved = try await fixtures.list()
            let immediate = try XCTUnwrap(saved.first { $0.title == instantTitle })
            XCTAssertEqual(immediate.timeZoneIdentifier, zone)
            capture(instantTitle)
        }
    }

    @MainActor
    func testTimeZoneAndRecurrenceAfterRestartAndFreshSync_TC_12034() async throws {
        executionTimeAllowance = 600
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host, apiVersion: .v18)
        // Load the stored Berlin series before restarting the app.
        let original = try await fixtures.create(
            title: "TC12034 Berlin series",
            start: instant(dayOffset: -28),
            recurrence: MeetingRecurrence(frequency: .weekly, interval: 4, until: nil),
            timeZoneIdentifier: berlin
        )
        XCTAssertEqual(original.timeZoneIdentifier, berlin)
        XCTAssertEqual(original.recurrence?.frequency, .weekly)
        XCTAssertEqual(original.recurrence?.interval, 4)
        let nextStart = instant(hour: 10)
        let initialPage = try launchMeetings(for: host, now: instant(dayOffset: -29), timeZone: berlin, apiVersion: 18)
        try assertTime(original, on: initialPage, start: original.startTime, equals: "11:00 - 11:30")
        let form = try initialPage.edit(original)
        try form.assertRepeat(.everyFourWeeks)
        _ = try form.cancel()

        let afterRestart = try restartMeetings(now: instant(hour: 0), timeZone: newYork, apiVersion: 18)
        try assertTime(original, on: afterRestart, start: nextStart, equals: "06:00 - 06:30")
        let restartedForm = try afterRestart.edit(original, start: nextStart)
        try restartedForm.assertRepeat(.everyFourWeeks)
        _ = try restartedForm.cancel()

        // A changed title confirms that the next launch fetches server changes.
        app.terminate()
        let title = "TC12034 fresh sync"
        _ = try await fixtures.update(meeting: original, title: title)
        let refreshedPage = try launchMeetings(for: host, now: instant(hour: 0), timeZone: newYork, apiVersion: 18)
        let refreshed = try await storedMeeting(fixtures, id: original.id)
        XCTAssertEqual(refreshed.title, title)
        XCTAssertEqual(refreshed.timeZoneIdentifier, berlin)
        XCTAssertEqual(refreshed.recurrence?.frequency, .weekly)
        XCTAssertEqual(refreshed.recurrence?.interval, 4)
        XCTAssertEqual(refreshed.startTime, original.startTime)
        let row = try refreshedPage.showRow(refreshed, start: nextStart)
        XCTAssertEqual(row.staticTexts[Locators.WireMeetings.MeetingRow.title.rawValue].label, title)
        try assertTime(refreshed, on: refreshedPage, start: nextStart, equals: "06:00 - 06:30")
        let refreshedForm = try refreshedPage.edit(refreshed, start: nextStart)
        try refreshedForm.assertRepeat(.everyFourWeeks)
        _ = try refreshedForm.cancel()
    }

    @MainActor
    func testRecurrencesKeepBerlinTimeAcrossDST_TC_12035() async throws {
        executionTimeAllowance = 1200
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host, apiVersion: .v18)
        let now = instant(dayOffset: -28, hour: 8)
        let page = try launchMeetings(for: host, now: now, timeZone: berlin, apiVersion: 18)
        var series: [MeetingResponse] = []
        let options: [(MeetingFormPage.RepeatOption, MeetingFrequency, Int)] = [
            (.daily, .daily, 1),
            (.weekly, .weekly, 1),
            (.everyTwoWeeks, .weekly, 2),
            (.everyFourWeeks, .weekly, 4)
        ]
        // Save all four recurrence options at 11:00 through the Schedule form.
        for (choice, frequency, interval) in options {
            let title = "TC12035 \(frequency) \(interval)"
            let form = try page.schedule()
            form.replaceTitle(with: title)
            try form.selectTime(start: true, hour: 11, minute: 0)
            try form.selectTime(start: false, hour: 12, minute: 0)
            try form.selectRepeat(choice)
            _ = try form.save()

            let meetings = try await fixtures.list()
            let meeting = try XCTUnwrap(meetings.first { $0.title == title })
            XCTAssertEqual(meetings.filter { $0.title == title }.count, 1)
            XCTAssertEqual(meeting.timeZoneIdentifier, berlin)
            XCTAssertEqual(meeting.startTime, instant(dayOffset: -28, hour: 9))
            XCTAssertEqual(meeting.endTime, instant(dayOffset: -28, hour: 10))
            XCTAssertEqual(meeting.recurrence?.frequency, frequency)
            XCTAssertEqual(meeting.recurrence?.interval, interval)
            try assertTime(meeting, on: page, start: meeting.startTime, equals: "11:00 - 12:00")
            series.append(meeting)
        }
        // Reload after Berlin leaves DST and check each UTC-shifted occurrence.
        let afterDST = try restartMeetings(now: instant(hour: 0), timeZone: berlin)
        for meeting in series {
            try assertTime(meeting, on: afterDST, start: instant(hour: 10), equals: "11:00 - 12:00")
        }
    }

    @MainActor
    func testInviteeTimeAcrossDifferentDSTDates_TC_12036() async throws {
        executionTimeAllowance = 900
        let (host, members, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        let invitee = try XCTUnwrap(members.first)
        try await registerClients(for: members)
        let fixtures = try await MeetingsTestHelper(user: host, apiVersion: .v18)
        let now = instant(dayOffset: -28, hour: 8)
        let original = try await fixtures.create(
            title: "TC12036 weekly", start: instant(dayOffset: -28, hour: 9), duration: 3600,
            recurrence: MeetingRecurrence(frequency: .weekly, interval: 1, until: instant(dayOffset: 7, hour: 10)),
            timeZoneIdentifier: berlin
        )
        let hostPage = try launchMeetings(for: host, now: now, timeZone: berlin, apiVersion: 18)
        let form = try hostPage.edit(original)
        try form.addParticipants([invitee])
        _ = try form.save()
        let meeting = try await storedMeeting(fixtures, id: original.id)
        XCTAssertEqual(meeting.timeZoneIdentifier, berlin)
        XCTAssertEqual(meeting.recurrence?.frequency, .weekly)
        XCTAssertEqual(meeting.recurrence?.interval, 1)
        // The host keeps 11:00 through both transitions.
        for start in [instant(dayOffset: -7), instant(hour: 10), instant(dayOffset: 7, hour: 10)] {
            try assertTime(meeting, on: hostPage, start: start, equals: "11:00 - 12:00")
        }
        // The same occurrences convert to the invitee's New York time.
        let page = try launchMeetings(for: invitee, now: now, timeZone: newYork, apiVersion: 18)
        try assertTime(meeting, on: page, start: instant(dayOffset: -7, hour: 9), equals: "05:00 - 06:00")
        try assertTime(meeting, on: page, start: instant(hour: 10), equals: "06:00 - 07:00")
        try assertTime(meeting, on: page, start: instant(dayOffset: 7, hour: 10), equals: "05:00 - 06:00")
    }

    @MainActor
    private func restartMeetings(now: Date?, timeZone: String, apiVersion: Int = 18) throws -> MeetingsPage {
        app.terminate()
        uiTestConfig.meetingsDate = now
        app.launchEnvironment[UITestConfig.environmentKey] = uiTestConfig.encode()
        app.launchEnvironment["TZ"] = timeZone
        app.launchArguments.removeAll { $0 == "-resetData" || $0.hasPrefix("--preferred-api-version=") }
        app.launchArguments.append("--preferred-api-version=\(apiVersion)")
        app.launch()
        return try ConversationsPage().openMeetings()
    }

    private func storedMeeting(_ fixtures: MeetingsTestHelper, id: QualifiedID) async throws -> MeetingResponse {
        try await fixtures.api.getMeeting(id: id)
    }

    @MainActor
    private func assertTime(
        _ meeting: MeetingResponse, on page: MeetingsPage, start: Date? = nil, equals expected: String
    ) throws {
        let row = try page.showRow(meeting, start: start)
        XCTAssertEqual(row.staticTexts[Locators.WireMeetings.MeetingRow.title.rawValue].label, meeting.title)
        XCTAssertEqual(row.staticTexts[Locators.WireMeetings.MeetingRow.time.rawValue].label, expected)
        capture("\(meeting.title) \(expected)")
    }

    private func instant(dayOffset: Int = 0, hour: Int = 9, minute: Int = 0, second: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let year = calendar.component(.year, from: Date()) + 1
        var transition = calendar.date(from: DateComponents(year: year, month: 10, day: 31))!
        // Berlin leaves DST on the last Sunday in October; keep backend fixtures in the future.
        while calendar.component(.weekday, from: transition) != 1 {
            transition = calendar.date(byAdding: .day, value: -1, to: transition)!
        }
        let day = calendar.date(byAdding: .day, value: dayOffset, to: transition)!
        return calendar.date(bySettingHour: hour, minute: minute, second: second, of: day)!
    }
}

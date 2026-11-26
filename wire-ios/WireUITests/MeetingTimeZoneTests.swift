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
        for (index, zone) in [berlin, newYork].enumerated() {
            let page = try index == 0
                ? launchMeetings(for: host, timeZone: zone, apiVersion: .v18)
                : restartMeetings(now: nil, timeZone: zone, apiVersion: .v18)
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

            // Check the created Meet Now record before closing the call or plan prompt.
            XCTAssertTrue(page.createMeetingButton.waitAndTap())
            XCTAssertTrue(page.meetNowOption.waitAndTap())
            let instantForm = try MeetingFormPage()
            let instantTitle = "TC12033 Meet Now \(index)"
            instantForm.replaceTitle(with: instantTitle)
            XCTAssertTrue(instantForm.saveButton.waitAndTap())
            XCTAssertTrue(instantForm.titleField.waitToDisappear(timeout: 30))
            let saved = try await fixtures.list()
            let immediate = try XCTUnwrap(saved.first { $0.title == instantTitle })
            XCTAssertEqual(immediate.timeZoneIdentifier, zone)
            let upgrade = app.alerts["Upgrade to Enterprise"]
            let endCall = app.buttons[Locators.OngoingCallPage.endOngoingCallButton.rawValue]
            app.dismissAllowIfPresent()
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                upgrade.exists || endCall.exists
            }, object: nil)
            XCTAssertEqual(XCTWaiter().wait(for: [ready], timeout: 30), .completed)
            if upgrade.exists {
                XCTAssertTrue(upgrade.buttons["Cancel"].waitAndTap())
                XCTAssertTrue(upgrade.waitToDisappear(timeout: 5))
            } else {
                XCTAssertTrue(endCall.waitAndTap())
                XCTAssertTrue(endCall.waitToDisappear(timeout: 15))
                let feedback = app.buttons["score_close"]
                if feedback.waitForExistence(timeout: 2) { feedback.tap() }
            }
            XCTAssertTrue(page.createMeetingButton.waitForExistence(timeout: 15))
            XCTAssertFalse(endCall.exists)
            let row = try page.showRow(immediate)
            XCTAssertEqual(row.staticTexts[Locators.WireMeetings.MeetingRow.title.rawValue].label, instantTitle)
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
        let initialPage = try launchMeetings(
            for: host,
            now: instant(dayOffset: -29),
            timeZone: berlin,
            apiVersion: .v18
        )
        try assertTime(original, on: initialPage, start: original.startTime, equals: "11:00 - 11:30")
        let form = try initialPage.edit(original)
        try form.assertRepeat(.everyFourWeeks)
        _ = try form.cancel()

        let afterRestart = try restartMeetings(now: instant(hour: 0), timeZone: newYork, apiVersion: .v18)
        try assertTime(original, on: afterRestart, start: nextStart, equals: "06:00 - 06:30")
        let restartedForm = try afterRestart.edit(original, start: nextStart)
        try restartedForm.assertRepeat(.everyFourWeeks)
        _ = try restartedForm.cancel()

        // A changed title confirms that the next launch fetches server changes.
        app.terminate()
        let title = "TC12034 fresh sync"
        _ = try await fixtures.update(meeting: original, title: title)
        let refreshedPage = try launchMeetings(for: host, now: instant(hour: 0), timeZone: newYork, apiVersion: .v18)
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
        let page = try launchMeetings(for: host, now: now, timeZone: berlin, apiVersion: .v18)
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
        let afterDST = try restartMeetings(now: instant(hour: 0), timeZone: berlin, apiVersion: .v18)
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
        let hostPage = try launchMeetings(for: host, now: now, timeZone: berlin, apiVersion: .v18)
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
        let page = try launchMeetings(for: invitee, now: now, timeZone: newYork, apiVersion: .v18)
        try assertTime(meeting, on: page, start: instant(dayOffset: -7, hour: 9), equals: "05:00 - 06:00")
        try assertTime(meeting, on: page, start: instant(hour: 10), equals: "06:00 - 07:00")
        try assertTime(meeting, on: page, start: instant(dayOffset: 7, hour: 10), equals: "05:00 - 06:00")
    }

    @MainActor
    func testInviteeJoinBoundariesInBothTimeZones_TC_12023() async throws {
        executionTimeAllowance = 600
        let (host, members, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        let invitee = try XCTUnwrap(members.first)
        try await registerClients(for: members)
        let fixtures = try await MeetingsTestHelper(user: host, apiVersion: .v18)
        let start = instant(hour: 10)
        let original = try await fixtures.create(
            title: "TC12023 join boundaries", start: start, duration: 3600, timeZoneIdentifier: berlin
        )
        let hostPage = try launchMeetings(
            for: host, now: instant(dayOffset: -28, hour: 8), timeZone: berlin, apiVersion: .v18
        )
        let form = try hostPage.edit(original)
        try form.addParticipants([invitee])
        _ = try form.save()
        let meeting = try await storedMeeting(fixtures, id: original.id)
        XCTAssertEqual(meeting.startTime, start)
        XCTAssertEqual(meeting.endTime, start.addingTimeInterval(3600))
        XCTAssertEqual(meeting.timeZoneIdentifier, berlin)

        // Check before start once, then check the start and end in both viewer zones.
        var signedIn = false
        for zone in [berlin, newYork] {
            let checks: [(TimeInterval, Bool)] = (zone == berlin ? [(-1, false)] : []) + [(0, true), (3600, false)]
            for check in checks {
                let now = start.addingTimeInterval(check.0)
                let page: MeetingsPage
                if !signedIn {
                    page = try launchMeetings(for: invitee, now: now, timeZone: zone, apiVersion: .v18)
                    signedIn = true
                } else {
                    page = try restartMeetings(now: now, timeZone: zone, apiVersion: .v18)
                }
                let row = try page.showRow(meeting, start: start)
                XCTAssertTrue(row.exists, "The occurrence is missing in \(zone) at \(now)")
                XCTAssertEqual(
                    joinButton(meeting, on: page, start: start).exists, check.1,
                    "Join visibility is incorrect in \(zone) at \(now)"
                )
                capture("TC12023 \(zone) offset \(check.0)")
            }
        }
    }

    @MainActor
    func testLegacyMeetingUsesBerlinFallbackAfterRestartAndFreshSync_TC_12037() async throws {
        executionTimeAllowance = 600
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let legacy = try await MeetingsTestHelper(user: host, apiVersion: .v16)
        let stable = try await MeetingsTestHelper(user: host, apiVersion: .v18)
        // API v16 omits tzid while the server stores the legacy Berlin zone.
        let original = try await legacy.create(
            title: "TC12037 legacy daily",
            start: instant(dayOffset: -1),
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1, until: nil),
            timeZoneIdentifier: berlin
        )
        XCTAssertNil(original.timeZoneIdentifier)
        XCTAssertEqual(original.recurrence?.frequency, .daily)
        XCTAssertEqual(original.recurrence?.interval, 1)
        let legacyReadback = try await storedMeeting(legacy, id: original.id)
        XCTAssertNil(legacyReadback.timeZoneIdentifier)
        let stableReadback = try await storedMeeting(stable, id: original.id)
        XCTAssertEqual(stableReadback.timeZoneIdentifier, berlin)

        let beforeDST = instant(dayOffset: -1)
        let afterDST = instant(hour: 10)
        let initialPage = try launchMeetings(
            for: host, now: instant(dayOffset: -2), timeZone: newYork, apiVersion: .v16
        )
        try assertTime(original, on: initialPage, start: beforeDST, equals: "05:00 - 05:30")
        try assertTime(original, on: initialPage, start: afterDST, equals: "06:00 - 06:30")

        let restartedPage = try restartMeetings(now: instant(hour: 0), timeZone: newYork, apiVersion: .v16)
        try assertTime(original, on: restartedPage, start: afterDST, equals: "06:00 - 06:30")
        let restartedForm = try restartedPage.edit(original, start: afterDST)
        try restartedForm.assertRepeat(.daily)
        _ = try restartedForm.cancel()

        let syncedPage = try launchMeetings(for: host, now: instant(hour: 0), timeZone: newYork, apiVersion: .v16)
        let syncedLegacy = try await storedMeeting(legacy, id: original.id)
        let syncedStable = try await storedMeeting(stable, id: original.id)
        XCTAssertNil(syncedLegacy.timeZoneIdentifier)
        XCTAssertEqual(syncedStable.timeZoneIdentifier, berlin)
        XCTAssertEqual(syncedLegacy.recurrence?.frequency, .daily)
        XCTAssertEqual(syncedLegacy.recurrence?.interval, 1)
        XCTAssertEqual(syncedLegacy.startTime, original.startTime)
        try assertTime(syncedLegacy, on: syncedPage, start: afterDST, equals: "06:00 - 06:30")
        let syncedForm = try syncedPage.edit(syncedLegacy, start: afterDST)
        try syncedForm.assertRepeat(.daily)
        _ = try syncedForm.cancel()
    }

    @MainActor
    func testTitleEditUsesEditorsTimeZone_TC_12038() async throws {
        executionTimeAllowance = 600
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host, apiVersion: .v18)
        let original = try await fixtures.create(
            title: "TC12038 Berlin",
            start: instant(dayOffset: -28),
            duration: 3600,
            recurrence: MeetingRecurrence(frequency: .weekly, interval: 4, until: nil),
            timeZoneIdentifier: berlin
        )
        let page = try launchMeetings(for: host, now: instant(dayOffset: -29), timeZone: newYork, apiVersion: .v18)
        // Before the edit, Berlin's DST transition moves this occurrence to 10:00 UTC.
        try assertTime(original, on: page, start: instant(hour: 10), equals: "06:00 - 07:00")
        try page.scrollToTop(first: original)
        let form = try page.edit(original)
        // Check the current WPB-28918 behavior: a title-only Save sends the device zone.
        form.replaceTitle(with: "TC12038 New York")
        _ = try form.save()

        let updated = try await storedMeeting(fixtures, id: original.id)
        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.title, "TC12038 New York")
        XCTAssertEqual(updated.startTime, original.startTime)
        XCTAssertEqual(updated.endTime, original.endTime)
        XCTAssertEqual(updated.timeZoneIdentifier, newYork)
        XCTAssertEqual(updated.recurrence?.frequency, .weekly)
        XCTAssertEqual(updated.recurrence?.interval, 4)
        XCTAssertNil(updated.recurrence?.until)
        // The same future occurrence now follows New York's calendar.
        try assertTime(updated, on: page, start: instant(), equals: "05:00 - 06:00")
    }

    @MainActor
    func testEditedSeriesKeepsUTCAndUsesNewZoneAfterRestart_TC_12039() async throws {
        executionTimeAllowance = 600
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host, apiVersion: .v18)
        let original = try await fixtures.create(
            title: "TC12039 Berlin",
            start: instant(dayOffset: -28),
            duration: 3600,
            recurrence: MeetingRecurrence(frequency: .weekly, interval: 4, until: nil),
            timeZoneIdentifier: berlin
        )
        // Save the existing series in New York, keeping its UTC dates and rule.
        let page = try launchMeetings(for: host, now: instant(dayOffset: -29), timeZone: newYork, apiVersion: .v18)
        let form = try page.edit(original)
        form.replaceTitle(with: "TC12039 New York")
        _ = try form.save()
        let updated = try await storedMeeting(fixtures, id: original.id)
        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.title, "TC12039 New York")
        XCTAssertEqual(updated.startTime, instant(dayOffset: -28))
        XCTAssertEqual(updated.endTime, instant(dayOffset: -28, hour: 10))
        XCTAssertEqual(updated.timeZoneIdentifier, newYork)
        XCTAssertEqual(updated.recurrence?.frequency, .weekly)
        XCTAssertEqual(updated.recurrence?.interval, 4)
        XCTAssertNil(updated.recurrence?.until)

        let restarted = try restartMeetings(now: instant(dayOffset: -1), timeZone: newYork, apiVersion: .v18)
        try assertTime(updated, on: restarted, start: instant(), equals: "05:00 - 06:00")
        // New York has left daylight saving time by the next four-week occurrence.
        try assertTime(updated, on: restarted, start: instant(dayOffset: 28, hour: 10), equals: "05:00 - 06:00")
        let afterRestart = try await storedMeeting(fixtures, id: original.id)
        XCTAssertEqual(afterRestart.startTime, updated.startTime)
        XCTAssertEqual(afterRestart.endTime, updated.endTime)
        XCTAssertEqual(afterRestart.timeZoneIdentifier, newYork)
        XCTAssertEqual(afterRestart.recurrence?.frequency, .weekly)
        XCTAssertEqual(afterRestart.recurrence?.interval, 4)
        XCTAssertNil(afterRestart.recurrence?.until)
    }

    @MainActor
    func testPreviousLocalDateAndFormControls_TC_12040() async throws {
        executionTimeAllowance = 600
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host, apiVersion: .v18)
        let start = instant(dayOffset: 7, hour: 0, minute: 30)
        let original = try await fixtures.create(
            title: "TC12040 previous date", start: start, duration: 3600, timeZoneIdentifier: berlin
        )
        // The same UTC instant falls on the previous local date in New York.
        let page = try launchMeetings(
            for: host, now: start.addingTimeInterval(-900), timeZone: newYork, apiVersion: .v18
        )
        try assertTime(original, on: page, equals: "20:30 - 21:30")
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = TimeZone(identifier: newYork)!
        formatter.setLocalizedDateFormatFromTemplate("EEEE MMMM d")
        XCTAssertEqual(page.dayHeaders.firstMatch.label, "Today (\(formatter.string(from: start)))")
        // Edit and Schedule show local controls without time-zone UI.
        let edit = try page.edit(original)
        edit.assertDateTimes(
            start: start,
            end: start.addingTimeInterval(3600),
            timeZone: TimeZone(identifier: newYork)!
        )
        XCTAssertTrue(edit.startDateButton.exists)
        XCTAssertTrue(edit.startTimeButton.exists)
        XCTAssertTrue(edit.endTimeButton.exists)
        XCTAssertTrue(edit.repeatButton.exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] %@", "time zone")).firstMatch
            .exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[cd] %@", "time zone")).firstMatch
            .exists)
        _ = try edit.cancel()

        let schedule = try page.schedule()
        schedule.assertDateTimes(
            start: start,
            end: start.addingTimeInterval(3600),
            timeZone: TimeZone(identifier: newYork)!
        )
        XCTAssertTrue(schedule.startDateButton.exists)
        XCTAssertTrue(schedule.startTimeButton.exists)
        XCTAssertTrue(schedule.endTimeButton.exists)
        XCTAssertTrue(schedule.repeatButton.exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] %@", "time zone")).firstMatch
            .exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[cd] %@", "time zone")).firstMatch
            .exists)
        _ = try schedule.cancel()
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

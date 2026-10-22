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

import Foundation
import notify
import WireFoundation
import WireLocators
import WireNetwork
import XCTest

/// [collaboration]
final class EditMeetingTests: WireUITestCase {

    private let fixtureDate = Date()

    private func date(hour: Int = 10, minute: Int = 0, dayOffset: Int = 0) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: 2 + dayOffset, to: calendar.startOfDay(for: fixtureDate))!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    @MainActor
    private func launchMeetings(for user: UserInfo, now: Date, locale: String = "en_GB") throws -> MeetingsPage {
        app.terminate()
        uiTestConfig.meetingsDate = now
        app.launchEnvironment[UITestConfig.environmentKey] = uiTestConfig.encode()
        app.launchArguments = ["-resetData", "--useEnvStaging", "-AppleLanguages", "(en)", "-AppleLocale", locale]
        app.setDeveloperFlags([.useWireAuthentication: true])
        app.launch()
        return try app.loginUser(email: user.email, password: user.password).acceptPopup().openMeetings()
    }

    private func registerClients(for users: [UserInfo]) async throws {
        for user in users {
            _ = try await testServicesClient.getInstanceId(
                email: user.email, password: user.password, name: user.name, verificationCode: nil
            )
        }
    }

    private func onlyMeeting(
        _ fixtures: MeetingsTestHelper,
        original: MeetingResponse
    ) async throws -> MeetingResponse {
        let meetings = try await fixtures.list()
        XCTAssertEqual(meetings.map(\.id), [original.id], "Editing must retain one meeting with the same ID")
        let meeting = try XCTUnwrap(meetings.first)
        XCTAssertEqual(meeting.conversationID, original.conversationID)
        XCTAssertEqual(meeting.creatorID, original.creatorID)
        return meeting
    }

    private func assertUnchanged(_ meeting: MeetingResponse, original: MeetingResponse) {
        XCTAssertEqual(meeting.title, original.title)
        XCTAssertEqual(meeting.startTime, original.startTime)
        XCTAssertEqual(meeting.endTime, original.endTime)
        XCTAssertEqual(meeting.recurrence?.frequency, original.recurrence?.frequency)
        XCTAssertEqual(meeting.recurrence?.interval, original.recurrence?.interval)
        XCTAssertEqual(meeting.recurrence?.until, original.recurrence?.until)
        XCTAssertEqual(meeting.timeZoneIdentifier, original.timeZoneIdentifier)
    }

    private func members(_ fixtures: MeetingsTestHelper, meeting: MeetingResponse) async throws -> Conversation
        .Members {
        let response = try await fixtures.conversationsAPI.getConversations(for: [meeting.conversationID])
        XCTAssertTrue(response.notFound.isEmpty)
        XCTAssertTrue(response.failed.isEmpty)
        return try XCTUnwrap(response.found.first?.members)
    }

    @MainActor
    private func assertTitle(_ title: String, meeting: MeetingResponse, on page: MeetingsPage) throws {
        let row = try page.showRow(meeting)
        let text = row.staticTexts[Locators.WireMeetings.MeetingRow.title.rawValue]
        let updated = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", title), object: text)
        guard XCTWaiter().wait(for: [updated], timeout: 15) == .completed else {
            throw RuntimeError("The meeting row did not show '\(title)'")
        }
    }

    @MainActor
    func testCancelEditRetainsExistingValues_TC_11987() async throws {
        let (host, users, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        try await registerClients(for: users)
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host, now: date())
        let creation = try page.schedule()
        creation.replaceTitle(with: "TC11987 original")
        try creation.addParticipants(users)
        try creation.selectRepeat(.weekly)
        _ = try creation.save()
        let initial = try await fixtures.list()
        let original = try XCTUnwrap(initial.first)
        let originalMembers = try await members(fixtures, meeting: original)

        // Open Edit and check the saved title, dates, repeat rule, and participants.
        let form = try page.edit(original)
        XCTAssertEqual(form.titleField.value as? String, original.title)
        form.assertDateTimes(start: original.startTime, end: original.endTime)
        try form.assertRepeat(.weekly)
        XCTAssertEqual(form.participantsButton.value as? String, "1")
        XCTAssertTrue(form.participantsButton.label.contains(users[0].name))

        // Change the form, cancel, and open the same meeting again.
        form.replaceTitle(with: "TC11987 discarded")
        try form.selectTime(start: true, hour: 15, minute: 0)
        try form.selectRepeat(.daily)
        _ = try form.cancel()
        let reopened = try page.edit(original)
        XCTAssertEqual(reopened.titleField.value as? String, original.title)
        reopened.assertDateTimes(start: original.startTime, end: original.endTime)
        try reopened.assertRepeat(.weekly)
        XCTAssertEqual(reopened.participantsButton.value as? String, "1")
        _ = try reopened.cancel()
        let unchanged = try await onlyMeeting(fixtures, original: original)
        assertUnchanged(unchanged, original: original)
        let unchangedMembers = try await members(fixtures, meeting: original)
        XCTAssertEqual(unchangedMembers, originalMembers)
    }

    @MainActor
    func testEditTitleValidation_TC_11990() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let original = try await fixtures.create(title: "TC11990 original", start: date(hour: 12))
        let page = try launchMeetings(for: host, now: date())
        let form = try page.edit(original)

        // Empty and over-limit titles must not change the saved meeting.
        for title in ["", "   ", String(repeating: "A", count: 65), String(repeating: "🧑🏽‍💻", count: 32)] {
            form.replaceTitle(with: title)
            XCTAssertFalse(form.saveButton.isEnabled)
            if title.count > 64 || title.utf8.count > 256 {
                XCTAssertTrue(form.titleError.waitForExistence(timeout: 5))
            }
        }
        let beforeSave = try await onlyMeeting(fixtures, original: original)
        XCTAssertEqual(beforeSave.title, original.title)
        _ = try form.cancel()

        // Save each supported title and check the row and the stable meeting ID.
        for title in ["TC11990 Standard title", "TC11990 & + / 😀", String(repeating: "A", count: 64)] {
            let edit = try page.edit(original)
            edit.replaceTitle(with: title)
            XCTAssertEqual(edit.titleField.value as? String, title)
            XCTAssertTrue(edit.saveButton.isEnabled)
            _ = try edit.save()
            let updated = try await onlyMeeting(fixtures, original: original)
            XCTAssertEqual(updated.title, title)
            XCTAssertEqual(updated.startTime, original.startTime)
            XCTAssertEqual(updated.endTime, original.endTime)
            try assertTitle(title, meeting: updated, on: page)
        }
    }

    @MainActor
    func testEditDateAndTimeRange_TC_11992() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let original = try await fixtures.create(title: "TC11992 edited", start: date(hour: 12))
        let earlier = try await fixtures.create(title: "Earlier meeting", start: date(hour: 14, dayOffset: 1))
        let later = try await fixtures.create(title: "Later meeting", start: date(hour: 17, dayOffset: 1))
        let page = try launchMeetings(for: host, now: date())
        let form = try page.edit(original)

        // Move to tomorrow and attempt equal and earlier End times.
        try form.selectStartDate(date(dayOffset: 1))
        try form.selectTime(start: true, hour: 15, minute: 0)
        for hour in [15, 14] {
            try form.selectTime(start: false, hour: hour, minute: 0, allowClamping: true)
            let selected = try form.dateTimes()
            XCTAssertEqual(selected.start, date(hour: 15, dayOffset: 1))
            XCTAssertGreaterThan(selected.end, selected.start)
            XCTAssertTrue(Calendar.current.isDate(selected.start, inSameDayAs: selected.end))
        }

        // Save a valid range and check its day and position in the list.
        try form.selectTime(start: false, hour: 16, minute: 30)
        _ = try form.save()
        let saved = try await fixtures.list()
        XCTAssertEqual(Set(saved.map(\.id)), Set([original.id, earlier.id, later.id]))
        let updated = try XCTUnwrap(saved.first { $0.id == original.id })
        XCTAssertEqual(updated.startTime, date(hour: 15, dayOffset: 1))
        XCTAssertEqual(updated.endTime, date(hour: 16, minute: 30, dayOffset: 1))
        XCTAssertEqual(updated.title, original.title)
        try page.assertRows([earlier, updated, later], now: date(), locale: "en_GB")

        // Reopen under both locale settings to check displayed date and time values.
        for locale in ["en_GB", "en_US"] {
            let localizedPage = try launchMeetings(for: host, now: date(), locale: locale)
            let edit = try localizedPage.edit(updated)
            edit.assertDateTimes(start: updated.startTime, end: updated.endTime, locale: locale)
            _ = try edit.cancel()
        }
    }

    @MainActor
    func testEditWholeMeetingSeries_TC_11994() async throws {
        executionTimeAllowance = 600
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let original = try await fixtures.create(title: "TC11994 series", start: date(hour: 12))
        let page = try launchMeetings(for: host, now: date())
        let options: [(MeetingFormPage.RepeatOption, MeetingFrequency?, Int?, Int)] = [
            (.daily, .daily, 1, 1), (.weekly, .weekly, 1, 7),
            (.everyTwoWeeks, .weekly, 2, 14), (.everyFourWeeks, .weekly, 4, 28), (.never, nil, nil, 0)
        ]
        var selectedStart = original.startTime
        for (option, frequency, interval, days) in options {
            // Edit a future occurrence after the first change; all edits target the same series.
            let form = try page.edit(original, start: selectedStart)
            guard form.repeatButton.waitAndTap() else { throw RuntimeError("Repeat menu did not open") }
            XCTAssertFalse(form.repeatChoice(.monthly).exists)
            XCTAssertFalse(form.repeatChoice(.yearly).exists)
            guard form.repeatChoice(option).waitAndTap() else { throw RuntimeError("Repeat choice did not appear") }
            _ = try form.save()
            XCTAssertFalse(app.alerts.firstMatch.exists, "The edit must not ask for occurrence or series scope")
            let updated = try await onlyMeeting(fixtures, original: original)
            XCTAssertEqual(updated.recurrence?.frequency, frequency)
            XCTAssertEqual(updated.recurrence?.interval, interval)
            XCTAssertEqual(updated.startTime, original.startTime)
            XCTAssertEqual(updated.endTime, original.endTime)
            if selectedStart != original.startTime {
                XCTAssertTrue(page.row(original, start: selectedStart).waitToDisappear(timeout: 15))
            }
            selectedStart = Calendar.current.date(byAdding: .day, value: days, to: original.startTime)!
            _ = try page.showRow(updated, start: selectedStart)
            if option == .never {
                try page.assertRows([updated], now: date(), locale: "en_GB")
            }
        }
    }

}

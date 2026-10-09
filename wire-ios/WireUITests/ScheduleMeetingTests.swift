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
final class ScheduleMeetingTests: WireUITestCase {

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

    private func onlyMeeting(_ fixtures: MeetingsTestHelper, title: String) async throws -> MeetingResponse {
        let meetings = try await fixtures.list()
        XCTAssertEqual(meetings.count, 1, "Scheduling must create exactly one meeting")
        let meeting = try XCTUnwrap(meetings.first)
        XCTAssertEqual(meeting.title, title)
        XCTAssertGreaterThan(meeting.endTime, meeting.startTime)
        XCTAssertTrue(Calendar.current.isDate(meeting.startTime, inSameDayAs: meeting.endTime))
        return meeting
    }

    private func assertMembers(
        _ fixtures: MeetingsTestHelper,
        meeting: MeetingResponse,
        host: UserInfo,
        invitees: [QualifiedID] = []
    ) async throws {
        let result = try await fixtures.conversationsAPI.getConversations(for: [meeting.conversationID])
        XCTAssertTrue(result.notFound.isEmpty)
        XCTAssertTrue(result.failed.isEmpty)
        let conversation = try XCTUnwrap(result.found.first)
        let members = try XCTUnwrap(conversation.members)
        XCTAssertEqual(meeting.creatorID.id, UUID(uuidString: host.id))
        XCTAssertEqual(members.selfMember?.qualifiedID?.id, UUID(uuidString: host.id))
        XCTAssertEqual(Set(members.others.compactMap(\.qualifiedID)), Set(invitees))
        XCTAssertEqual(members.others.count, invitees.count, "The conversation has missing or duplicate invitees")
    }

    @MainActor
    func testCancelScheduleMeeting_TC_11948() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        for locale in ["en_GB", "en_US"] {
            let page = try launchMeetings(for: host, now: date(minute: 7), locale: locale)
            let form = try page.schedule()
            XCTAssertTrue(form.titleField.exists)
            XCTAssertTrue(form.participantsButton.exists)
            XCTAssertTrue(form.repeatButton.exists)
            form.assertDateTimes(start: date(minute: 15), end: date(hour: 11, minute: 15), locale: locale)
            XCTAssertFalse(form.saveButton.isEnabled)
            _ = try form.cancel()
            XCTAssertTrue(page.noUpcomingMeetingsText.waitForExistence(timeout: 10))
            let afterEmptyCancel = try await fixtures.list()
            XCTAssertTrue(afterEmptyCancel.isEmpty)

            let changedForm = try page.schedule()
            changedForm.replaceTitle(with: "TC11948 discarded")
            changedForm.selectRepeat(MeetingFormPage.localized("wireMeetings.schedule.time.daily"))
            XCTAssertTrue(changedForm.saveButton.isEnabled)
            _ = try changedForm.cancel()
            XCTAssertTrue(page.noUpcomingMeetingsText.waitForExistence(timeout: 10))
            XCTAssertEqual(page.meetingRows.count, 0)
            let afterChangedCancel = try await fixtures.list()
            XCTAssertTrue(afterChangedCancel.isEmpty)
        }
    }

    @MainActor
    func testDefaultScheduleDateAndDuration_TC_11950() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let datasets: [(now: Date, start: Date, end: Date)] = [
            (date(minute: 7), date(minute: 15), date(hour: 11, minute: 15)),
            (date(), date(minute: 15), date(hour: 11, minute: 15)),
            (date(hour: 23), date(hour: 23, minute: 15), date(hour: 23, minute: 45)),
            (date(hour: 23, minute: 50), date(hour: 0, dayOffset: 1), date(hour: 1, dayOffset: 1)),
            (date(hour: 23, minute: 30), date(hour: 0, dayOffset: 1), date(hour: 1, dayOffset: 1))
        ]
        for dataset in datasets {
            let page = try launchMeetings(for: host, now: dataset.now)
            let form = try page.schedule()
            form.assertDateTimes(start: dataset.start, end: dataset.end)
            _ = try form.cancel()
        }
        let meetings = try await fixtures.list()
        XCTAssertTrue(meetings.isEmpty)
    }

    @MainActor
    func testScheduleMeetingTitleValidation_TC_11952() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host, now: date())
        let form = try page.schedule()
        XCTAssertFalse(form.saveButton.isEnabled)
        form.replaceTitle(with: "   ")
        XCTAssertFalse(form.saveButton.isEnabled)
        let beforeValidTitle = try await fixtures.list()
        XCTAssertTrue(beforeValidTitle.isEmpty)

        let validTitle = String(repeating: "A", count: 64)
        form.replaceTitle(with: validTitle)
        XCTAssertEqual(form.titleField.value as? String, validTitle)
        XCTAssertTrue(form.saveButton.isEnabled)
        _ = try form.save()
        let meeting = try await onlyMeeting(fixtures, title: validTitle)
        XCTAssertTrue(page.row(meeting).waitForExistence(timeout: 15))

        let invalidForm = try page.schedule()
        let invalidTitle = String(repeating: "B", count: 65)
        invalidForm.replaceTitle(with: invalidTitle)
        XCTAssertEqual(invalidForm.titleField.value as? String, invalidTitle)
        XCTAssertTrue(invalidForm.titleError.waitForExistence(timeout: 5))
        XCTAssertFalse(invalidForm.saveButton.isEnabled)
        // Fewer than 64 characters can still exceed the separate 256-byte limit.
        invalidForm.replaceTitle(with: String(repeating: "🧑🏽‍💻", count: 32))
        XCTAssertTrue(invalidForm.titleError.waitForExistence(timeout: 5))
        XCTAssertFalse(invalidForm.saveButton.isEnabled)
        _ = try invalidForm.cancel()
        let remaining = try await fixtures.list()
        XCTAssertEqual(remaining.map(\.id), [meeting.id], "The invalid title created a second meeting")
    }

    @MainActor
    func testScheduleMeetingWithoutInvitees_TC_11954() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host, now: date())
        let form = try page.schedule()
        let title = "TC11954 host only"
        form.replaceTitle(with: title)
        XCTAssertEqual(form.participantsButton.value as? String, "0")
        form.assertRepeat(MeetingFormPage.localized("wireMeetings.schedule.time.never"))
        form.assertDateTimes(start: date(minute: 15), end: date(hour: 11, minute: 15))
        _ = try form.save()

        let meeting = try await onlyMeeting(fixtures, title: title)
        XCTAssertNil(meeting.recurrence)
        XCTAssertEqual(meeting.startTime, date(minute: 15))
        XCTAssertEqual(meeting.endTime, date(hour: 11, minute: 15))
        let row = page.row(meeting)
        XCTAssertTrue(row.waitForExistence(timeout: 15), "The new meeting did not appear without refresh")
        XCTAssertEqual(row.staticTexts[Locators.WireMeetings.MeetingRow.title.rawValue].label, title)
        try await assertMembers(fixtures, meeting: meeting, host: host)
    }

    @MainActor
    func testScheduleFutureDateAndQuarterHourTimes_TC_11955() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host, now: date())
        let form = try page.schedule()
        form.replaceTitle(with: "TC11955 future date")
        try form.selectStartDate(date(dayOffset: 1))
        form.assertDateTimes(start: date(minute: 15, dayOffset: 1), end: date(hour: 11, minute: 15, dayOffset: 1))
        XCTAssertFalse(
            app.buttons[Locators.WireMeetings.MeetingForm.endDate.rawValue].isHittable,
            "End date must not be editable"
        )

        for minute in [0, 15, 30, 45] {
            try form.selectTime(start: true, hour: 15, minute: minute)
            form.assertDateTimes(
                start: date(hour: 15, minute: minute, dayOffset: 1),
                end: date(hour: 16, minute: minute, dayOffset: 1)
            )
        }
        try form.selectTime(start: false, hour: 16, minute: 30)
        form.assertDateTimes(
            start: date(hour: 15, minute: 45, dayOffset: 1),
            end: date(hour: 16, minute: 30, dayOffset: 1)
        )
        _ = try form.save()
        let meeting = try await onlyMeeting(fixtures, title: "TC11955 future date")
        XCTAssertEqual(meeting.startTime, date(hour: 15, minute: 45, dayOffset: 1))
        XCTAssertEqual(meeting.endTime, date(hour: 16, minute: 30, dayOffset: 1))
        XCTAssertTrue(page.row(meeting).waitForExistence(timeout: 15))
    }

    @MainActor
    func testScheduleOnlyValidSameDayTimes_TC_11957() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host, now: date(minute: 7))
        let constrained = try page.schedule()
        constrained.replaceTitle(with: "TC11957 picker constraints")
        // A past start must stay within the allowed range.
        try constrained.selectTime(start: true, hour: 9, minute: 0)
        let afterPastStart = try constrained.dateTimes()
        XCTAssertGreaterThanOrEqual(afterPastStart.start, date(minute: 15))
        XCTAssertGreaterThanOrEqual(afterPastStart.end, afterPastStart.start.addingTimeInterval(15 * 60))
        XCTAssertLessThanOrEqual(afterPastStart.end, date(hour: 23, minute: 45))
        // An equal end must move to a later time on the same day.
        try constrained.selectTime(start: true, hour: 15, minute: 0)
        try constrained.selectTime(start: false, hour: 15, minute: 0)
        let afterEqualEnd = try constrained.dateTimes()
        XCTAssertEqual(afterEqualEnd.start, date(hour: 15))
        XCTAssertGreaterThanOrEqual(afterEqualEnd.end, afterEqualEnd.start.addingTimeInterval(15 * 60))
        XCTAssertLessThanOrEqual(afterEqualEnd.end, date(hour: 23, minute: 45))
        _ = try constrained.cancel()
        let beforeScheduling = try await fixtures.list()
        XCTAssertTrue(beforeScheduling.isEmpty)

        // Valid ranges must appear unchanged in the form and the saved meeting.
        for (hour, minute, endHour, endMinute) in [(15, 0, 16, 0), (23, 0, 23, 45), (23, 30, 23, 45)] {
            let form = try page.schedule()
            let title = "TC11957 \(hour):\(minute)"
            form.replaceTitle(with: title)
            try form.selectTime(start: true, hour: hour, minute: minute)
            form.assertDateTimes(start: date(hour: hour, minute: minute), end: date(hour: endHour, minute: endMinute))
            _ = try form.save()
            let meeting = try await onlyMeeting(fixtures, title: title)
            XCTAssertEqual(meeting.startTime, date(hour: hour, minute: minute))
            XCTAssertEqual(meeting.endTime, date(hour: endHour, minute: endMinute))
            XCTAssertTrue(page.row(meeting).waitForExistence(timeout: 15))
            try await fixtures.delete(meeting)
            XCTAssertTrue(page.row(meeting).waitToDisappear(timeout: 15))
        }

        let invalid = try page.schedule()
        invalid.replaceTitle(with: "TC11957 no later end")
        try invalid.selectTime(start: true, hour: 23, minute: 45)
        // Disabled submission or an explicit rejection are both valid. A zero-length record is not.
        if invalid.saveButton.isEnabled {
            invalid.saveButton.tap()
            XCTAssertTrue(
                invalid.schedulingErrorAlert.waitForExistence(timeout: 30),
                "An invalid range was not rejected"
            )
            XCTAssertTrue(invalid.titleField.exists, "The invalid form closed as if scheduling succeeded")
        }
        let afterInvalidRange = try await fixtures.list()
        XCTAssertTrue(afterInvalidRange.isEmpty, "The 23:45 start created a meeting without a later end")
    }

    @MainActor
    func testScheduleSupportedRecurrences_TC_11962() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host, now: date())
        let options: [(title: String, frequency: MeetingFrequency, interval: Int, days: Int)] = [
            (MeetingFormPage.localized("wireMeetings.schedule.time.daily"), .daily, 1, 1),
            (MeetingFormPage.localized("wireMeetings.schedule.time.weekly"), .weekly, 1, 7),
            (MeetingFormPage.localized("wireMeetings.schedule.time.everyTwoWeeks"), .weekly, 2, 14),
            (MeetingFormPage.localized("wireMeetings.schedule.time.everyFourWeeks"), .weekly, 4, 28)
        ]
        // Check each supported choice, its saved rule, and the next occurrence in the list.
        for option in options {
            let form = try page.schedule()
            form.replaceTitle(with: "TC11962 \(option.title)")
            form.repeatButton.tap()
            for title in [MeetingFormPage.localized("wireMeetings.schedule.time.never")] + options.map(\.title) {
                XCTAssertTrue(app.buttons[title].waitForExistence(timeout: 5))
            }
            XCTAssertFalse(app.buttons[MeetingFormPage.localized("wireMeetings.schedule.time.monthly")].exists)
            XCTAssertFalse(app.buttons[MeetingFormPage.localized("wireMeetings.schedule.time.yearly")].exists)
            app.buttons[option.title].tap()
            _ = try form.save()
            let meeting = try await onlyMeeting(fixtures, title: "TC11962 \(option.title)")
            XCTAssertEqual(meeting.recurrence?.frequency, option.frequency)
            XCTAssertEqual(meeting.recurrence?.interval, option.interval)
            XCTAssertTrue(page.row(meeting).waitForExistence(timeout: 15))
            let nextStart = Calendar.current.date(byAdding: .day, value: option.days, to: meeting.startTime)!
            let nextRow = try page.showRow(meeting, start: nextStart)
            XCTAssertEqual(nextRow.staticTexts[Locators.WireMeetings.MeetingRow.title.rawValue].label, meeting.title)
            XCTAssertEqual(
                nextRow.staticTexts[Locators.WireMeetings.MeetingRow.recurrence.rawValue].label,
                option.title
            )
            try await fixtures.delete(meeting)
            XCTAssertTrue(nextRow.waitToDisappear(timeout: 15))
            XCTAssertTrue(page.noUpcomingMeetingsText.waitForExistence(timeout: 15))
        }
    }

    @MainActor
    func testManageScheduleParticipants_TC_11964() async throws {
        let (host, users, _, _) = try await UserHelper.default.registerMeetingsTeam(
            withMemberCount: 3, names: ["Schedule Host", "Schedule Alice", "Schedule Bob", "Schedule Carol"]
        )
        try await registerClients(for: users)
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host, now: date())
        let form = try page.schedule()
        try form.openParticipants()
        XCTAssertTrue(form.member(users[0]).waitForExistence(timeout: 15), "Eligible team users did not appear")
        let selectedTitle = MeetingFormPage.localized("wireMeetings.schedule.members.selected.title")
        for (index, user) in users.enumerated() {
            try form.selectMember(user)
            XCTAssertEqual(form.selectedMembersButton.label, "\(selectedTitle) (\(index + 1))")
            try form.clearMemberSearch()
        }
        form.searchMember(host.name)
        XCTAssertTrue(form.noMemberSearchResults.waitForExistence(timeout: 10))
        XCTAssertFalse(form.member(host).exists, "The host can be added twice")
        try form.clearMemberSearch()
        form.searchMember(users[0].name)
        XCTAssertTrue(form.noMemberSearchResults.waitForExistence(timeout: 10))
        XCTAssertFalse(form.member(users[0]).exists, "A selected user is still an add candidate")
        try form.clearMemberSearch()
        try form.confirmParticipants()
        XCTAssertEqual(form.participantsButton.value as? String, "3")

        try form.openParticipants()
        for user in users {
            XCTAssertTrue(form.member(user).waitForExistence(timeout: 10))
            XCTAssertEqual(
                app.buttons.matching(identifier: Locators.WireMeetings.MeetingForm.memberIdentifier(user.id)).count,
                1
            )
        }
        XCTAssertTrue(form.member(users[1]).waitAndTap())
        XCTAssertEqual(form.selectedMembersButton.label, "\(selectedTitle) (2)")
        try form.confirmParticipants()
        XCTAssertEqual(form.participantsButton.value as? String, "2")
        XCTAssertTrue(form.participantsButton.label.contains(users[0].name))
        XCTAssertTrue(form.participantsButton.label.contains(users[2].name))
        XCTAssertFalse(form.participantsButton.label.contains(users[1].name))
        _ = try form.cancel()
        let meetings = try await fixtures.list()
        XCTAssertTrue(meetings.isEmpty)
    }

    @MainActor
    func testScheduleMoreThanOneHundredParticipants_TC_11967() async throws {
        // This case provisions 101 real MLS clients and selects them through the real picker.
        // Keep its allowance separate from the ordinary five-minute cases.
        executionTimeAllowance = 1800
        let (host, users, ids, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 101)
        XCTAssertEqual(users.count, 101, "The staging fixture must support 101 eligible team members")
        try await registerClients(for: users)
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host, now: date())
        let form = try page.schedule()
        form.replaceTitle(with: "TC11967 101 invitees")
        try form.addParticipants(Array(users.prefix(100)))
        XCTAssertEqual(form.participantsButton.value as? String, "100")
        try form.addParticipants([users[100]])
        XCTAssertEqual(form.participantsButton.value as? String, "101", "The picker imposed a 100-user limit")
        XCTAssertTrue(form.saveButton.isEnabled)
        _ = try form.save(timeout: 180)

        let meeting = try await onlyMeeting(fixtures, title: "TC11967 101 invitees")
        XCTAssertTrue(page.row(meeting).waitForExistence(timeout: 30))
        try await assertMembers(fixtures, meeting: meeting, host: host, invitees: ids)
    }

    @MainActor
    func testRetryScheduleAfterControlledConnectionFailure_TC_11969() async throws {
        let failureID = UUID().uuidString
        let name = "\(UITestConfig.meetingsCreateFailureNotificationPrefix).\(failureID)"
        var token: Int32 = NOTIFY_TOKEN_INVALID
        guard notify_register_check(name, &token) == UInt32(NOTIFY_STATUS_OK) else {
            throw RuntimeError("Meeting create control could not be registered")
        }
        defer { notify_cancel(token) }
        guard notify_set_state(token, 0) == UInt32(NOTIFY_STATUS_OK) else {
            throw RuntimeError("Meeting create control could not hold the request")
        }
        uiTestConfig.meetingsCreateFailureID = failureID

        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host, now: date())
        let form = try page.schedule()
        let title = "TC11969 retained details"
        form.replaceTitle(with: title)
        let weekly = MeetingFormPage.localized("wireMeetings.schedule.time.weekly")
        form.selectRepeat(weekly)
        guard form.saveButton.waitAndTap() else { throw RuntimeError("Schedule button was not available") }
        guard form.loadingIndicator.waitForExistence(timeout: 10), !form.saveButton.exists else {
            throw RuntimeError("Scheduling did not show a loading indicator without a second submit action")
        }
        let whilePending = try await fixtures.list()
        guard whilePending.isEmpty else { throw RuntimeError("A meeting was created while the request was pending") }

        guard notify_set_state(token, 1) == UInt32(NOTIFY_STATUS_OK) else {
            throw RuntimeError("Meeting create control could not fail the request")
        }
        let alert = form.schedulingErrorAlert
        guard alert.waitForExistence(timeout: 10),
              alert.staticTexts[MeetingFormPage.localized("meetings.scheduleModal.error.createFailed")].exists else {
            throw RuntimeError("The expected scheduling error did not appear")
        }
        let afterFailure = try await fixtures.list()
        guard afterFailure.isEmpty else { throw RuntimeError("The failed request created a meeting") }
        guard alert.buttons[MeetingFormPage.localized("wireMeetings.schedule.error.alert.ok")].waitAndTap() else {
            throw RuntimeError("The scheduling error could not be dismissed")
        }
        XCTAssertEqual(form.titleField.value as? String, title)
        form.assertDateTimes(start: date(minute: 15), end: date(hour: 11, minute: 15))
        form.assertRepeat(weekly)

        guard notify_set_state(token, 2) == UInt32(NOTIFY_STATUS_OK) else {
            throw RuntimeError("Meeting create control could not restore the request")
        }
        _ = try form.save()
        let meeting = try await onlyMeeting(fixtures, title: title)
        XCTAssertEqual(meeting.recurrence?.frequency, .weekly)
        XCTAssertEqual(meeting.recurrence?.interval, 1)
        XCTAssertEqual(meeting.startTime, date(minute: 15))
        XCTAssertEqual(meeting.endTime, date(hour: 11, minute: 15))
        XCTAssertTrue(page.row(meeting).waitForExistence(timeout: 15))
    }
}

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

    private func requireConferenceCalling() async throws {
        let configs = try await UserHelper.default.featureConfigsAPI.getFeatureConfigs()
        guard configs.contains(where: {
            guard case let .conferenceCalling(config) = $0 else { return false }
            return config.status == .enabled
        }) else { throw RuntimeError("The call test requires conference calling to be enabled") }
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
        for title in ["", "   ", String(repeating: "🧑🏽‍💻", count: 32)] {
            form.replaceTitle(with: title)
            XCTAssertFalse(form.saveButton.isEnabled)
            if title.count > 64 || title.utf8.count > 256 {
                XCTAssertTrue(form.titleError.waitForExistence(timeout: 5))
            }
        }
        form.replaceTitle(with: String(repeating: "A", count: 65))
        XCTAssertEqual(form.titleField.value as? String, String(repeating: "A", count: 64))
        XCTAssertTrue(form.saveButton.isEnabled)
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

    @MainActor
    func testEditDetailsAndParticipants_TC_11995() async throws {
        executionTimeAllowance = 600
        let (host, users, ids, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 3)
        try await registerClients(for: users)
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host, now: date())
        let creation = try page.schedule()
        creation.replaceTitle(with: "TC11995 original")
        try creation.addParticipants([users[0], users[1]])
        _ = try creation.save()
        let created = try await fixtures.list()
        let original = try XCTUnwrap(created.first)
        let before = try await members(fixtures, meeting: original)
        let hostRole = try XCTUnwrap(before.selfMember?.conversationRole)
        let inviteeRole = try XCTUnwrap(before.others.first { $0.qualifiedID == ids[0] }?.conversationRole)
        let earlier = try await fixtures.create(title: "Earlier meeting", start: date(hour: 14, dayOffset: 1))

        // Change meeting details and add the new participant.
        let form = try page.edit(original)
        form.replaceTitle(with: "TC11995 updated")
        try form.selectStartDate(date(dayOffset: 1))
        try form.selectTime(start: true, hour: 15, minute: 0)
        try form.selectRepeat(.weekly)
        try form.addParticipants([users[2]])
        try form.openParticipants()
        if form.selectedMembersButton.identifier == Locators.WireMeetings.MeetingForm.selectedMembersIdentifier(
            isExpanded: true
        ) {
            guard form.selectedMembersButton.waitAndTap() else { throw RuntimeError("Selected members did not close") }
        }
        for excluded in [users[2], host] {
            form.searchMember(excluded.name)
            XCTAssertTrue(form.noMemberSearchResults.waitForExistence(timeout: 10))
            XCTAssertFalse(form.member(excluded).exists, "A selected participant or the host was offered for addition")
            try form.clearMemberSearch()
        }
        try form.confirmParticipants()

        // Remove one existing invitee and save all changes.
        try form.openParticipants()
        XCTAssertFalse(form.member(host).exists, "The host must not have a removal control")
        guard form.member(users[1]).waitAndTap() else { throw RuntimeError("The invitee could not be removed") }
        try form.confirmParticipants()
        XCTAssertEqual(form.participantsButton.value as? String, "2")
        form.assertDateTimes(start: date(hour: 15, dayOffset: 1), end: date(hour: 16, dayOffset: 1))
        try form.assertRepeat(.weekly)
        _ = try form.save()
        let saved = try await fixtures.list()
        XCTAssertEqual(Set(saved.map(\.id)), Set([original.id, earlier.id]))
        let updated = try XCTUnwrap(saved.first { $0.id == original.id })
        XCTAssertEqual(updated.conversationID, original.conversationID)
        XCTAssertEqual(updated.creatorID, original.creatorID)
        XCTAssertEqual(updated.title, "TC11995 updated")
        XCTAssertEqual(updated.startTime, date(hour: 15, dayOffset: 1))
        XCTAssertEqual(updated.endTime, date(hour: 16, dayOffset: 1))
        XCTAssertEqual(updated.recurrence?.frequency, .weekly)
        try assertTitle(updated.title, meeting: updated, on: page)
        try page.scrollToTop(first: earlier)
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "en_GB")
        dayFormatter.setLocalizedDateFormatFromTemplate("EEEE MMMM d")
        XCTAssertEqual(page.dayHeaders.firstMatch.label, "Tomorrow (\(dayFormatter.string(from: updated.startTime)))")
        XCTAssertLessThan(page.row(earlier).frame.minY, page.row(updated).frame.minY)
        let after = try await members(fixtures, meeting: updated)
        XCTAssertEqual(after.selfMember?.qualifiedID?.id, UUID(uuidString: host.id))
        XCTAssertEqual(after.selfMember?.conversationRole, hostRole)
        XCTAssertEqual(Set(after.others.compactMap(\.qualifiedID)), Set([ids[0], ids[2]]))
        XCTAssertEqual(after.others.count, 2)
        XCTAssertEqual(
            after.others.first { $0.qualifiedID == ids[0] }?.conversationRole,
            inviteeRole
        )
        XCTAssertEqual(after.others.first { $0.qualifiedID == ids[2] }?.conversationRole, inviteeRole)
        for (index, user) in users.enumerated() {
            let participantFixtures = try await MeetingsTestHelper(user: user)
            let visible = try await participantFixtures.list()
            XCTAssertEqual(visible.contains { $0.id == original.id }, index != 1)
            if index == 1 {
                let access = try await participantFixtures.conversationsAPI
                    .getConversations(for: [original.conversationID])
                XCTAssertTrue(
                    access.found.isEmpty,
                    "The removed participant still has access to the meeting conversation"
                )
            }
        }

        // Keep the retained invitee on Meetings while a host API edit arrives without refresh.
        let inviteePage = try launchMeetings(for: users[0], now: date())
        _ = try inviteePage.showRow(updated)
        let synchronized = try await fixtures.update(
            meeting: updated,
            title: "TC11995 synchronized",
            start: date(hour: 14, dayOffset: 1)
        )
        try assertTitle(synchronized.title, meeting: synchronized, on: inviteePage)
    }

    @MainActor
    func testEditAvailabilityForMeetingStates_TC_11997() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        try await requireConferenceCalling()
        let fixtures = try await MeetingsTestHelper(user: host)
        let upcoming = try await fixtures.create(title: "TC11997 upcoming", start: date(hour: 14))
        let ongoing = try await fixtures.create(title: "TC11997 ongoing", start: date(hour: 11), duration: 7200)
        let completed = try await fixtures.create(title: "TC11997 completed", start: date(hour: 9))
        let page = try launchMeetings(for: host, now: date(hour: 12))

        // Upcoming and ongoing meetings must open the edit form.
        for meeting in [upcoming, ongoing] {
            let form = try page.edit(meeting)
            XCTAssertEqual(form.titleField.value as? String, meeting.title)
            form.assertDateTimes(start: meeting.startTime, end: meeting.endTime)
            _ = try form.cancel()
        }

        // Create a real Meet Now meeting and check its edit form during the call.
        guard page.createMeetingButton.waitAndTap(), page.meetNowOption.waitAndTap() else {
            throw RuntimeError("Meet Now did not open")
        }
        let instantForm = try MeetingFormPage()
        instantForm.replaceTitle(with: "TC11997 Meet Now")
        guard instantForm.saveButton.waitAndTap() else { throw RuntimeError("Meet Now did not start") }
        let call = try waitForMeetingCall()
        try minimizeMeetingCall(call)
        let allMeetings = try await fixtures.list()
        let instant = try XCTUnwrap(allMeetings.first { $0.title == "TC11997 Meet Now" })
        let edit = try page.edit(instant)
        edit.assertDateTimes(start: instant.startTime, end: instant.endTime)
        _ = try edit.cancel()

        // Completed meetings must keep Delete and hide Edit.
        try page.openMenu(for: completed)
        XCTAssertFalse(
            app.buttons["Edit meeting"].exists,
            "TC-11997 requires completed meetings to have no Edit action"
        )
        XCTAssertTrue(app.buttons["Delete meeting for all"].exists)
    }

    @MainActor
    func testEditOngoingRecurringMeetingAnchor_TC_11999() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let original = try await fixtures.create(
            title: "TC11999 daily", start: date(), duration: 3600,
            recurrence: MeetingRecurrence(frequency: .daily, interval: 1, until: nil)
        )
        let now = date(minute: 30, dayOffset: 2)
        let today = date(dayOffset: 2)
        let page = try launchMeetings(for: host, now: now)

        // Open today's ongoing occurrence, then a future occurrence of the same series.
        let current = try page.edit(original, start: today)
        current.assertDateTimes(start: today, end: date(hour: 11, dayOffset: 2))
        _ = try current.cancel()
        let future = try page.edit(original, start: date(dayOffset: 3))
        future.assertDateTimes(start: today, end: date(hour: 11, dayOffset: 2))

        // Save from the future row and check that today's occurrence remains.
        _ = try future.save()
        let updated = try await onlyMeeting(fixtures, original: original)
        XCTAssertEqual(updated.startTime, today)
        XCTAssertEqual(updated.endTime, date(hour: 11, dayOffset: 2))
        XCTAssertEqual(updated.recurrence?.frequency, .daily)
        _ = try page.showRow(updated, start: today)
        _ = try page.showRow(updated, start: date(dayOffset: 3))
    }

    @MainActor
    func testRetryEditAfterControlledConnectionFailure_TC_12003() async throws {
        let failureID = UUID().uuidString
        let name = "\(UITestConfig.meetingsUpdateFailureNotificationPrefix).\(failureID)"
        var token: Int32 = NOTIFY_TOKEN_INVALID
        guard notify_register_check(name, &token) == UInt32(NOTIFY_STATUS_OK) else {
            throw RuntimeError("Meeting update control could not be registered")
        }
        defer { notify_cancel(token) }
        guard notify_set_state(token, 0) == UInt32(NOTIFY_STATUS_OK) else {
            throw RuntimeError("Meeting update control could not hold the request")
        }
        uiTestConfig.meetingsUpdateFailureID = failureID
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let original = try await fixtures.create(title: "TC12003 original", start: date(hour: 12))
        let page = try launchMeetings(for: host, now: date())
        let form = try page.edit(original)
        form.replaceTitle(with: "TC12003 retained")
        try form.selectRepeat(.weekly)

        // Hold the update, then fail before any request reaches the backend.
        guard form.saveButton.waitAndTap(), form.loadingIndicator.waitForExistence(timeout: 10) else {
            throw RuntimeError("The update did not show a loading indicator")
        }
        XCTAssertFalse(form.saveButton.exists)
        let pending = try await onlyMeeting(fixtures, original: original)
        assertUnchanged(pending, original: original)
        guard notify_set_state(token, 1) == UInt32(NOTIFY_STATUS_OK) else {
            throw RuntimeError("Meeting update control could not fail the request")
        }
        let alert = form.schedulingErrorAlert
        guard alert.waitForExistence(timeout: 10) else { throw RuntimeError("The update error did not appear") }
        XCTAssertEqual(alert.label, "Could not update meeting")
        XCTAssertTrue(alert.staticTexts.allElementsBoundByIndex.contains {
            $0.label == "Something went wrong while updating the meeting. Please try again."
        })
        let failed = try await onlyMeeting(fixtures, original: original)
        assertUnchanged(failed, original: original)
        guard alert.buttons[Locators.WireMeetings.MeetingForm.errorDismiss.rawValue].firstMatch.waitAndTap() else {
            throw RuntimeError("The update error could not close")
        }
        XCTAssertEqual(form.titleField.value as? String, "TC12003 retained")
        form.assertDateTimes(start: original.startTime, end: original.endTime)
        try form.assertRepeat(.weekly)

        // Restore the request and retry the retained changes on the same meeting.
        guard notify_set_state(token, 2) == UInt32(NOTIFY_STATUS_OK) else {
            throw RuntimeError("Meeting update control could not restore the request")
        }
        _ = try form.save()
        let updated = try await onlyMeeting(fixtures, original: original)
        XCTAssertEqual(updated.title, "TC12003 retained")
        XCTAssertEqual(updated.recurrence?.frequency, .weekly)
        XCTAssertEqual(updated.startTime, original.startTime)
        XCTAssertEqual(updated.endTime, original.endTime)
        try assertTitle(updated.title, meeting: updated, on: page)
    }

    @MainActor
    private func minimizeMeetingCall(_ call: OngoingCallPage) throws {
        // The group-call helper returns ActiveConversationPage; Meetings has a different return page.
        guard call.minimizeCallButton.waitAndTap() else { throw RuntimeError("The meeting call did not minimize") }
        _ = try MeetingsPage()
    }

    @MainActor
    private func waitForMeetingCall() throws -> OngoingCallPage {
        let timer = app.staticTexts[Locators.OngoingCallPage.timeLabel.rawValue]
        let permission = springboard.alerts.buttons["Allow"].firstMatch
        let pattern = "^[0-9]+:[0-5][0-9]$"
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            permission.exists || (timer.exists && timer.label.range(of: pattern, options: .regularExpression) != nil)
        }, object: nil)
        guard XCTWaiter().wait(for: [ready], timeout: 30) == .completed else {
            throw RuntimeError("The meeting call or microphone permission did not appear")
        }
        if permission.exists { permission.tap() }
        let established = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label MATCHES %@", pattern), object: timer
        )
        guard XCTWaiter().wait(for: [established], timeout: 30) == .completed else {
            throw RuntimeError("The meeting call did not connect")
        }
        return try OngoingCallPage()
    }
}

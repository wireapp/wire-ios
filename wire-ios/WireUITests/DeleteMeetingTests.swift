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
import WireFoundation
import WireLocators
import WireNetwork
import XCTest

/// [collaboration]
final class DeleteMeetingTests: WireUITestCase {

    private enum DeleteRole: Equatable {
        case host
        case invitee

        var menuTitle: String {
            switch self {
            case .host: "Delete meeting for all"
            case .invitee: "Delete meeting for me"
            }
        }
    }

    private let fixtureDate = Date()

    @MainActor
    func testDeleteConfirmationMatchesMeetingRole_TC_12005() async throws {
        let (host, users, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        let invitee = users[0]
        try await registerClients(for: users)
        let hostFixtures = try await MeetingsTestHelper(user: host)
        let inviteeFixtures = try await MeetingsTestHelper(user: invitee)
        let page = try launchMeetings(for: host, now: date())
        let meeting = try await schedule(on: page, using: hostFixtures, title: "TC12005", inviting: users)

        // Check the host confirmation, then cancel and check that the row remains.
        let hostAlert = try requestDelete(meeting, on: page, as: .host)
        assertMessage(
            "The meeting will be deleted for you and everybody else. All participants will be notified.",
            in: hostAlert
        )
        attachScreenshot("TC-12005 host confirmation")
        try cancelDelete(hostAlert)
        _ = try page.showRow(meeting)

        // Check the invitee confirmation, then verify that both accounts retain access.
        let inviteePage = try launchMeetings(for: invitee, now: date())
        let inviteeAlert = try requestDelete(meeting, on: inviteePage, as: .invitee)
        assertMessage(
            "The meeting will be deleted from your calendar. This will not affect other participants.",
            in: inviteeAlert
        )
        attachScreenshot("TC-12005 invitee confirmation")
        try cancelDelete(inviteeAlert)
        _ = try inviteePage.showRow(meeting)
        try await assertVisible(meeting, to: hostFixtures, true)
        try await assertVisible(meeting, to: inviteeFixtures, true)
        try await assertConversationAccess(meeting, for: inviteeFixtures, true)
    }

    @MainActor
    func testHostDeletesUpcomingAndCompletedMeetings_TC_12006() async throws {
        let (host, users, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        let invitee = users[0]
        try await registerClients(for: users)
        let hostFixtures = try await MeetingsTestHelper(user: host)
        let inviteeFixtures = try await MeetingsTestHelper(user: invitee)
        let meetings = try await scheduleNonActiveMeetings(for: host, using: hostFixtures, inviting: users)
        let now = date(hour: 12)
        let page = try launchMeetings(for: host, now: now)

        // Delete the upcoming meeting and the completed meeting from Today without a refresh.
        for meeting in meetings {
            try await assertVisible(meeting, to: inviteeFixtures, true)
            try confirmDelete(requestDelete(meeting, on: page, as: .host))
            try assertRemoved(meeting, on: page)
            try await assertVisible(meeting, to: hostFixtures, false)
            try await assertVisible(meeting, to: inviteeFixtures, false)
        }

        // Check the invitee's list after sign-in and sync.
        let inviteePage = try launchMeetings(for: invitee, now: now)
        XCTAssertTrue(inviteePage.noUpcomingMeetingsText.waitForExistence(timeout: 15))
    }

    @MainActor
    func testHostDeletesEntireRecurringSeries_TC_12009() async throws {
        let (host, users, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        try await registerClients(for: users)
        let hostFixtures = try await MeetingsTestHelper(user: host)
        let inviteeFixtures = try await MeetingsTestHelper(user: users[0])
        let page = try launchMeetings(for: host, now: date())
        let meeting = try await schedule(
            on: page, using: hostFixtures, title: "TC12009", inviting: users, recurrence: .daily
        )
        let laterStart = try nextDailyOccurrence(of: meeting)
        try await assertVisible(meeting, to: inviteeFixtures, true)

        // Open a later occurrence and confirm the alert describes the full series.
        _ = try page.showRow(meeting)
        let alert = try requestDelete(meeting, on: page, as: .host, start: laterStart)
        assertMessage(
            "This is a recurring meeting. Deleting it removes every occurrence for you and everybody else. " +
                "All participants will be notified.",
            in: alert
        )
        attachScreenshot("TC-12009 recurring host confirmation")
        try confirmDelete(alert)

        // Both occurrences and the series record must be gone.
        try assertRemoved(meeting, on: page, start: laterStart)
        XCTAssertTrue(page.noUpcomingMeetingsText.waitForExistence(timeout: 15))
        try await assertVisible(meeting, to: hostFixtures, false)
        try await assertVisible(meeting, to: inviteeFixtures, false)
    }

    @MainActor
    func testInviteeDeletesUpcomingAndCompletedMeetingsForSelf_TC_12011() async throws {
        let (host, users, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 2)
        let (invitee, otherInvitee) = (users[0], users[1])
        try await registerClients(for: users)
        let hostFixtures = try await MeetingsTestHelper(user: host)
        let inviteeFixtures = try await MeetingsTestHelper(user: invitee)
        let otherFixtures = try await MeetingsTestHelper(user: otherInvitee)
        let meetings = try await scheduleNonActiveMeetings(for: host, using: hostFixtures, inviting: users)
        let now = date(hour: 12)
        let page = try launchMeetings(for: invitee, now: now)

        // Leave each meeting conversation and verify access for the two other users.
        for meeting in meetings {
            try await assertConversationAccess(meeting, for: inviteeFixtures, true)
            try confirmDelete(requestDelete(meeting, on: page, as: .invitee))
            try assertRemoved(meeting, on: page)
            try await assertConversationAccess(meeting, for: inviteeFixtures, false)
            try await assertVisible(meeting, to: hostFixtures, true)
            try await assertVisible(meeting, to: otherFixtures, true)
            try await assertConversationAccess(meeting, for: otherFixtures, true)
        }

        // Open a fresh list to make sure the completed meeting does not return after sync.
        let syncedPage = try launchMeetings(for: invitee, now: now)
        XCTAssertTrue(syncedPage.noUpcomingMeetingsText.waitForExistence(timeout: 15))
    }

    @MainActor
    func testInviteeDeletesEntireRecurringSeriesForSelf_TC_12014() async throws {
        let (host, users, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 2)
        let hostFixtures = try await MeetingsTestHelper(user: host)
        let inviteeFixtures = try await MeetingsTestHelper(user: users[0])
        let otherFixtures = try await MeetingsTestHelper(user: users[1])
        try await registerClients(for: users)
        let hostPage = try launchMeetings(for: host, now: date())
        let meeting = try await schedule(
            on: hostPage, using: hostFixtures, title: "TC12014", inviting: users, recurrence: .daily
        )
        let laterStart = try nextDailyOccurrence(of: meeting)
        let inviteePage = try launchMeetings(for: users[0], now: date())

        // Delete from a later occurrence. The only confirmation is the self-delete alert.
        _ = try inviteePage.showRow(meeting)
        let alert = try requestDelete(meeting, on: inviteePage, as: .invitee, start: laterStart)
        try confirmDelete(alert)
        try assertRemoved(meeting, on: inviteePage, start: laterStart)
        XCTAssertTrue(inviteePage.noUpcomingMeetingsText.waitForExistence(timeout: 15))

        // Verify that only the acting invitee lost access to the series conversation.
        try await assertConversationAccess(meeting, for: inviteeFixtures, false)
        try await assertVisible(meeting, to: hostFixtures, true)
        try await assertVisible(meeting, to: otherFixtures, true)
        try await assertConversationAccess(meeting, for: otherFixtures, true)
    }

    @MainActor
    func testHostDeletesOngoingScheduledMeetings_TC_12007() async throws {
        let (host, users, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        try await registerClients(for: users)
        try await requireConferenceCalling()
        let hostFixtures = try await MeetingsTestHelper(user: host)
        let inviteeFixtures = try await MeetingsTestHelper(user: users[0])
        let meetings = try await scheduleOngoingMeetings(for: host, using: hostFixtures, inviting: users)
        let page = try launchMeetings(for: host, now: date(minute: 30))

        // Delete once without joining, and once from the list with the call minimized.
        for (meeting, join) in zip(meetings, [false, true]) {
            try await assertVisible(meeting, to: inviteeFixtures, true)
            try showOngoing(meeting, on: page)
            if join { try joinAndMinimize(meeting, on: page) }
            try confirmDelete(requestDelete(meeting, on: page, as: .host))
            try assertRemoved(meeting, on: page)
            if join { assertCallEnded() }

            // Check that neither account can see the record after the host deletes it.
            try await assertVisible(meeting, to: hostFixtures, false)
            try await assertVisible(meeting, to: inviteeFixtures, false)
        }
    }

    @MainActor
    func testInviteeDeletesOngoingScheduledMeetingsForSelf_TC_12012() async throws {
        let (host, users, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 2)
        let (invitee, otherInvitee) = (users[0], users[1])
        try await registerClients(for: users)
        try await requireConferenceCalling()
        let hostFixtures = try await MeetingsTestHelper(user: host)
        let inviteeFixtures = try await MeetingsTestHelper(user: invitee)
        let otherFixtures = try await MeetingsTestHelper(user: otherInvitee)
        let meetings = try await scheduleOngoingMeetings(for: host, using: hostFixtures, inviting: users)
        let page = try launchMeetings(for: invitee, now: date(minute: 30))

        // Leave once without joining, and once from the list with the call minimized.
        for (meeting, join) in zip(meetings, [false, true]) {
            try await assertConversationAccess(meeting, for: inviteeFixtures, true)
            try showOngoing(meeting, on: page)
            if join { try joinAndMinimize(meeting, on: page) }
            try confirmDelete(requestDelete(meeting, on: page, as: .invitee))
            try assertRemoved(meeting, on: page)
            if join { assertCallEnded() }

            // The other users must retain the meeting and its conversation.
            try await assertConversationAccess(meeting, for: inviteeFixtures, false)
            try await assertVisible(meeting, to: hostFixtures, true)
            try await assertVisible(meeting, to: otherFixtures, true)
            try await assertConversationAccess(meeting, for: otherFixtures, true)
        }
    }

    @MainActor
    func testDeleteActiveMeetNowByHostAndInvitee_TC_12015() async throws {
        let (host, users, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 2)
        let (invitee, otherInvitee) = (users[0], users[1])
        try await registerClients(for: users)
        try await requireConferenceCalling()
        let hostFixtures = try await MeetingsTestHelper(user: host)
        let inviteeFixtures = try await MeetingsTestHelper(user: invitee)
        let otherFixtures = try await MeetingsTestHelper(user: otherInvitee)
        let page = try launchMeetings(for: host, now: nil)

        // Start Meet Now, minimize its call, then delete it as the host.
        let hostMeeting = try await startMeetNow(
            on: page, using: hostFixtures, title: "TC12015 host Meet Now", inviting: users
        )
        try await assertVisible(hostMeeting, to: inviteeFixtures, true)
        try confirmDelete(requestDelete(hostMeeting, on: page, as: .host))
        try assertRemoved(hostMeeting, on: page)
        assertCallEnded()
        try await assertVisible(hostMeeting, to: hostFixtures, false)
        try await assertVisible(hostMeeting, to: inviteeFixtures, false)
        try await assertVisible(hostMeeting, to: otherFixtures, false)

        // Start a separate Meet Now. Sign in as an invitee, join, then delete it for self.
        let inviteeMeeting = try await startMeetNow(
            on: page, using: hostFixtures, title: "TC12015 invitee Meet Now", inviting: users
        )
        let inviteePage = try launchMeetings(for: invitee, now: nil)
        try await assertConversationAccess(inviteeMeeting, for: inviteeFixtures, true)
        try joinAndMinimize(inviteeMeeting, on: inviteePage)
        try confirmDelete(requestDelete(inviteeMeeting, on: inviteePage, as: .invitee))
        try assertRemoved(inviteeMeeting, on: inviteePage)
        assertCallEnded()
        try await assertConversationAccess(inviteeMeeting, for: inviteeFixtures, false)
        try await assertVisible(inviteeMeeting, to: hostFixtures, true)
        try await assertConversationAccess(inviteeMeeting, for: hostFixtures, true)
        try await assertVisible(inviteeMeeting, to: otherFixtures, true)
        try await assertConversationAccess(inviteeMeeting, for: otherFixtures, true)
    }

    private func date(hour: Int = 10, minute: Int = 0, dayOffset: Int = 0) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: 2 + dayOffset, to: calendar.startOfDay(for: fixtureDate))!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    @MainActor
    private func launchMeetings(for user: UserInfo, now: Date?) throws -> MeetingsPage {
        app.terminate()
        uiTestConfig.meetingsDate = now
        app.launchEnvironment[UITestConfig.environmentKey] = uiTestConfig.encode()
        app.launchArguments = ["-resetData", "--useEnvStaging", "-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
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

    @MainActor
    private func schedule(
        on page: MeetingsPage,
        using fixtures: MeetingsTestHelper,
        title: String,
        inviting users: [UserInfo],
        startHour: Int? = nil,
        recurrence: MeetingFormPage.RepeatOption? = nil
    ) async throws -> MeetingResponse {
        let form = try page.schedule()
        form.replaceTitle(with: title)
        if let startHour {
            try form.selectTime(start: true, hour: startHour, minute: 0)
            try form.selectTime(start: false, hour: startHour + 1, minute: 0)
        }
        try form.addParticipants(users)
        if let recurrence {
            try form.selectRepeat(recurrence)
        }
        _ = try form.save()
        return try await meeting(titled: title, from: fixtures)
    }

    private func meeting(titled title: String, from fixtures: MeetingsTestHelper) async throws -> MeetingResponse {
        let meetings = try await fixtures.list()
        let matches = meetings.filter { $0.title == title }
        XCTAssertEqual(matches.count, 1, "Expected one meeting named '\(title)'")
        return try XCTUnwrap(matches.first)
    }

    @MainActor
    private func scheduleNonActiveMeetings(
        for host: UserInfo,
        using fixtures: MeetingsTestHelper,
        inviting users: [UserInfo]
    ) async throws -> [MeetingResponse] {
        let page = try launchMeetings(for: host, now: date(hour: 8))
        let upcoming = try await schedule(
            on: page, using: fixtures, title: "Upcoming meeting", inviting: users, startHour: 14
        )
        let completed = try await schedule(
            on: page, using: fixtures, title: "Completed meeting", inviting: users, startHour: 10
        )
        let now = date(hour: 12)
        XCTAssertGreaterThan(upcoming.startTime, now)
        XCTAssertLessThan(completed.endTime, now)
        XCTAssertTrue(Calendar.current.isDate(completed.startTime, inSameDayAs: now))
        return [upcoming, completed]
    }

    private func nextDailyOccurrence(of meeting: MeetingResponse) throws -> Date {
        XCTAssertEqual(meeting.recurrence?.frequency, .daily)
        return try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: meeting.startTime))
    }

    private func confirmDelete(_ alert: XCUIElement) throws {
        guard alert.buttons["Delete"].waitAndTap(), alert.waitToDisappear() else {
            throw RuntimeError("The confirmation did not close after Delete")
        }
    }

    private func assertRemoved(_ meeting: MeetingResponse, on page: MeetingsPage, start: Date? = nil) throws {
        guard page.row(meeting, start: start).waitToDisappear(timeout: 20) else {
            throw RuntimeError("The row for '\(meeting.title)' remained after deletion")
        }
    }

    private func requestDelete(
        _ meeting: MeetingResponse,
        on page: MeetingsPage,
        as role: DeleteRole,
        start: Date? = nil
    ) throws -> XCUIElement {
        try page.openMenu(for: meeting, start: start)
        let action = app.buttons[role.menuTitle]
        let otherRole: DeleteRole = role == .host ? .invitee : .host
        guard action.waitForExistence(timeout: 5), action.isEnabled else {
            throw RuntimeError("The meeting menu did not offer '\(role.menuTitle)'")
        }
        XCTAssertFalse(app.buttons[otherRole.menuTitle].exists)
        action.tap()

        let title = role == .host && meeting.recurrence != nil ? "Delete meeting for everyone" : role.menuTitle
        let alert = app.alerts[title]
        guard alert.waitForExistence(timeout: 5) else {
            throw RuntimeError("The confirmation '\(title)' did not appear")
        }
        XCTAssertTrue(alert.buttons["Delete"].isEnabled)
        XCTAssertTrue(alert.buttons["Cancel"].isEnabled)
        return alert
    }

    private func cancelDelete(_ alert: XCUIElement) throws {
        guard alert.buttons["Cancel"].waitAndTap(), alert.waitToDisappear() else {
            throw RuntimeError("The confirmation did not close after Cancel")
        }
    }

    private func assertMessage(_ message: String, in alert: XCUIElement) {
        XCTAssertTrue(alert.staticTexts.allElementsBoundByIndex.contains { $0.label == message })
    }

    private func assertVisible(
        _ meeting: MeetingResponse,
        to fixtures: MeetingsTestHelper,
        _ visible: Bool
    ) async throws {
        let meetings = try await fixtures.list()
        XCTAssertEqual(meetings.contains { $0.id == meeting.id }, visible, "API visibility for '\(meeting.title)'")
    }

    private func assertConversationAccess(
        _ meeting: MeetingResponse,
        for fixtures: MeetingsTestHelper,
        _ hasAccess: Bool
    ) async throws {
        let response = try await fixtures.conversationsAPI.getConversations(for: [meeting.conversationID])
        XCTAssertTrue(response.failed.isEmpty, "The conversation lookup failed")
        let expectedFound = hasAccess ? [meeting.conversationID] : []
        let expectedNotFound = hasAccess ? [] : [meeting.conversationID]
        XCTAssertEqual(response.found.compactMap(\.qualifiedID), expectedFound)
        XCTAssertEqual(response.notFound, expectedNotFound)
    }

    @MainActor
    private func scheduleOngoingMeetings(
        for host: UserInfo,
        using fixtures: MeetingsTestHelper,
        inviting users: [UserInfo]
    ) async throws -> [MeetingResponse] {
        let page = try launchMeetings(for: host, now: date(hour: 8))
        var meetings: [MeetingResponse] = []
        for title in ["Outside the call", "Inside the call"] {
            try await meetings.append(schedule(on: page, using: fixtures, title: title, inviting: users, startHour: 10))
        }
        return meetings
    }

    private func showOngoing(_ meeting: MeetingResponse, on page: MeetingsPage) throws {
        let join = try page.showRow(meeting).buttons[Locators.WireMeetings.MeetingRow.joinButton.rawValue]
        guard join.waitForExistence(timeout: 10), join.isEnabled else {
            throw RuntimeError("The meeting did not show the ongoing Join action")
        }
    }

    private var restoreCallButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.openOngoingCallButton.rawValue]
    }

    private func requireConferenceCalling() async throws {
        let configs = try await UserHelper.default.featureConfigsAPI.getFeatureConfigs()
        guard configs.contains(where: {
            guard case let .conferenceCalling(config) = $0 else { return false }
            return config.status == .enabled
        }) else { throw RuntimeError("The call test requires conference calling to be enabled") }
    }

    @MainActor
    private func joinAndMinimize(_ meeting: MeetingResponse, on page: MeetingsPage) throws {
        try page.openMenu(for: meeting)
        guard app.buttons["Join now"].waitAndTap() else { throw RuntimeError("Join now did not appear") }
        try minimizeConnectedCall()
    }

    @MainActor
    private func minimizeConnectedCall() throws {
        let timer = app.staticTexts[Locators.OngoingCallPage.timeLabel.rawValue]
        let permission = springboard.alerts.buttons["Allow"].firstMatch
        let pattern = "^[0-9]+:[0-5][0-9]$"
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            permission.exists || (timer.exists && timer.label.range(of: pattern, options: .regularExpression) != nil)
        }, object: nil)
        guard XCTWaiter().wait(for: [ready], timeout: 30) == .completed else {
            throw RuntimeError("The call or microphone permission did not appear")
        }
        if permission.exists { permission.tap() }
        let established = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label MATCHES %@", pattern), object: timer
        )
        guard XCTWaiter().wait(for: [established], timeout: 30) == .completed else {
            throw RuntimeError("The call did not connect")
        }
        let call = try OngoingCallPage()
        guard call.minimizeCallButton.waitAndTap(), restoreCallButton.waitForExistence(timeout: 10) else {
            throw RuntimeError("The minimized call did not stay open")
        }
    }

    private func assertCallEnded() {
        XCTAssertTrue(restoreCallButton.waitToDisappear(timeout: 20), "The active call did not close")
    }

    @MainActor
    private func startMeetNow(
        on page: MeetingsPage,
        using fixtures: MeetingsTestHelper,
        title: String,
        inviting users: [UserInfo]
    ) async throws -> MeetingResponse {
        guard page.createMeetingButton.waitAndTap(), page.meetNowOption.waitAndTap() else {
            throw RuntimeError("Meet Now did not open")
        }
        let form = try MeetingFormPage()
        form.replaceTitle(with: title)
        try form.addParticipants(users)
        guard form.saveButton.waitAndTap() else { throw RuntimeError("Meet Now did not start") }
        try minimizeConnectedCall()
        return try await meeting(titled: title, from: fixtures)
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

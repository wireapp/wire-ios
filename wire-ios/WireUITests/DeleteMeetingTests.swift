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

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

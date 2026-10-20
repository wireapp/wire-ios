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
final class MeetNowTests: WireUITestCase {

    @MainActor
    private func launchMeetings(for user: UserInfo, locale: String = "en_GB") throws -> MeetingsPage {
        app.terminate()
        app.launchEnvironment[UITestConfig.environmentKey] = uiTestConfig.encode()
        app.launchArguments = ["-resetData", "--useEnvStaging", "-AppleLanguages", "(en)", "-AppleLocale", locale]
        app.setDeveloperFlags([.useWireAuthentication: true])
        app.launch()
        return try app.loginUser(email: user.email, password: user.password).acceptPopup().openMeetings()
    }

    @MainActor
    private func openMeetNow(from page: MeetingsPage) throws -> MeetingFormPage {
        guard page.createMeetingButton.waitAndTap(), page.meetNowOption.waitAndTap() else {
            throw RuntimeError("Meet Now did not appear")
        }
        return try MeetingFormPage()
    }

    private func onlyMeeting(_ fixtures: MeetingsTestHelper, title: String) async throws -> MeetingResponse {
        let meetings = try await fixtures.list()
        XCTAssertEqual(meetings.count, 1, "Meet Now must create exactly one meeting")
        let meeting = try XCTUnwrap(meetings.first)
        XCTAssertEqual(meeting.title, title)
        return meeting
    }

    @MainActor
    private func waitForCall(title: String) throws -> OngoingCallPage {
        let timer = app.staticTexts[Locators.OngoingCallPage.timeLabel.rawValue]
        let microphonePermission = springboard.alerts.buttons["Allow"].firstMatch
        let durationPattern = "^[0-9]+:[0-5][0-9]$"
        let callOrPermission = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            microphonePermission.exists || (timer.exists && timer.label.range(
                of: durationPattern, options: .regularExpression
            ) != nil)
        }, object: nil)
        guard XCTWaiter().wait(for: [callOrPermission], timeout: 30) == .completed else {
            throw RuntimeError("Meet Now did not open the call or request microphone access")
        }
        if microphonePermission.exists { microphonePermission.tap() }
        let established = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label MATCHES %@", durationPattern),
            object: timer
        )
        guard XCTWaiter().wait(for: [established], timeout: 30) == .completed else {
            throw RuntimeError("Meet Now did not enter the call without an additional Join action")
        }
        let call = try OngoingCallPage()
        call.verifyGroupNameAndTimerShowingOnceCallJoined(groupName: title)
        return call
    }

    @MainActor
    private func assertMeetingRow(
        _ meeting: MeetingResponse,
        on page: MeetingsPage,
        locale: String = "en_GB"
    ) throws {
        let row = try page.showRow(meeting)
        XCTAssertEqual(row.staticTexts[Locators.WireMeetings.MeetingRow.title.rawValue].label, meeting.title)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: locale)
        formatter.timeStyle = .short
        let expectedTime = "\(formatter.string(from: meeting.startTime)) - \(formatter.string(from: meeting.endTime))"
        XCTAssertEqual(
            row.staticTexts[Locators.WireMeetings.MeetingRow.time.rawValue].label
                .replacingOccurrences(of: "\u{202F}", with: " "),
            expectedTime.replacingOccurrences(of: "\u{202F}", with: " ")
        )
        try page.assertRows([meeting], now: Date(), locale: locale)
    }

    @MainActor
    func testCancelMeetNow_TC_11971() async throws {
        let (host, users, _, _) = try await UserHelper.default.registerMeetingsTeam(withMemberCount: 1)
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host)
        let form = try openMeetNow(from: page)
        XCTAssertTrue(form.titleField.exists)
        let emptyTitleValue = form.titleField.value as? String
        XCTAssertTrue(form.participantsButton.exists)
        XCTAssertTrue(form.cancelButton.exists)
        XCTAssertEqual(form.saveButton.label, "Start")
        XCTAssertFalse(form.saveButton.isEnabled)
        XCTAssertFalse(form.startDateButton.exists)
        XCTAssertFalse(form.startTimeButton.exists)
        XCTAssertFalse(app.buttons[Locators.WireMeetings.MeetingForm.endDate.rawValue].exists)
        XCTAssertFalse(form.endTimeButton.exists)
        XCTAssertFalse(form.repeatButton.exists)
        _ = try form.cancel()
        XCTAssertTrue(page.noUpcomingMeetingsText.waitForExistence(timeout: 10))
        let afterEmptyCancel = try await fixtures.list()
        XCTAssertTrue(afterEmptyCancel.isEmpty)
        XCTAssertFalse(app.buttons[Locators.OngoingCallPage.endOngoingCallButton.rawValue].exists)

        let populatedForm = try openMeetNow(from: page)
        XCTAssertEqual(populatedForm.titleField.value as? String, emptyTitleValue)
        populatedForm.replaceTitle(with: "TC11971 discarded")
        try populatedForm.addParticipants(users)
        XCTAssertEqual(populatedForm.participantsButton.value as? String, "1")
        XCTAssertTrue(populatedForm.saveButton.isEnabled)
        _ = try populatedForm.cancel()
        XCTAssertTrue(page.noUpcomingMeetingsText.waitForExistence(timeout: 10))
        XCTAssertEqual(page.meetingRows.count, 0)
        let afterPopulatedCancel = try await fixtures.list()
        XCTAssertTrue(afterPopulatedCancel.isEmpty)
        XCTAssertFalse(app.buttons[Locators.OngoingCallPage.endOngoingCallButton.rawValue].exists)

        let reopenedForm = try openMeetNow(from: page)
        // Empty UIKit text fields can expose the placeholder as their value.
        XCTAssertFalse(reopenedForm.saveButton.isEnabled)
        XCTAssertEqual(reopenedForm.titleField.value as? String, emptyTitleValue)
        XCTAssertEqual(reopenedForm.participantsButton.value as? String, "0")
        _ = try reopenedForm.cancel()
    }

    @MainActor
    func testMeetNowTitleValidation_TC_11973() async throws {
        let (host, _, _, _) = try await UserHelper.default.registerMeetingsTeam()
        let fixtures = try await MeetingsTestHelper(user: host)
        let page = try launchMeetings(for: host)
        let form = try openMeetNow(from: page)
        XCTAssertFalse(form.saveButton.isEnabled)
        form.replaceTitle(with: "   ")
        XCTAssertFalse(form.saveButton.isEnabled)
        let beforeValidTitle = try await fixtures.list()
        XCTAssertTrue(beforeValidTitle.isEmpty)

        for title in ["TC11973 Standard title", String(repeating: "A", count: 64), String(repeating: "😀", count: 64)] {
            form.replaceTitle(with: title)
            XCTAssertEqual(form.titleField.value as? String, title)
            XCTAssertTrue(form.saveButton.isEnabled)
            XCTAssertFalse(form.titleError.exists)
        }
        let invalidTitle = String(repeating: "B", count: 65)
        form.replaceTitle(with: invalidTitle)
        XCTAssertEqual(form.titleField.value as? String, invalidTitle)
        XCTAssertTrue(form.titleError.waitForExistence(timeout: 5))
        XCTAssertFalse(form.saveButton.isEnabled)
        // The separate 256-byte limit also applies when the character count is below 64.
        form.replaceTitle(with: String(repeating: "🧑🏽‍💻", count: 32))
        XCTAssertTrue(form.titleError.waitForExistence(timeout: 5))
        XCTAssertFalse(form.saveButton.isEnabled)
        let beforeStart = try await fixtures.list()
        XCTAssertTrue(beforeStart.isEmpty)

        let title = "TC11973 Meet Now & + / 😀"
        form.replaceTitle(with: title)
        XCTAssertEqual(form.titleField.value as? String, title)
        XCTAssertTrue(form.saveButton.isEnabled)
        XCTAssertTrue(form.saveButton.waitAndTap())
        let call = try waitForCall(title: title)
        let meeting = try await onlyMeeting(fixtures, title: title)
        XCTAssertTrue(call.minimizeCallButton.waitAndTap())
        try assertMeetingRow(meeting, on: MeetingsPage())
    }
}

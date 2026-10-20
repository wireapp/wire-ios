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
}

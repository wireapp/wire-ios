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

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

import WireLocators
import XCTest

/// Verifies that the `ZMUserSession` is deallocated after logout. (WPB-18909)
final class LogoutMemoryLeakUITests: WireUITestCase {

    override func additionalLaunchArguments() -> [String] {
        ["-EnableMemoryTracking"]
    }

    @MainActor
    func testUserSessionDeallocatedAfterLogout() async throws {
        // Given
        let user = try await UserHelper.default.createPersonalUser()
        _ = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
        try showDeveloperTools().checkUserSessionDeallocated(false).hide()

        // When
        _ = try ConversationsPage()
            .openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(user.password)
        XCTAssertNoThrow(try WelcomePage())

        // Then
        try showDeveloperTools().checkUserSessionDeallocated(true).hide()
    }

    private func dismissSessionExpiredAlertIfPresent() {
        let okButton = app.alerts[Locators.SessionExpiredPage.alertTitle.rawValue]
            .buttons[Locators.SessionExpiredPage.okButton.rawValue]
        if okButton.waitForExistence(timeout: 5) {
            okButton.tap()
        }
    }

    private func showDeveloperTools() throws -> DeveloperToolsPage {
        dismissSessionExpiredAlertIfPresent()
        simulateShakeGesture()
        return try DeveloperToolsPage()
    }

}

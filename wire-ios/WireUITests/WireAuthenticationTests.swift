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

import XCTest

final class WireAuthenticationTests: WireUITestCase {

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testLoginWithWrongEmail_NextIsDisabled_TC_9456() throws {

        let welcomePage = try WelcomePage()
            .typeEmailOrSSO("notAnEmail.com")

        XCTAssertFalse(welcomePage.nextButton.isEnabled, "nextButton should be disabled if no email")
    }

    @MainActor
    func testLoginWithoutPassword_NextIsDisabled_TC_9457() throws {

        let loginPage = try WelcomePage()
            .enterEmailOrSSO(LoginCredentials.email)

        XCTAssertEqual(app.textFields["Enter email"].value as? String, LoginCredentials.email)
        XCTAssertTrue(loginPage.nextButton.waitForExistence(timeout: 2.0))
        XCTAssertFalse(loginPage.nextButton.isEnabled, "nextButton should be disabled if no password")
    }

    /// [critical]
    @MainActor
    func testLogout_TC_8946() async throws {
        // Login user A
        let userA = try await UserHelper.default.createPersonalUser()
        _ = try skipUiLogin(user: userA)

        // Login to user B
        let userB = try await UserHelper.default.createPersonalUser()
        _ = try ConversationsPage()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        _ = try app
            .loginUser(email: userB.email, password: userB.password)
            .acceptPopup()

        // Verify that user B is logged in and selected
        let accountSettingsB = try ConversationsPage()
            .openSettings()
            .openAccountSettings()
        XCTAssertEqual(accountSettingsB.getAccountName(), userB.name, "User B should be selected")

        // Logout user B
        try accountSettingsB
            .logout()
            .enterPassword(userB.password, expectWelcomePage: false)

        // Verify that user A is logged in and selected
        let accountSettingsA = try ConversationsPage()
            .openSettings()
            .openAccountSettings()
        XCTAssertEqual(accountSettingsA.getAccountName(), userA.name, "User A should be selected")

        // Logout user A
        try accountSettingsA
            .logout()
            .enterPassword(userA.password, expectWelcomePage: true)
    }

}

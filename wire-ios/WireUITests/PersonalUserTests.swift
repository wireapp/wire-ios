//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class PersonalUsersTests: WireUITestCase {

    @MainActor
    func test_Register_asPersonalUser() async throws {
        let user = UserGenerator.generateUniqueUserInfo()

        let welcomePage = try WelcomePage()

        let createAccountPage = try welcomePage
            .enterEmailOrSSO(user.email)
            .tapCreatePersonalAccountLink()

        let verificationPage = try createAccountPage
            .tapConfirmCreateAccount()
            .tapAcceptButton()

        let verificationCode = try await InbucketClient.getVerificationCode(email: user.email)

        let setNamePage = try verificationPage
            .enterVerificationCode(verificationCode)

        let setPasswordPage = try setNamePage
            .setName(user.name)

        let setUsernamePage = try setPasswordPage
            .setPassword(user.password)
            .acceptPopup()

        let conversationsPage = try setUsernamePage
            .setUsername(user.username)

        let settingsPage = try conversationsPage
            .openSettings()

        let accountPage = try settingsPage
            .openAccountSettings()

        let accountName = try XCTUnwrap(accountPage.getAccountName())
        XCTAssertEqual(accountName, user.name, "Account name didn't match \(user.name)")
        XCTAssertTrue(accountPage.getUsername().contains(user.username), "Username didn't contain \(user.username)")
        XCTAssertEqual(accountPage.getEmail(), user.email, "Email didn't contain \(user.email)")

        try accountPage.logout()
            .enterPassword(user.password)
    }

    @MainActor
    func test_Login_asExistingPersonalUser() async throws {
        let user = try await userManager.createPersonalUser()

        _ = try WelcomePage()
            .enterEmailOrSSO(user.email)
            .enterPassword(user.password)
            .acceptFirstTimeAlert()
            .acceptPopup()
            .openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(user.password)
    }
}

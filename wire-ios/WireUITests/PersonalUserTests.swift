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

final class PersonalUsersTests: WireUITestCase {

    @MainActor
    func testCritical_Register_asPersonalUser() async throws {
        let user = UserGenerator.generateUniqueUserInfo()

        let welcomePage = try WelcomePage()

        let createPersonalAccountFormPage = try welcomePage
            .enterEmailOrSSO(user.email)
            .tapCreatePersonalAccountLink()

        let verificationPage = try createPersonalAccountFormPage
            .enterName(user.name)
            .enterPassword(user.password)
            .enterConfirmPassword(user.password)
            .tapContinueButton()
            .tapAcceptButton()

        let verificationCode = try await InbucketClient.getVerificationCode(email: user.email)

        let setUsernamePage = try verificationPage
            .enterVerificationCodeAndConfirm(verificationCode)

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
    }

    @MainActor
    func testCritical_Login_asExistingPersonalUser() async throws {
        let user = try await userHelper.createPersonalUser()

        let firstTimePage = try app.loginUser(email: user.email, password: user.password)
        _ = try  firstTimePage.acceptPopup(with: self)
            .openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(user.password)
    }

    @MainActor
    func testCritical_PersonalAccountLifecycle() async throws {
        let userA = try await userHelper.createPersonalUser()
        let userB = try await userHelper.createPersonalUser()
        let messageFromUserB = "Hello from \(userB.name)"

        let userDetailsPage = try app.loginUser(email: userA.email, password: userA.password)
            .acceptPopup(with: self)
            .tapPlusButtonToCreateGroup()
            .tapSearchBox()
            .searchUserByUserHandle(userB.username)
            .tapSearchedUserCell()

        let userNameB = try XCTUnwrap(userDetailsPage.getUserName())
        XCTAssertEqual(userNameB, "@\(userB.username)", "username didn't match @\(userB.username)")

        _ = try userDetailsPage.sendConnectionRequest()
            .closeProfilePage()
            .closeNewConversationPage()
            .openUserAccountPageForUser(with: userA.name)
            .tapAddAccountOrTeamButton()
        let connectionRequestsPage = try app.loginUser(email: userB.email, password: userB.password)
            .acceptPopup(with: self)
            .openPendingRequest()

        let userNameA = try XCTUnwrap(connectionRequestsPage.getUserName())
        XCTAssertEqual(userNameA, "@\(userA.username)", "username didn't match @\(userA.username)")

        var conversationsPage = try connectionRequestsPage.acceptConnectionRequest()
            .sendMessage(messageFromUserB)
            .goBackToConversationPage()

        let nameA = try XCTUnwrap(conversationsPage.getNameLabel())
        XCTAssertEqual(nameA, userA.name, "name didn't match \(userA.name)")

        conversationsPage = try conversationsPage.openUserAccountPageForUser(with: userB.name)
            .switchUserAccountForUser(withName: userA.name)

        let nameUserB = try XCTUnwrap(conversationsPage.getNameLabel())
        XCTAssertEqual(nameUserB, userB.name, "name didn't match \(userB.name)")

        let activeConversationPage = try conversationsPage.openConversation()

        let fetchMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertTrue(
            fetchMessages.contains(messageFromUserB),
            "Expected message '\(messageFromUserB)' not found in sent messages: \(fetchMessages)"
        )

        var accountSettingsPage = try activeConversationPage.goBackToConversationPage()
            .longPressForMoreOptionOnConversation()
            .blockUser()
            .openSettings()
            .openAccountSettings()

        let accountNameUserA = try XCTUnwrap(accountSettingsPage.getAccountName())
        accountSettingsPage = try accountSettingsPage.deleteAccount()
            .openSettings()
            .openAccountSettings()

        let accountNameUserB = try XCTUnwrap(accountSettingsPage.getAccountName())

        XCTAssertNotEqual(accountNameUserA, accountNameUserB, "Account name didn't change after deleting")
    }
}

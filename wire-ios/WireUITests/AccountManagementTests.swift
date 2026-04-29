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

import WireFoundation
import XCTest

final class AccountManagementTests: WireUITestCase {

    var teamMember: UserInfo!

    @MainActor
    func testAccountManagementLockWithPasscode_TC_8950() async throws {

        let passcode = UserGenerator.generateAppPasscode()

        let user = try await UserHelper.default.createPersonalUser()

        let page = try await app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openSettings()
            .openOptionsMenu()
            .enableLockWithPasscode()
            .SetPasscode(passcode)
            .backgroundAndResume(app: app, forDelay: 2)

        XCTAssertFalse(
            page.conversationsButton.exists,
            "App incorrectly showing conversations page without app passcode"
        )

        _ = try page.enterPasscode(passcode)

    }

    /// testiny: https://app.testiny.io/IOS/testcases/tcf/1287/tc/8796
    @MainActor
    func testAccountManagementUpdateEmailAndResetPassword_TC_8933_TC_8931() async throws {

        let updatedUserDetails = UserGenerator.generateUniqueUserInfo()

        let user = try await UserHelper.default.createPersonalUser()

        let verifyEmailPage = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openSettings()
            .openAccountSettings()
            .tapEmailField()
            .updateEmailAndSave(with: updatedUserDetails.email)

        XCTAssertTrue(
            app.staticTexts["Resend to \(updatedUserDetails.email)"].exists,
            "Expected static text label 'Resend to \(updatedUserDetails.email)' to be visible, but it was missing."
        )

        let webViewPage = try verifyEmailPage.goBacktoAccountSetting()
            .tapOnResetPasswordButton()

        XCTAssertTrue(webViewPage.webViewOpened(), "WebView didn't open")

    }

    @MainActor
    func testSwitchingAccounts_TC_8941() async throws {
        // Create user A on staging with a single conversation
        let userA = try await UserHelper.default.createPersonalUser()
        let conversationA = "Conversation A"
        try await UserHelper.default.createGroupConversations(qualifiedIds: [], owner: userA, groupName: conversationA)

        // Create user B on staging with a single conversation
        let userB = try await UserHelper.default.createPersonalUser()
        let conversationB = "Conversation B"
        try await UserHelper.default.createGroupConversations(qualifiedIds: [], owner: userB, groupName: conversationB)

        // Create user C on anta with a single conversation
        let userC = try await UserHelper.instance(backend: .anta).createPersonalUser()
        let conversationC = "Conversation C"
        try await UserHelper.instance(backend: .anta).createGroupConversations(
            qualifiedIds: [],
            owner: userC,
            groupName: conversationC
        )

        // Login to user A
        _ = try app
            .loginUser(email: userA.email, password: userA.password)
            .acceptPopup()

        // Login to user B
        _ = try ConversationsPage()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        _ = try app
            .loginUser(email: userB.email, password: userB.password)
            .acceptPopup()

        // Login to user C
        _ = try ConversationsPage()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        try switchBackend(target: .anta)

        _ = try app
            .loginUser(email: userC.email, password: userC.password)
            .acceptPopup()

        // Switch account to user A and verify the correct conversation is shown
        _ = try ConversationsPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: userA.name)

        XCTAssert(try ConversationsPage().conversationCell(named: conversationA).waitForExistence(timeout: 2.0))

        // Switch account to user B and verify the correct conversation is shown
        _ = try ConversationsPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: userB.name)

        XCTAssert(try ConversationsPage().conversationCell(named: conversationB).waitForExistence(timeout: 2.0))

        // Switch account to user C and verify the correct conversation is shown
        _ = try ConversationsPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: userC.name)

        XCTAssert(try ConversationsPage().conversationCell(named: conversationC).waitForExistence(timeout: 2.0))
    }

}

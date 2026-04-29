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

    @MainActor
    func testAccountSwitching() async throws {
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

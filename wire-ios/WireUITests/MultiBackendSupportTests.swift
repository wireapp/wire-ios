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

/// [core-messenger]
final class MultiBackendSupportTests: WireUITestCase {

    @MainActor
    private func testLoginToBackend(
        _ backend: BackendTarget
    ) async throws -> (AccountSettingsPage, UserInfo) {

        let user = try await UserHelper.instance(backend: backend).createPersonalUser()

        let firstTimePage = try app.loginUser(email: user.email, password: user.password)

        let accountPage = try firstTimePage
            .acceptPopup()
            .openSettings()
            .openAccountSettings()

        try verifySwitchingAccount(
            accountPage: accountPage,
            expectedUser: user,
            expectedDomain: backend.domainInfo
        )

        return (accountPage, user)
    }

    /// [critical]
    @MainActor
    func testAddMultiBackendAccounts_TC_8940_8814() async throws {

        var (accountPageBackend1, userBackend1) = try await testLoginToBackend(.staging)

        _ = try accountPageBackend1
            .backToSettings()
            .switchToConversationsTab()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        try switchBackend(target: .anta)

        let (accountPageBackend2, _) = try await testLoginToBackend(.anta)

        accountPageBackend1 = try accountPageBackend2
            .backToSettings()
            .switchToConversationsTab()
            .openUserProfilePage()
            .verifyAddedAccountInfo(for: userBackend1.name)
            .switchUserAccountForUser(withName: userBackend1.name)
            .openSettings()
            .openAccountSettings()

        // Verify switching account
        try verifySwitchingAccount(
            accountPage: accountPageBackend1,
            expectedUser: userBackend1,
            expectedDomain: BackendTarget.staging.domainInfo
        )
    }

    /// [critical]
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

    @MainActor
    func testReLoginWhenMultipleBackends_TC_10550() async throws {
        // Login to account A
        let userA = try await UserHelper.instance(backend: .staging).createPersonalUser()
        _ = try app
            .loginUser(email: userA.email, password: userA.password)
            .acceptPopup()

        // Go to Anta login
        _ = try ConversationsPage()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        try switchBackend(target: .anta)

        // Login to account B
        let userB = try await UserHelper.instance(backend: .anta).createPersonalUser()
        _ = try app
            .loginUser(email: userB.email, password: userB.password)
            .acceptPopup()

        // Switch to account A
        _ = try ConversationsPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: userA.name)

        // Switch to account B
        _ = try ConversationsPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: userB.name)

        // Logout account B
        _ = try ConversationsPage()
            .openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(userB.password, expectWelcomePage: false)

        // Go to Anta login
        _ = try ConversationsPage()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        try switchBackend(target: .anta)

        // Re-login to account B
        _ = try app
            .loginUser(email: userB.email, password: userB.password)

        // Verify logged into account B
        let accountSettingsPage = try ConversationsPage()
            .openSettings()
            .openAccountSettings()

        try verifySwitchingAccount(
            accountPage: accountSettingsPage,
            expectedUser: userB,
            expectedDomain: BackendTarget.anta.domainInfo
        )
    }

    private func verifySwitchingAccount(
        accountPage: AccountSettingsPage,
        expectedUser: UserInfo,
        expectedDomain: String
    ) throws {

        let accountName = try XCTUnwrap(accountPage.getAccountName())
        let domainInfo = try XCTUnwrap(accountPage.getDomainInfo())
        let username = accountPage.getUsername()
        let email = accountPage.getEmail()

        XCTAssertEqual(accountName, expectedUser.name, "Account name didn't match \(expectedUser.name)")
        XCTAssertTrue(
            username.contains(expectedUser.username),
            "Username didn't contain \(expectedUser.username)"
        )
        XCTAssertEqual(email, expectedUser.email, "Email didn't match \(expectedUser.email)")
        XCTAssertEqual(domainInfo, expectedDomain, "Domain info \(domainInfo) mismatched on account page")
    }

}

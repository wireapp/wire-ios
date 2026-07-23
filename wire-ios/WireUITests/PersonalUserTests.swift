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
final class PersonalUsersTests: WireUITestCase {

    private typealias ConversationFilterTeam = (
        teamOwner: UserInfo,
        teamMember: UserInfo,
        groupName: String,
        channelName: String
    )

    @MainActor
    private func registerTeamForConversationFilter() async throws -> ConversationFilterTeam {
        let groupName = UserGenerator.generateRandomConversationName()
        let channelName = UserGenerator.generateRandomConversationName()
        let (teamOwner, teamMembers, qualifiedIDs, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .channel(channelName)
        )

        try await UserHelper.default.createGroupConversations(
            qualifiedIds: qualifiedIDs,
            owner: teamOwner,
            groupName: groupName
        )

        return (
            teamOwner,
            try XCTUnwrap(teamMembers.first),
            groupName,
            channelName
        )
    }

    @MainActor
    private func loginAndCreateOneOnOneConversation(for user: UserInfo) throws -> ConversationsPage {
        try skipUiLogin(user: user)
            .tapPlusButtonToCreateGroup()
            .openUserDetailsInContactList()
            .tapStartConversationButton()
            .goBackToConversationPage()
    }

    /// [critical]
    @MainActor
    func testRegisterAsPersonalUser_TC_8971() async throws {
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

        let verificationCode = try await InbucketClient.getVerificationCode(email: user.email, backend: .staging)

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

    /// [critical]
    @MainActor
    func testLoginAsExistingPersonalUser_TC_8804() async throws {
        let user = try await UserHelper.default.createPersonalUser()

        let firstTimePage = try app.loginUser(email: user.email, password: user.password)
        _ = try  firstTimePage.acceptPopup()
            .openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(user.password)
    }

    /// [critical]
    @MainActor
    func testSearchUserAndConnectionRequestLifecycle_TC_8806_8807_8808_8809_8810() async throws {
        let userA = try await UserHelper.default.createPersonalUser()
        let userB = try await UserHelper.default.createPersonalUser()
        let userC = try await UserHelper.default.createPersonalUser()
        let domain = BackendTarget.staging.domainInfo

        let userDetailsPage = try skipUiLogin(user: userA)
            .tapPlusButtonToCreateGroup()
            .tapSearchBox()
            .searchUserByUserHandle(userB.username)
            .tapSearchedUserCell(handle: userB.username)

        let userNameB = try XCTUnwrap(userDetailsPage.getUserName())
        XCTAssertEqual(userNameB, "@\(userB.username)", "username didn't match @\(userB.username)")

        _ = try userDetailsPage.sendConnectionRequest()
            .closeProfilePage()
            .closeNewConversationPage()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        let connectionRequestsPage = try app.loginUser(email: userB.email, password: userB.password)
            .acceptPopup()
            .openPendingRequest()

        let userNameA = try XCTUnwrap(connectionRequestsPage.getUserName())
        XCTAssertEqual(userNameA, "@\(userA.username)", "username didn't match @\(userA.username)")

        let conversationsPage = try connectionRequestsPage.acceptConnectionRequest()
            .goBackToConversationPage()

        let nameA = try XCTUnwrap(conversationsPage.getNameLabel())
        XCTAssertEqual(nameA, userA.name, "name didn't match \(userA.name)")

        try await UserHelper.default.sendConnectionRequestToUser(domain: domain, userId: userB.id)

        let secondConnectionRequestsPage = try conversationsPage.openPendingRequest()
        let userNameC = try XCTUnwrap(secondConnectionRequestsPage.getUserName())
        XCTAssertEqual(userNameC, "@\(userC.username)", "username didn't match @\(userC.username)")

        let otherUserConversationPage = try secondConnectionRequestsPage.rejectConnectionRequest()
            .goBackToConversationPage()

        XCTAssertFalse(
            otherUserConversationPage.conversationCell(named: userC.name).exists,
            "Conversation with rejected user \(userC.name) is still shown after rejecting @\(userC.username) request"
        )
    }

    /// [critical]
    @MainActor
    func testBlockAndDeleteUser_TC_8867_9450() async throws {

        let userB = try await UserHelper.default.createPersonalUser()
        let userA = try await UserHelper.default.createPersonalUser()
        let domain = BackendTarget.staging.domainInfo

        try await UserHelper.default.sendConnectionRequestToUser(domain: domain, userId: userB.id)
        try await UserHelper.default.acceptConnectionRequestFromUser(domain: domain, user1: userB, userId: userA.id)

        _ = try skipUiLogin(user: userA)
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        let conversationsPage = try app.loginUser(email: userB.email, password: userB.password)
            .acceptPopup()
            .longPressForMoreOptionOnConversation()
            .blockUser()

        let blockedConversationCell = conversationsPage.conversationCell.buttons[userA.name]

        XCTAssertFalse(
            blockedConversationCell.exists,
            "Blocked conversation is still visible after blocking"
        )

        var accountSettingsPage = try conversationsPage.openSettings()
            .openAccountSettings()
        let accountNameUserB = try XCTUnwrap(accountSettingsPage.getAccountName())

        accountSettingsPage = try accountSettingsPage.deleteAccount()
            .openSettings()
            .openAccountSettings()

        let accountNameUserA = try XCTUnwrap(accountSettingsPage.getAccountName())

        XCTAssertNotEqual(
            accountNameUserA,
            accountNameUserB,
            "Account name didn't change after deleting, still showing deleted one"
        )
    }

    @MainActor
    func testAddConversationAsFavourite_TC_8869() async throws {
        let groupName = UserGenerator.generateRandomConversationName()
        let (teamOwner, _, _, _) = try await UserHelper.default
            .registerTeam(
                withMemberCount: 1,
                conversation: .group(groupName)
            )

        let conversationsPage = try skipUiLogin(user: teamOwner)
        XCTAssertTrue(
            conversationsPage.conversationCell(named: groupName).waitForExistence(timeout: 15),
            "Conversation \(groupName) did not appear for authenticated user \(teamOwner.email)"
        )

        _ = try conversationsPage
            .longPressForMoreOptionOnConversation()
            .markConversationAsFavourite()
            .longPressForMoreOptionOnConversation()

        XCTAssertTrue(
            conversationsPage.removeFavouriteButtonOnMoreOptions.exists,
            "Conversation not added to favourite as 'Remove from Favourites' not shown"
        )
    }

    @MainActor
    func testFilterConversationByFavourite_TC_8874() async throws {
        let groupName = UserGenerator.generateRandomConversationName()
        let (teamOwner, _, _, _) = try await UserHelper.default
            .registerTeam(
                withMemberCount: 1,
                conversation: .group(groupName)
            )

        let conversationsPage = try skipUiLogin(user: teamOwner)
        XCTAssertTrue(
            conversationsPage.conversationCell(named: groupName).waitForExistence(timeout: 15),
            "Conversation \(groupName) did not appear for authenticated user \(teamOwner.email)"
        )

        _ = try conversationsPage
            .longPressForMoreOptionOnConversation()
            .markConversationAsFavourite()
            .filterConversationByFavourite()

        let conversationsCell = conversationsPage.conversationCell

        XCTAssertTrue(
            conversationsPage.textFilteredByFavourites.exists,
            "Favorites filter label did not appear"
        )

        XCTAssertTrue(
            conversationsCell.waitForExistence(timeout: 5),
            "Favourite group conversation did not appear"
        )

        XCTAssertEqual(
            conversationsCell.label,
            groupName,
            "Conversation cell label did not match groupName"
        )

        _ = try conversationsPage.filterConversationByOneOnOne()

        XCTAssertFalse(
            conversationsPage.conversationCell.exists,
            "Favourite group conversation still appearing in OneOnOne conversations"
        )

        XCTAssertTrue(
            conversationsPage.textFilteredByOneOnOne.exists,
            "OneOnOne filter label did not appear"
        )
    }

    @MainActor
    func testFilterConversationByGroupsChannelsAndOneOnOne_TC_8875_8876_8877() async throws {
        // GIVEN
        let team = try await registerTeamForConversationFilter()

        // WHEN
        let conversationsPage = try loginAndCreateOneOnOneConversation(for: team.teamOwner)

        // WHEN - Filtering by group
        _ = try conversationsPage.filterConversationByGroup()

        // THEN
        XCTAssertTrue(
            conversationsPage.conversationCell(named: team.groupName).waitForExistence(timeout: 5),
            "Group conversation did not appear"
        )

        // WHEN - Filtering by channel
        _ = try conversationsPage.filterConversationByChannel()

        // THEN
        XCTAssertTrue(
            conversationsPage.conversationCell(named: team.channelName).waitForExistence(timeout: 5),
            "Channel conversation did not appear"
        )

        // WHEN - Filtering by OneOnOne
        _ = try conversationsPage.filterConversationByOneOnOne()

        // THEN
        XCTAssertTrue(
            conversationsPage.conversationCell(named: team.teamMember.name).waitForExistence(timeout: 5),
            "OneOnOne conversation did not appear"
        )
    }

    @MainActor
    func testMoveConversationToFolderAndFilterByFolder_TC_8870_8878() async throws {
        // GIVEN
        let team = try await registerTeamForConversationFilter()

        // WHEN
        let conversationsPage = try skipUiLogin(user: team.teamOwner)
        XCTAssertTrue(
            conversationsPage.conversationCell(named: team.groupName).waitForExistence(timeout: 15),
            "Conversation \(team.groupName) did not appear for authenticated user \(team.teamOwner.email)"
        )

        _ = try conversationsPage
            .longPressForMoreOptionOnConversation(named: team.groupName)
            .moveConversationToNewFolder(named: team.groupName)
            .filterConversationByFolder(named: team.groupName)

        // THEN
        XCTAssertTrue(
            conversationsPage
                .conversationCell(named: team.groupName)
                .waitForExistence(timeout: 5),
            "Conversation moved to folder did not appear in folder filter"
        )

        XCTAssertEqual(
            conversationsPage.conversationCells.count,
            1,
            "Expected only one conversation to be visible after filtering by folder"
        )
    }
}

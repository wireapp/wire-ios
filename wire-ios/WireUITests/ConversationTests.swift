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

final class ConversationTests: WireUITestCase {

    @MainActor
    func testClearContent_TC_9488() async throws {
        let stagingTeam = try await UserHelper.default.registerTeam(withMemberCount: 2)
        let userA = try XCTUnwrap(stagingTeam.teamMembers.first)
        let userB = try XCTUnwrap(stagingTeam.teamMembers.last)

        let conversationsPage = try await loginToBackend(user: userA)

        // WHEN
        try conversationsPage
            .tapPlusButtonToCreateGroup()
            .tapNewGroupButton()
            .enterGroupName("test")
            .tapMemberCells(withLabelPrefixes: [userB.name])
            .doneSelectingMembers()
            .sendMessage("test")
            .sendMessage("test2")
            .goBackToConversationPage()
            .longPressForMoreOptionOnConversation()
            .clearContent()

        // THEN
        XCTAssertTrue(conversationsPage.conversationCell.exists)

        let activeConversationPage = try conversationsPage
            .openConversation()
        let sentMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertTrue(sentMessages.isEmpty)
    }

    @MainActor
    func testLeaveGroup_TC_8862() async throws {
        // GIVEN
        let (_, members, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 2,
            conversation: .group("Test")
        )
        let activeConversationPage = try app.loginUser(email: members[0].email, password: members[0].password)
            .acceptPopup()
            .openConversation()
            // WHEN
            .sendMessage("test")
            .openConversationDetails()
            .moreOptionsConversationDetails()
            .leaveOptionsConversationDetails()
            .leaveConversation()
            .closeConversationDetails()

        // THEN
        let userMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertEqual(userMessages.count, 1)

        XCTAssertTrue(activeConversationPage.userLeftSystemMessage.exists, "the system message is missing")
    }

    @MainActor
    func testGuestPresentBannerWhenGuestAdded_TC_8864() async throws {
        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        var (owner, _, _, _) = try await UserHelper.default.registerTeam()
        let (_, otherTeamMembers, otherTeamMemberQualifiedIDs, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 1
        )
        let guest = try XCTUnwrap(otherTeamMembers.first)
        let guestQualifiedID = try XCTUnwrap(otherTeamMemberQualifiedIDs.first)
        let domain = UserHelper.default.backend.domainInfo

        try await UserHelper.default.login(user: &owner)
        try await UserHelper.default.sendConnectionRequestToUser(domain: domain, userId: guestQualifiedID.id.uuidString)
        try await UserHelper.default.acceptConnectionRequestFromUser(domain: domain, user1: guest, userId: owner.id)

        try await UserHelper.default.createGroupConversations(
            qualifiedIds: [guestQualifiedID],
            owner: owner,
            groupName: groupName
        )

        // WHEN
        let activeConversationPage = try app.loginUser(
            email: owner.email,
            password: owner.password
        )
        .acceptPopup()
        .openConversationWithGuest(groupName: groupName)

        // THEN
        XCTAssertTrue(
            activeConversationPage.guestsArePresentBanner.waitForExistence(timeout: 5),
            "\(owner.name) should see guests banner in group with guest"
        )

        let conversationDetailsPage = try activeConversationPage.openConversationDetails()
        XCTAssertTrue(
            conversationDetailsPage.guestIcon(forUserNamed: guest.name).waitForExistence(timeout: 5),
            "\(guest.name) should be shown as guest in participant list"
        )
    }

    @MainActor
    func testBlockAndUnblockUser_TC_8868() async throws {
        let userA = try await UserHelper.default.createPersonalUser()
        let userB = try await UserHelper.default.createPersonalUser()
        let messageFromUserB = "Hello from \(userB.name)"

        // userA sends a connection request to userB
        let userDetailsPage = try app.loginUser(email: userA.email, password: userA.password)
            .acceptPopup()
            .tapPlusButtonToCreateGroup()
            .tapSearchBox()
            .searchUserByUserHandle(userB.username)
            .tapSearchedUserCell()

        _ = try userDetailsPage.sendConnectionRequest()
            .closeProfilePage()
            .closeNewConversationPage()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        // userB logs in, accepts and replies
        var conversationsPage = try app.loginUser(email: userB.email, password: userB.password)
            .acceptPopup()
            .openPendingRequest()
            .acceptConnectionRequest()
            .sendMessage(messageFromUserB)
            .goBackToConversationPage()

        // switch back to userA
        conversationsPage = try conversationsPage.openUserProfilePage()
            .switchUserAccountForUser(withName: userA.name)

        // WHEN userA blocks userB
        try conversationsPage
            .longPressForMoreOptionOnConversation()
            .blockUser()

        // THEN the conversation for userB stays in the list with a "Blocked" status
        let blockedCell = conversationsPage.conversationCell(named: userB.name)
        XCTAssertTrue(
            blockedCell.waitForExistence(timeout: 5),
            "Blocked user conversation cell is missing from the list"
        )
        let blockedValue = try XCTUnwrap(blockedCell.value as? String, "Conversation cell has no accessibility value")
        XCTAssertTrue(
            blockedValue.contains("Blocked"),
            "Conversation cell should show 'Blocked' status, was: \(blockedValue)"
        )

        // WHEN userA unblocks userB via long-press on the conversation item
        try conversationsPage
            .longPressForMoreOptionOnConversation()
            .unblockUser()

        // THEN userB is still in the conversation list
        let unblockedCell = conversationsPage.conversationCell(named: userB.name)
        XCTAssertTrue(
            unblockedCell.waitForExistence(timeout: 5),
            "Unblocked user conversation cell is missing from the list"
        )
    }

    @MainActor
    func testLeaveAndClearGroup_TC_10525() async throws {
        // GIVEN
        let (_, members, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 2,
            conversation: .group("Test")
        )
        let activeConversationPage = try app.loginUser(email: members[0].email, password: members[0].password)
            .acceptPopup()
            .openConversation()
            // WHEN
            .sendMessage("test")
            .openConversationDetails()
            .moreOptionsConversationDetails()
            .leaveOptionsConversationDetails()
            .leaveAndClearConversation()
            .closeConversationDetails()

        // THEN
        let userMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertEqual(userMessages.count, 0)

        XCTAssertFalse(activeConversationPage.userLeftSystemMessage.exists, "the system message has not been removed")
    }

}

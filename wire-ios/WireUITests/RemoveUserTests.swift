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

/// [core-messenger]
class RemoveUserTests: WireUITestCase {

    /// Test when a team member is removed, the 1:1 with the user is marked as readonly on the conversation list
    /// [critical]
    @MainActor
    func testRemoveTeamMemberAndConversationListUpdated_TC_9491() async throws {
        try await testRemoveTeamMember(testRemovalOnConversation: false)
    }

    /// [critical]
    @MainActor
    func testUserDeletedForPersonalUser_TC_9490() async throws {
        // GIVEN
        let member1 = try await UserHelper.default.createPersonalUser()
        let member2 = try await UserHelper.default.createPersonalUser()

        _ = try skipUiLogin(user: member2)
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        try await loginToBackend(user: member1)
            .tapPlusButtonToCreateGroup()
            .searchUserByUserHandle(member2.name)
            .tapSearchedUserCell(handle: member2.username)
            .tapConnect()
            .closeProfilePage()
            .closeNewConversationPage()

        // here we logout member2 to avoid receiving event in other session ->
        // TODO: [WPB-23949] avoid logout once crash is resolved
        try ConversationsPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: member2.name)
            .openPendingRequest()
            .acceptConnectionRequest()
            .goBackToConversationPage()
            .openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(member2.password, expectWelcomePage: false)

        let member2ConversationsPage = try ConversationsPage()
        let oneOnOneConversation = try member2ConversationsPage
            .openConversation()
            .sendMessage("test")

        // WHEN
        try await deleteMember(member2)

        // THEN

        XCTAssertTrue(oneOnOneConversation.inputMessageField.waitToDisappear(), "conversation should be readonly")
        XCTAssertTrue(
            oneOnOneConversation.userRemovedSystemMessage.waitForExistence(timeout: 1),
            "system message should be inserted"
        )
    }

    /// Test when a team member is removed, the 1:1 with the user is marked as readonly on an active conversation
    @MainActor
    func disabled_testRemoveTeamMemberAndActiveConversationUpdated() async throws {
        // TODO: [WPB-18909] restore test
        try await testRemoveTeamMember(testRemovalOnConversation: true)
    }

    @MainActor
    private func testRemoveTeamMember(testRemovalOnConversation: Bool) async throws {
        // GIVEN
        let team = try await UserHelper.default.registerTeam(withMemberCount: 2)
        let member1 = try XCTUnwrap(team.teamMembers.first)
        let member2 = try XCTUnwrap(team.teamMembers.last)

        _ = try skipUiLogin(user: member2)
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        let member1UserProfilePage = try await loginToBackend(user: member1)
            .tapPlusButtonToCreateGroup()
            .searchUserByUserHandle(member2.name)
            .tapSearchedUserCell(handle: member2.username)
            .tapStartConversationButton()
            .goBackToConversationPage()
            .openUserProfilePage()

        // here we logout member2 to avoid receiving event in other session ->
        // TODO: [WPB-23949] avoid logout once crash is resolved
        try member1UserProfilePage
            .switchUserAccountForUser(withName: member2.name)
            .openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(member2.password, expectWelcomePage: false)

        let member2ConversationsPage = try ConversationsPage()
        let oneOnOneConversation = try member2ConversationsPage
            .openConversation()
            .sendMessage("test")

        if !testRemovalOnConversation {
            try oneOnOneConversation.goBackToConversationPage()
        }

        // WHEN
        try await deleteMember(member2)

        // THEN
        if !testRemovalOnConversation {
            try member2ConversationsPage.openConversation()
        }

        XCTAssertTrue(oneOnOneConversation.inputMessageField.waitToDisappear(), "conversation should be readonly")
        XCTAssertTrue(
            oneOnOneConversation.userRemovedSystemMessage.waitForExistence(timeout: 1),
            "system message should be inserted"
        )
    }

    private func deleteMember(_ user: UserInfo) async throws {
        try await UserHelper.default.deleteUser(user)
    }
}

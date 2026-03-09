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

class RemoveUserTests: WireUITestCase {

    @MainActor
    private func login(_ user: UserInfo) async throws -> ConversationsPage {
        print("login: email \(user.email) and password \(user.password)")
        return try app.loginUser(email: user.email, password: user.password)
            .acceptPopup(with: self)
    }

    private func deleteMember(_ user: UserInfo) async throws {
        try await userHelper.deleteUser(user)
    }

    
    /// Test when a team member is removed, the 1:1 with the user is marked as readonly on an active conversation
    @MainActor
    func testRemoveTeamMemberAndActiveConversationUpdated() async throws {
        // TODO: [WPB-18909] restore test
        try await testRemoveTeamMember(testRemovalOnConversation: true)
    }

    /// Test when a team member is removed, the 1:1 with the user is marked as readonly on the conversation list
    @MainActor
    func testRemoveTeamMemberAndConversationListUpdated() async throws {
        try await testRemoveTeamMember(testRemovalOnConversation: false)
    }

    @MainActor
        func testRemoveTeamMember(testRemovalOnConversation: Bool) async throws {
        // GIVEN
        let team = try await userHelper.registerTeam(withMemberCount: 2)
        let member1 = try XCTUnwrap(team.teamMembers.first)
        let member2 = try XCTUnwrap(team.teamMembers.last)

        _ = try await login(member2)
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        let member1UserProfilePage = try await login(member1)
            .tapPlusButtonToCreateGroup()
            .searchUserByUserHandle(member2.name)
            .tapSearchedUserCell(handle: member2.username)
            .tapStartConversationButton()
            .goBackToConversationPage()
            .openUserProfilePage()

        // FIXME: logout member2 to avoid receiving event in other session -> crash
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
        XCTAssertTrue(oneOnOneConversation.userRemovedSystemMessage.waitForExistence(timeout: 1), "system message should be inserted")
    }
}

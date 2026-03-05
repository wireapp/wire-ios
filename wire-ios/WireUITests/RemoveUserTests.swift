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
        let page = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup(with: self)
            
        return page
    }
    
    private func deleteMember(_ user: UserInfo) async throws {
        try await userHelper.deleteUser(user)
    }
    
    /// Test when a team member is removed, the 1:1 with the user is marked as readonly
    @MainActor
    func testRemoveTeamMember() async throws {
        // GIVEN
        let team = try await userHelper.registerTeam(withMemberCount: 2)
        let member1 = try XCTUnwrap(team.teamMembers.first)
        let member2 = try XCTUnwrap(team.teamMembers.last)
        
        _ = try await login(member2)
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        let activeConversation = try await login(member1)
            .tapPlusButtonToCreateGroup()
            .searchUserByUserHandle(member2.name)
            .tapSearchedUserCell(handle: member2.username)
            .tapStartConversationButton()
//            .sendMessage("test")
        
        // WHEN
        try await deleteMember(member2)
        
        // THEN
        XCTAssertFalse(activeConversation.inputMessageField.exists, "conversation should be readonly")
    }
}

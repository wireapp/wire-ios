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
    
    private func createTeam()  async throws -> (UserInfo, UserInfo, UserInfo) {
        let (_, teamOwner) = try await userHelper.registerUserAsTeamOwner()
        let ownerAccessToken = try await userHelper.fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )
        let teamID = try XCTUnwrap(teamOwner.teamID)
        let countOfMembers = 2

        var qualifiedIds: [QualifiedID] = []
        var teamMembers: [UserInfo] = []

        for _ in 0 ..< countOfMembers {
            let (qualifiedId, teamMember) = try await userHelper.registerUsersAsTeamMember(
                ownerAccessToken: ownerAccessToken.token,
                teamID: teamID
            )
            qualifiedIds.append(qualifiedId)
            teamMembers.append(teamMember)
        }
        return (teamOwner, teamMembers[0], teamMembers[1])
    }
    
    private func login(_ user: UserInfo) async throws -> SetUsernamePage {
        let page = try app.loginUser(email: user.email, password: user.password)
            .acceptPopupOnTeamMemberSetup(with: self)
            
        return page
    }
    
    private func deleteMember(_ user: UserInfo) async throws {
        try await userHelper.deleteUser(user)
    }
    /// Test when a team member is removed, the 1:1 with the user is marked as readonly
    @MainActor
    func testRemoveTeamMember() async throws {
        // GIVEN
        let (owner, member1, member2) = try await createTeam()
        
        let firstTimePage = try await login(member1)
        let userProfilePage = try firstTimePage
            .setUsername(member1.username)
            .tapPlusButtonToCreateGroup()
            .tapSearchBox()
            .searchUserByUserHandle(member2.username)
            .tapSearchedUserCell()
    
        
        // WHEN
//        try await deleteMember(member2)
        
        // THEN
        
    }
}

//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class TeamManageTests: WireUITestCase {

    @MainActor
    func test_Migrate_PersonalUserToTeam() async throws {
        let user = try await userManager.createPersonalUser()

        let welcomePage = try WelcomePage()

        var conversationPage = try welcomePage
            .enterEmailOrSSO(user.email)
            .enterPassword(user.password)
            .acceptFirstTimeAlert()
            .acceptPopup()

        var userAccountPage = try conversationPage.openUserAccount()

        let teamCreationStepsPage = try userAccountPage
            .tapCreateTeamButtonAndContinue()
            .tapContinue()
            .typeTeamNameAndContinue(user.teamName)
            .acceptTheConfirmationAndContinue()

        conversationPage = try teamCreationStepsPage.tapBackToWireButton()

        userAccountPage = try conversationPage.openUserAccount()

        let teamName = try XCTUnwrap(userAccountPage.getTeamName())
        XCTAssertEqual(teamName, user.teamName, "Team name didn't match expected value \(user.teamName)")
        XCTAssertTrue(userAccountPage.manageTeamButton.exists, "Manage Team button is not visible")

        conversationPage = try userAccountPage.closeAccountPage()
        let settingsPage = try conversationPage.openSettings()

        try settingsPage.openAccountSettings()
            .logout()
            .enterPassword(user.password)
    }

    @MainActor
    func test_PersonalUser_InvitedToTeam() async throws {
        let owner = try await userManager.createPersonalUser()
        let memberUser = UserGenerator.generateUniqueUserInfo()
        let teamID = try await BackendClient.upgradePersonalToTeam(
            email: owner.email,
            password: owner.password,
            teamName: owner.teamName
        )

        let invitationID = try await BackendClient.inviteUserToTeam(
            teamID: teamID,
            email: owner.email,
            password: owner.password,
            memberName: memberUser.name,
            memberEmail: memberUser.email
        )
        let code = try await BackendClient.getInvitationCode(team: teamID, invitationID: invitationID)
        try await BackendClient.registerTeamMember(memberUser, invitationCode: code)

        let welcomePage = try WelcomePage()

        let loginPage = try welcomePage
            .enterEmailOrSSO(memberUser.email)

        let userAccountPage = try loginPage.enterPassword(memberUser.password)
            .acceptFirstTimeAlert()
            .acceptPopupOnTeamMemberSetup()
            .setUsername(memberUser.username)
            .openUserAccount()

        let teamName = try XCTUnwrap(userAccountPage.getTeamName())
        XCTAssertEqual(teamName, owner.teamName, "Team name didn't match expected value \(owner.teamName)")

        let conversationPage = try userAccountPage.closeAccountPage()
        _ = try conversationPage.openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(memberUser.password)
    }

    @MainActor
    func test_TeamOwner_GroupConversation() async throws {

        let teamOwner = try await userManager.registerUserAsTeamOwner()
        var teamMember1 = UserGenerator.generateUniqueUserInfo()
        var teamMember2 = UserGenerator.generateUniqueUserInfo()

        let invitationID1 = try await userManager
            .getInvitationIdToAddMemberInTeam(
                email: teamOwner.email,
                password: teamOwner.password,
                teamID: teamOwner.teamID!,
                memberEmail: teamMember1.email,
                memberName: teamMember1.name
            )

        let invitationCodeFormember1 = try await userManager.getInvitationCodeToAddMemberInTeam(
            teamID: teamOwner.teamID!,
            invitationID: invitationID1
        )

        let invitationID2 = try await userManager
            .getInvitationIdToAddMemberInTeam(
                email: teamOwner.email,
                password: teamOwner.password,
                teamID: teamOwner.teamID!,
                memberEmail: teamMember2.email,
                memberName: teamMember2.name
            )

        let invitationCodeFormember2 = try await userManager.getInvitationCodeToAddMemberInTeam(
            teamID: teamOwner.teamID!,
            invitationID: invitationID2
        )

        try await userManager.registerUserAsTeamMember(
            teamMember: teamMember1,
            invitationCode: invitationCodeFormember1
        )

        try await userManager.registerUserAsTeamMember(
            teamMember: teamMember2,
            invitationCode: invitationCodeFormember2
        )
    }
}

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
        let user = try await userHelper.createPersonalUser()

        let firstTimePage = try app.loginUser(email: user.email, password: user.password)
        var userAccountPage = try  firstTimePage.acceptPopup()
            .openUserAccountPageForUser(with: user.name)

        var conversationPage = try userAccountPage
            .tapCreateTeamButtonAndContinue()
            .tapContinue()
            .typeTeamNameAndContinue(user.teamName)
            .acceptTheConfirmationAndContinue()
            .tapBackToWireButton()

        userAccountPage = try conversationPage.openUserAccountPageForUser(with: user.name)

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
        let owner = try await userHelper.createPersonalUser()
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

        let firstTimePage = try app.loginUser(email: memberUser.email, password: memberUser.password)
        let userAccountPage = try firstTimePage.acceptPopupOnTeamMemberSetup()
            .setUsername(memberUser.username)
            .openUserAccountPageForUser(with: memberUser.username)

        let teamName = try XCTUnwrap(userAccountPage.getTeamName())
        XCTAssertEqual(teamName, owner.teamName, "Team name didn't match expected value \(owner.teamName)")

        let conversationPage = try userAccountPage.closeAccountPage()
        _ = try conversationPage.openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(memberUser.password)
    }

    @MainActor
    func test_TeamOwner_GroupCreatedAndSendMessage() async throws {

        let groupName = UserGenerator.generateRandomGroupName()
        let messageFromOwner = UserGenerator.generateRandomMessage()

        let teamOwner = try await userHelper.registerUserAsTeamOwner()
        let teamMember1 = UserGenerator.generateUniqueUserInfo()
        let teamMember2 = UserGenerator.generateUniqueUserInfo()

        let accessToken = try await userHelper.fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )

        let teamMember1Id = try await userHelper.registerUsersAsTeamMember(
            accessToken: accessToken,
            teamID: teamOwner.teamID!,
            member: teamMember1
        )

        let teamMember2Id = try await userHelper.registerUsersAsTeamMember(
            accessToken: accessToken,
            teamID: teamOwner.teamID!,
            member: teamMember2
        )

        let firstTimePage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
        let conversationPage = try firstTimePage.acceptPopupOnTeamMemberSetup()
            .setUsername(teamOwner.username)

        let groupConversationPage = try conversationPage.tapPlusButtonToCreateGroup()
            .tapNewGroupButton()
            .enterGroupName(groupName)
            .tapMemberCells(withLabelPrefixes: [teamMember1.name, teamMember2.name])
            .doneSelectingMembers()
            .sendMessage(input: messageFromOwner)

        let senderName = try XCTUnwrap(groupConversationPage.getSenderName())
        XCTAssertEqual(senderName, teamOwner.name, "Sender info didn't match expected value \(teamOwner.name)")

        let sentMessages = try XCTUnwrap(groupConversationPage.getSentMessages())
        XCTAssertTrue(
            sentMessages.contains(messageFromOwner),
            "Expected message '\(messageFromOwner)' not found in sent messages: \(sentMessages)"
        )
    }
}

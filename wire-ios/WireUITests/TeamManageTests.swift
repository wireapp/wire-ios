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

final class TeamManageTests: WireUITestCase {

    @MainActor
    func testCritical_Migrate_PersonalUserToTeam() async throws {
        let user = try await userHelper.createPersonalUser()

        let conversationPage = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup(with: self)
            .openUserAccountPageForUser(with: user.name)
            .tapCreateTeamButton()
            .tapContinue()
            .typeTeamNameAndContinue(user.teamName)
            .acceptTheConfirmationAndContinue()
            .tapBackToWireButton()

        let userProfilePage = try conversationPage.openUserAccountPageForUser(with: user.name)

        let teamName = try XCTUnwrap(userProfilePage.getTeamName())
        XCTAssertEqual(teamName, user.teamName, "Team name didn't match expected value \(user.teamName)")
        XCTAssertTrue(userProfilePage.manageTeamButton.exists, "Manage Team button is not visible")
    }

    @MainActor
    func testCritical_PersonalUser_InvitedToTeam() async throws {
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
        let userProfilePage = try firstTimePage.acceptPopupOnTeamMemberSetup(with: self)
            .setUsername(memberUser.username)
            .openUserAccountPageForUser(with: memberUser.username)

        let teamName = try XCTUnwrap(userProfilePage.getTeamName())
        XCTAssertEqual(teamName, owner.teamName, "Team name didn't match expected value \(owner.teamName)")

        let conversationPage = try userProfilePage.closeAccountPage()
        _ = try conversationPage.openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(memberUser.password)
    }

    @MainActor
    func testCritical_TeamOwner_GroupCreatedAndSendMessage() async throws {

        let groupName = UserGenerator.generateRandomGroupName()
        let messageFromOwner = UserGenerator.generateRandomMessage()

        let (_, teamOwner) = try await userHelper.registerUserAsTeamOwner()

        let teamID = try XCTUnwrap(teamOwner.teamID)
        let ownerAccessToken = try await userHelper.fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )

        let (_, teamMember1) = try await userHelper.registerUsersAsTeamMember(
            ownerAccessToken: ownerAccessToken.token,
            teamID: teamID,
        )

        let (_, teamMember2) = try await userHelper.registerUsersAsTeamMember(
            ownerAccessToken: ownerAccessToken.token,
            teamID: teamID,
        )

        let activeConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup(with: self)
            .tapPlusButtonToCreateGroup()
            .tapNewGroupButton()
            .enterGroupName(groupName)
            .tapMemberCells(withLabelPrefixes: [teamMember1.name, teamMember2.name])
            .doneSelectingMembers()
            .sendMessage(messageFromOwner)

        let senderName = try XCTUnwrap(activeConversationPage.getSenderName())
        XCTAssertEqual(senderName, teamOwner.name, "Sender info didn't match expected value \(teamOwner.name)")

        let sentMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertTrue(
            sentMessages.contains(messageFromOwner),
            "Expected message '\(messageFromOwner)' not found in sent messages: \(sentMessages)"
        )
    }

    @MainActor
    func testCritical_GroupAdmin_RemoveAndAddParticipantFromGroup() async throws {

        let groupName = UserGenerator.generateRandomGroupName()
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

        try await userHelper.createGroupConversations(
            qualifiedIds: qualifiedIds,
            owner: teamOwner,
            groupName: groupName
        )

        let conversationDetailsPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup(with: self)
            .openConversation()
            .openConversationDetails()
            .openUserDetailsPage(byName: teamMembers[0].name)
            .removeParticipantFromConversation()

        XCTAssertFalse(
            conversationDetailsPage.userCells
                .matching(NSPredicate(format: "label == %@", teamMembers[0].name))
                .firstMatch
                .exists,
            "User \(teamMembers[0].name) is still present in group"
        )

        _ = try conversationDetailsPage.appParticipantToConversation()
            .tapMemberCells(withLabelPrefixes: [teamMembers[0].name])
            .addSelectedParticipant()

        XCTAssertTrue(
            conversationDetailsPage.userCells
                .matching(NSPredicate(format: "label == %@", teamMembers[0].name))
                .firstMatch
                .waitForExistence(timeout: 5),
            "User \(teamMembers[0].name) is not present in group"
        )
    }
}

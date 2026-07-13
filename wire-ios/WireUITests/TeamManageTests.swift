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
final class TeamManageTests: WireUITestCase {

    /// [critical]
    @MainActor
    func testMigratePersonalUserToTeam_TC_9452() async throws {
        let user = try await UserHelper.default.createPersonalUser()

        let conversationPage = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openUserProfilePage()
            .tapCreateTeamButton()
            .tapContinue()
            .typeTeamNameAndContinue(user.teamName)
            .acceptTheConfirmationAndContinue()
            .tapBackToWireButton()

        let userProfilePage = try conversationPage.openUserProfilePage()

        let teamName = try XCTUnwrap(userProfilePage.getTeamName())
        XCTAssertEqual(teamName, user.teamName, "Team name didn't match expected value \(user.teamName)")
        XCTAssertTrue(userProfilePage.manageTeamButton.exists, "Manage Team button is not visible")
    }

    /// [critical]
    @MainActor
    func testPersonalUserInvitedToTeam_TC_9453() async throws {
        let teamOwner = try await UserHelper.default.createPersonalUser()
        let teamID = try await UserHelper.default.upgradePersonalToTeam(
            teamName: teamOwner.teamName
        )

        let ownerAccessToken = try await UserHelper.default.fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )

        let (_, memberUser) = try await UserHelper.default.registerUsersAsTeamMember(
            ownerAccessToken: ownerAccessToken.token,
            teamID: teamID
        )

        let firstTimePage = try app.loginUser(email: memberUser.email, password: memberUser.password)
        let userProfilePage = try firstTimePage.acceptPopupOnTeamMemberSetup()
            .setUsername(memberUser.username)
            .openUserProfilePage()

        let teamName = try XCTUnwrap(userProfilePage.getTeamName())
        XCTAssertEqual(teamName, teamOwner.teamName, "Team name didn't match expected value \(teamOwner.teamName)")

        let conversationPage = try userProfilePage.closeAccountPage()
        _ = try conversationPage.openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(memberUser.password)
    }

    /// [critical]
    @MainActor
    func testTeamOwnerGroupCreatedAndSendMessage_TC_9454() async throws {

        let groupName = UserGenerator.generateRandomConversationName()
        let messageFromOwner = UserGenerator.generateRandomMessage()

        let (_, teamOwner) = try await UserHelper.default.registerUserAsTeamOwner()

        let teamMemberNames = try await UserHelper.default.registerTeamWith2Members(teamOwner: teamOwner)

        let activeConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .tapPlusButtonToCreateGroup()
            .tapNewGroupButton()
            .enterGroupName(groupName)
            .tapMemberCells(withLabelPrefixes: teamMemberNames)
            .doneSelectingMembers()
            .sendMessage(messageFromOwner)

        let senderName = try XCTUnwrap(activeConversationPage.getSenderName())
        XCTAssertEqual(senderName, teamOwner.name, "Sender info didn't match expected value \(teamOwner.name)")

        let sentMessages = activeConversationPage.fetchMessages()
        XCTAssertTrue(
            sentMessages.contains(messageFromOwner),
            "Expected message '\(messageFromOwner)' not found in sent messages: \(sentMessages)"
        )
    }

    /// [critical]
    @MainActor
    func testGroupAdminRemoveAndAddParticipantFromGroup_TC_9455() async throws {

        let groupName = UserGenerator.generateRandomConversationName()
        let (_, teamOwner) = try await UserHelper.default.registerUserAsTeamOwner()
        let ownerAccessToken = try await UserHelper.default.fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )
        let teamID = try XCTUnwrap(teamOwner.teamID)
        let countOfMembers = 2

        var qualifiedIds: [QualifiedID] = []
        var teamMembers: [UserInfo] = []

        for _ in 0 ..< countOfMembers {
            let (qualifiedId, teamMember) = try await UserHelper.default.registerUsersAsTeamMember(
                ownerAccessToken: ownerAccessToken.token,
                teamID: teamID
            )
            qualifiedIds.append(qualifiedId)
            teamMembers.append(teamMember)
        }

        try await UserHelper.default.createGroupConversations(
            qualifiedIds: qualifiedIds,
            owner: teamOwner,
            groupName: groupName
        )

        let conversationDetailsPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
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

    /// [WPB-3772] Bug: Opening an archived conversation unarchives it
    @MainActor
    func testArchivedConversationUnarchivesWhenOpened_TC_8872() async throws {
        let groupName = UserGenerator.generateRandomConversationName()

        let (teamOwner, _, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .group(groupName)
        )

        let archivedConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .openConversation()
            .openConversationDetails()
            .moreOptionsConversationDetails()
            .archiveOptionsConversationDetails()
            .openArchived()
            .openConversation()
            .goBackToConversationPage()
            .openArchived()

        XCTAssertTrue(archivedConversationPage.conversationExists(withName: groupName))
    }

    @MainActor
    func testUnarchiveConversation_TC_8873() async throws {
        let groupName = UserGenerator.generateRandomConversationName()

        let (teamOwner, _, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .group(groupName)
        )

        let archivedConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .openConversation()
            .openConversationDetails()
            .moreOptionsConversationDetails()
            .archiveOptionsConversationDetails()
            .openArchived()

        XCTAssertTrue(
            archivedConversationPage.conversationExists(withName: groupName),
            "Group \(groupName) should be in the archived list after archiving"
        )

        let conversationsPage = try archivedConversationPage
            .openConversation()
            .openConversationDetails()
            .moreOptionsConversationDetails()
            .unarchiveOptionsConversationDetails()

        XCTAssertTrue(
            conversationsPage.conversationCell(named: groupName).waitForExistence(timeout: 5),
            "Group \(groupName) should be back in the recent conversation list after unarchiving"
        )

        XCTAssertFalse(
            try conversationsPage.openArchived().conversationExists(withName: groupName),
            "Group \(groupName) should no longer be in the archived list after unarchiving"
        )
    }

    /// [critical]
    @MainActor
    func testMentionUserInGroup_TC_8865() async throws {

        let (teamOwner, teamMembers, _, _) = try await UserHelper.default
            .registerTeam(
                withMemberCount: 4,
                conversation: .group(UserGenerator.generateRandomConversationName())
            )

        _ = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        let conversationPage = try app.loginUser(email: teamMembers[1].email, password: teamMembers[1].password)
            .acceptPopup()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: teamOwner.name)
            .openConversation()
            .mentionUserAndSendMessage(nameOfUser: teamMembers[1].name)
            .goBackToConversationPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: teamMembers[1].name)

        XCTAssertEqual(
            conversationPage.mentionStatus.value as? String,
            "You are mentioned",
            "'@' value not found in conversation cell"
        )

        let activeConversationPage = try conversationPage.openConversation()

        let fetchMessages = activeConversationPage.fetchMessages()
        XCTAssertTrue(
            fetchMessages.contains(where: { $0.contains("@") && $0.contains(teamMembers[1].name) }),
            "Expected mention '@\(teamMembers[1].name)' not found in sent messages: \(fetchMessages)"
        )
    }
}

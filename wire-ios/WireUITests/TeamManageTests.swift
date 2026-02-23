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
    func test_Migrate_PersonalUserToTeam() async throws {
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
    func test_TeamOwner_GroupCreatedAndSendMessage() async throws {

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
    func test_GroupAdmin_RemoveAndAddParticipantFromGroup() async throws {

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

    @MainActor
    func test_TeamOwner_VerifyMessagesAndFileSentByMembersInGroup() async throws {
        let groupName = UserGenerator.generateRandomGroupName()
        let messageFromMember1 = UserGenerator.generateRandomMessage()

        let (_, teamOwner) = try await userHelper.registerUserAsTeamOwner()
        let ownerAccessToken = try await userHelper.fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )
        let teamID = try XCTUnwrap(teamOwner.teamID)
        let countOfMembers = 3

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

        let conversationsPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup(with: self)

        let (convoId, domain) = try await userHelper.getConversationId(matching: .groupName(groupName))
        let convoUUID = try XCTUnwrap(convoId)
        let convoDomain = try XCTUnwrap(domain)

        // member1 send text
        try await testServicesClient.sendText(
            user: teamMembers[0],
            text: messageFromMember1,
            convoId: convoUUID,
            domain: convoDomain
        )

        func getFileInfo(from path: String) -> (name: String, ext: String) {
            let url = URL(fileURLWithPath: path)
            return (url.deletingPathExtension().lastPathComponent, url.pathExtension)
        }

        let basePath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("TestServicesData")

//        let imagePath = basePath.appendingPathComponent("Img/testImage.jpg").path
//        let audioPath = basePath.appendingPathComponent("Audio/testAudio.m4a").path

//        let (imageName, imageExtension) = getFileInfo(from: imagePath)
//        let (audioName, audioExtension) = getFileInfo(from: audioPath)

        // member2 send image
//        try await testServicesClient.sendFile(
//            type: imageExtension,
//            user: teamMembers[1],
//            fileName: imageName,
//            filepath: imagePath,
//            convoId: convoUUID,
//            domain: convoDomain
//        )

        // member3 send audio
//        try await testServicesClient.sendFile(
//            type: audioExtension,
//            user: teamMembers[2],
//            fileName: audioName,
//            filepath: audioPath,
//            convoId: convoUUID,
//            domain: convoDomain
//        )

        let fetchedGroupName = try XCTUnwrap(conversationsPage.getGroupName())
        XCTAssertEqual(
            fetchedGroupName,
            groupName,
            "Group name \(fetchedGroupName) didn't match expected value \(groupName)"
        )

        XCTAssertTrue(
            try conversationsPage.waitUntilLastMessageReceivedByTestService(with: teamMembers[2].name),
            "Last message not received within 5 seconds by \(teamMembers[2].name)"
        )

        let activeConversationPage = try conversationsPage.openConversation()
        let fetchMessages = activeConversationPage.fetchMessages()
        let fetchFileNames = activeConversationPage.fetchFileNames()
        let fetchSenders = activeConversationPage.fetchSenders()

//        XCTAssertTrue(
//            fetchFileNames[0].contains(audioName.uppercased()) && fetchSenders[0].contains(teamMembers[2].name),
//            "Either expected message '\(audioName)' not found or not sent by \(teamMembers[2].name)"
//        )
//
//        XCTAssertTrue(
//            fetchFileNames[1].contains(imageName.uppercased()) &&
//                fetchSenders[1].contains(teamMembers[1].name),
//            "Either expected message '\(imageName)' not found or not sent by \(teamMembers[1].name)"
//        )
//
//        XCTAssertTrue(
//            fetchMessages[0].contains(messageFromMember1) &&
//                fetchSenders[2].contains(teamMembers[0].name),
//            "Expected message '\(messageFromMember1)' not found in sent messages: \(fetchMessages)"
//        )
    }
}

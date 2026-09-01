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
final class ChannelMessagingTests: WireUITestCase {

    private typealias ReturnedTeam = (
        teamOwner: UserInfo,
        teamMember: UserInfo,
        conversationId: UUID,
        conversationDomain: String
    )

    @MainActor
    private func registerTeamWithChannelConversation() async throws -> ReturnedTeam {
        let channelName = UserGenerator.generateRandomConversationName()
        let (teamOwner, teamMembers, _, conversationID) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .channel(channelName)
        )

        return (
            teamOwner,
            teamMembers[0],
            try XCTUnwrap(conversationID, "conversationId is nil"),
            UserHelper.default.backend.domainInfo
        )
    }

    @MainActor
    private func login(user: UserInfo) throws -> ConversationsPage {
        try app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
    }

    @MainActor
    private func addTeamMemberToChannel(
        _ teamWithChannelConversation: ReturnedTeam
    ) throws -> ActiveConversationPage {
        try ConversationsPage()
            .openConversation()
            .openConversationDetails()
            .appParticipantToConversation()
            .tapMemberCells(withLabelPrefixes: [teamWithChannelConversation.teamMember.name])
            .addSelectedParticipant()
            .closeConversationDetails()
    }

    /// [critical]
    @MainActor
    func testSendTextImageAudioAndPingInChannelConversation_TC_8847_8848_8849_8852() async throws {

        // GIVEN
        let message = UserGenerator.generateRandomMessage()
        let teamWithChannelConversation = try await registerTeamWithChannelConversation()

        // WHEN
        let activeConversationPage = try await login(user: teamWithChannelConversation.teamOwner)
            .openConversation()
            .openPhotosAndGrantPermission()
            .selectImageAndSend()
            .recordAudioAndSend()
            .sendMessage(message)
            .sendPing()

        // THEN

        let sentMessages = activeConversationPage.fetchMessages()

        XCTAssertTrue(
            activeConversationPage.imageCell.waitForExistence(timeout: 2),
            "No Image cell found"
        )

        XCTAssertTrue(
            activeConversationPage.playAudioFile.waitForExistence(timeout: 2),
            "No audio found"
        )

        XCTAssertTrue(
            sentMessages.contains(message),
            "Expected message '\(message)' not found in sent messages: \(sentMessages)"
        )

        try activeConversationPage.verifyPingSent()
    }

    @MainActor
    func testSendAndReceiveVideoInChannelConversation_TC_8850_8857() async throws {

        // GIVEN
        let teamWithChannelConversation = try await registerTeamWithChannelConversation()

        _ = try login(user: teamWithChannelConversation.teamOwner)
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        _ = try app.loginUser(
            email: teamWithChannelConversation.teamMember.email,
            password: teamWithChannelConversation.teamMember.password
        )
        .acceptPopup()
        .openUserProfilePage()
        .switchUserAccountForUser(withName: teamWithChannelConversation.teamOwner.name)

        let activeConversationPage = try addTeamMemberToChannel(teamWithChannelConversation)

        // WHEN
        let sentConversationPage = try activeConversationPage
            .openPhotosAndGrantPermission()
            .selectVideoAndSend(at: 2)

        // THEN - video is sent
        XCTAssertTrue(
            sentConversationPage.videoCell.waitForExistence(timeout: 2), "No Video cell found"
        )
        XCTAssertTrue(
            sentConversationPage.videoPlayButton.waitForExistence(timeout: 2), "No Video play button found"
        )

        let receivedConversationPage = try sentConversationPage
            .goBackToConversationPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: teamWithChannelConversation.teamMember.name)
            .openConversation()

        // THEN - video is received
        XCTAssertTrue(
            receivedConversationPage.videoCell.waitForExistence(timeout: 5),
            "No Video cell found after receiving"
        )
        XCTAssertTrue(
            receivedConversationPage.videoPlayButton.waitForExistence(timeout: 2),
            "No Video play button found after receiving"
        )
    }

    @MainActor
    func testReceiveImageAudioAndPingInChannelConversation_TC_8855_8856_8859() async throws {

        // GIVEN
        let teamWithChannelConversation = try await registerTeamWithChannelConversation()
        let mediaURLs = TestServiceMediaFixtures.mediaURLs(relativeTo: #filePath)

        _ = try login(user: teamWithChannelConversation.teamOwner)
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        _ = try app.loginUser(
            email: teamWithChannelConversation.teamMember.email,
            password: teamWithChannelConversation.teamMember.password
        )
        .acceptPopup()
        .openUserProfilePage()
        .switchUserAccountForUser(withName: teamWithChannelConversation.teamOwner.name)

        let activeConversationPage = try addTeamMemberToChannel(teamWithChannelConversation)

        // WHEN
        try await testServicesClient.sendImage(
            user: teamWithChannelConversation.teamMember,
            fileURL: mediaURLs.imageURL,
            type: mediaURLs.imageExtension,
            conversationId: teamWithChannelConversation.conversationId,
            domain: teamWithChannelConversation.conversationDomain
        )

        try await testServicesClient.sendFile(
            type: "audio",
            user: teamWithChannelConversation.teamMember,
            fileName: "audio-message",
            filepath: nil,
            convoId: teamWithChannelConversation.conversationId,
            domain: teamWithChannelConversation.conversationDomain,
            audio: TestServiceMediaFixtures.audioMetadata()
        )

        try await testServicesClient.sendPing(
            user: teamWithChannelConversation.teamMember,
            conversationId: teamWithChannelConversation.conversationId,
            domain: teamWithChannelConversation.conversationDomain
        )

        // THEN
        XCTAssertTrue(
            activeConversationPage.imageCell.waitForExistence(timeout: 5),
            "Expected image attachment not found"
        )
        XCTAssertTrue(
            activeConversationPage.fileTypeIcons.firstMatch.waitForExistence(timeout: 5),
            "Expected audio attachment not found"
        )

        let senderName = activeConversationPage.getSenderName()
        XCTAssertEqual(
            senderName,
            teamWithChannelConversation.teamMember.name,
            "Sender info didn't match expected value \(teamWithChannelConversation.teamMember.name)"
        )

        XCTAssertTrue(
            activeConversationPage
                .receivedPing(for: teamWithChannelConversation.teamMember.name)
                .waitForExistence(timeout: 2),
            "Expected ping message from \(teamWithChannelConversation.teamMember.name) not found"
        )
    }

    @MainActor
    func testSendAndReceiveFileInChannelConversation_TC_8851_8858() async throws {

        // GIVEN
        let teamWithChannelConversation = try await registerTeamWithChannelConversation()

        _ = try login(user: teamWithChannelConversation.teamOwner)
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        _ = try app.loginUser(
            email: teamWithChannelConversation.teamMember.email,
            password: teamWithChannelConversation.teamMember.password
        )
        .acceptPopup()
        .openUserProfilePage()
        .switchUserAccountForUser(withName: teamWithChannelConversation.teamOwner.name)

        let activeConversationPage = try addTeamMemberToChannel(teamWithChannelConversation)

        // WHEN
        activeConversationPage.uploadFile()

        // THEN - file is sent
        activeConversationPage.verifySharedFile(name: "TESTFILE", type: "PDF")

        let receivedConversationPage = try activeConversationPage
            .goBackToConversationPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: teamWithChannelConversation.teamMember.name)
            .openConversation()

        // THEN - file is received
        receivedConversationPage.verifySharedFile(name: "TESTFILE", type: "PDF")
    }

    @MainActor
    func testReceiveGIFInChannelConversation_TC_8860() async throws {

        // GIVEN
        let teamWithChannelConversation = try await registerTeamWithChannelConversation()
        let mediaURLs = TestServiceMediaFixtures.mediaURLs(relativeTo: #filePath)

        _ = try login(user: teamWithChannelConversation.teamOwner)
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        _ = try app.loginUser(
            email: teamWithChannelConversation.teamMember.email,
            password: teamWithChannelConversation.teamMember.password
        )
        .acceptPopup()
        .openUserProfilePage()
        .switchUserAccountForUser(withName: teamWithChannelConversation.teamOwner.name)

        let activeConversationPage = try addTeamMemberToChannel(teamWithChannelConversation)

        // WHEN
        try await testServicesClient.sendImage(
            user: teamWithChannelConversation.teamMember,
            fileURL: mediaURLs.gifURL,
            type: mediaURLs.gifType,
            conversationId: teamWithChannelConversation.conversationId,
            domain: teamWithChannelConversation.conversationDomain
        )

        // THEN
        activeConversationPage.verifyGIFReceived()
        let senderName = activeConversationPage.getSenderName()
        XCTAssertEqual(
            senderName,
            teamWithChannelConversation.teamMember.name,
            "Sender info didn't match expected value \(teamWithChannelConversation.teamMember.name)"
        )
    }
}

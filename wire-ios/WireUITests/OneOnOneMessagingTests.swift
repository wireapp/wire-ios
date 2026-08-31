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
final class OneOnOneMessagingTests: WireUITestCase {

    @MainActor
    private func openOneOnOneConversation() async throws
        -> (teamOwner: UserInfo, activeConversationPage: ActiveConversationPage) {
        let (teamOwner, teamMembers, _, _) = try await UserHelper.default.registerTeam(withMemberCount: 1)
        let firstTimePage = try app.loginUser(email: teamMembers[0].email, password: teamMembers[0].password)
        let activeConversationPage = try firstTimePage.acceptPopup()
            .tapPlusButtonToCreateGroup()
            .openUserDetailsInContactList()
            .tapStartConversationButton()

        return (teamOwner, activeConversationPage)
    }

    private func assertSenderName(
        on activeConversationPage: ActiveConversationPage,
        equals expectedName: String
    ) {
        let senderName = activeConversationPage.getSenderName()
        XCTAssertEqual(
            senderName,
            expectedName,
            "Sender info didn't match expected value \(expectedName)"
        )
    }

    /// [critical]
    @MainActor
    func testSendTextImageAudioAndPingInOneOnOneConversation_TC_8819_8820_8821_8824() async throws {

        // GIVEN
        let message = UserGenerator.generateRandomMessage()
        let (_, activeConversationPage) = try await openOneOnOneConversation()

        // WHEN
        let sentConversationPage = try await activeConversationPage
            .openPhotosAndGrantPermission()
            .selectImageAndSend()
            .recordAudioAndSend()
            .sendMessage(message)
            .sendPing()

        // THEN
        let sentMessages = sentConversationPage.fetchMessages()
        XCTAssertTrue(
            sentConversationPage.imageCell.waitForExistence(timeout: 2),
            "No Image cell found"
        )

        XCTAssertTrue(
            sentMessages.contains(message),
            "Expected message '\(message)' not found in sent messages: \(sentMessages)"
        )

        XCTAssertTrue(
            sentConversationPage.playAudioFile.waitForExistence(timeout: 2),
            "No audio found"
        )

        try sentConversationPage.verifyPingSent()
    }

    @MainActor
    func testSendAndReceiveVideoInOneOnOneConversation_TC_8822_8829() async throws {

        // GIVEN
        let (teamOwner, teamMembers, _, _) = try await UserHelper.default.registerTeam(withMemberCount: 1)
        let member = try XCTUnwrap(teamMembers.first)

        _ = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        let activeConversationPage = try app.loginUser(email: member.email, password: member.password)
            .acceptPopup()
            .tapPlusButtonToCreateGroup()
            .openUserDetailsInContactList()
            .tapStartConversationButton()

        // WHEN
        let sentConversationPage = try activeConversationPage
            .openPhotosAndGrantPermission()
            .selectVideoAndSend(at: 1)

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
            .switchUserAccountForUser(withName: teamOwner.name)
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
    func testReceiveTextImageAudioAndPingInOneOnOneConversation_TC_8826_8827_8828_8831() async throws {

        // GIVEN
        let message = UserGenerator.generateRandomMessage()
        let (teamOwner, activeConversationPage) = try await openOneOnOneConversation()
        let mediaURLs = TestServiceMediaFixtures.mediaURLs(relativeTo: #filePath)

        let (conversationId, domain) = try await UserHelper.default
            .getConversationId(matching: .conversationType(.group))
        let conversationDomain = try XCTUnwrap(domain, "domain is nil")

        // WHEN member sends text, image, audio and ping
        try await testServicesClient.sendText(
            user: teamOwner,
            text: message,
            conversationId: conversationId,
            domain: conversationDomain
        )

        try await testServicesClient.sendImage(
            user: teamOwner,
            fileURL: mediaURLs.imageURL,
            type: mediaURLs.imageExtension,
            conversationId: conversationId,
            domain: conversationDomain
        )

        try await testServicesClient.sendFile(
            type: "audio",
            user: teamOwner,
            fileName: "audio-message",
            filepath: nil,
            convoId: conversationId,
            domain: conversationDomain,
            audio: TestServiceMediaFixtures.audioMetadata()
        )

        try await testServicesClient.sendPing(
            user: teamOwner,
            conversationId: conversationId,
            domain: conversationDomain
        )

        // THEN
        XCTAssertTrue(
            activeConversationPage.messageLabels.firstMatch.waitForExistence(timeout: 5),
            "Expected at least one message to appear, but no message labels were found"
        )
        let receivedMessages = activeConversationPage.fetchMessages()
        XCTAssertTrue(
            receivedMessages.contains(message),
            "Expected message '\(message)' not found in received messages: \(receivedMessages)"
        )

        XCTAssertTrue(
            activeConversationPage.fileTypeIcons.element(boundBy: 1).waitForExistence(timeout: 5),
            "Expected image and audio attachments not found"
        )

        assertSenderName(on: activeConversationPage, equals: teamOwner.name)

        XCTAssertTrue(
            activeConversationPage
                .receivedPing(for: teamOwner.name)
                .waitForExistence(timeout: 2),
            "Expected ping message from \(teamOwner.name) not found"
        )
    }

    @MainActor
    func testSendAndReceiveFileInOneOnOneConversation_TC_8823_8830() async throws {

        // GIVEN
        let (teamOwner, teamMembers, _, _) = try await UserHelper.default.registerTeam(withMemberCount: 1)
        let member = try XCTUnwrap(teamMembers.first)

        _ = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        let activeConversationPage = try app.loginUser(email: member.email, password: member.password)
            .acceptPopup()
            .tapPlusButtonToCreateGroup()
            .openUserDetailsInContactList()
            .tapStartConversationButton()

        // WHEN
        activeConversationPage.uploadFile()

        // THEN - file is sent
        activeConversationPage.verifySharedFile(name: "TESTFILE", type: "PDF")

        let receivedConversationPage = try activeConversationPage
            .goBackToConversationPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: teamOwner.name)
            .openConversation()

        // THEN - file is received
        receivedConversationPage.verifySharedFile(name: "TESTFILE", type: "PDF")
    }
}

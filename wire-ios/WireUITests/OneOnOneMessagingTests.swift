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
    func testSendTextAndAudioInOneOnOneConversation_TC_8819_8821() async throws {

        // GIVEN
        let message = UserGenerator.generateRandomMessage()
        let (_, activeConversationPage) = try await openOneOnOneConversation()

        // WHEN
        try await activeConversationPage
            .sendMessage(message)
            .recordAudioAndSend()

        // THEN
        let sentMessages = activeConversationPage.fetchMessages()
        XCTAssertTrue(
            sentMessages.contains(message),
            "Expected message '\(message)' not found in sent messages: \(sentMessages)"
        )

        XCTAssertTrue(
            activeConversationPage.playAudioFile.waitForExistence(timeout: 2),
            "No audio found"
        )
    }

    @MainActor
    func testReceiveTextAndAudioInOneOnOneConversation_TC_8826_8828() async throws {

        // GIVEN
        let message = UserGenerator.generateRandomMessage()
        let (teamOwner, activeConversationPage) = try await openOneOnOneConversation()

        let (conversationId, domain) = try await UserHelper.default
            .getConversationId(matching: .conversationType(.group))
        let conversationDomain = try XCTUnwrap(domain, "domain is nil")

        // WHEN member sends text and audio file
        try await testServicesClient.sendText(
            user: teamOwner,
            text: message,
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
            activeConversationPage.fileTypeIcons.firstMatch.waitForExistence(timeout: 2),
            "Expected audio attachment not found"
        )

        assertSenderName(on: activeConversationPage, equals: teamOwner.name)
    }

    @MainActor
    func testReceiveImageAndVideoInOneOnOneConversation_TC_8827_8829() async throws {

        // GIVEN
        let (teamOwner, activeConversationPage) = try await openOneOnOneConversation()

        let (conversationId, domain) = try await UserHelper.default
            .getConversationId(matching: .conversationType(.group))
        let conversationDomain = try XCTUnwrap(domain, "domain is nil")

        let mediaURLs = TestServiceMediaFixtures.mediaURLs(relativeTo: #filePath)

        // WHEN member sends image and video files
        try await testServicesClient.sendImage(
            user: teamOwner,
            fileURL: mediaURLs.imageURL,
            type: mediaURLs.imageExtension,
            conversationId: conversationId,
            domain: conversationDomain
        )

        try await testServicesClient.sendFile(
            type: mediaURLs.videoExtension,
            user: teamOwner,
            fileName: "testVideo.mp4",
            filepath: mediaURLs.videoURL.path,
            convoId: conversationId,
            domain: conversationDomain
        )

        // THEN
        XCTAssertTrue(
            activeConversationPage.fileTypeIcons.firstMatch.waitForExistence(timeout: 5),
            "Expected image attachment not found"
        )

        assertSenderName(on: activeConversationPage, equals: teamOwner.name)

        XCTAssertTrue(
            activeConversationPage.fileAttachment(name: "TESTVIDEO", type: "MP4").waitForExistence(timeout: 5),
            "Expected MP4 video attachment not found"
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

    @MainActor
    func testSendAndReceivePingInOneOnOneConversation_TC_8824_8831() async throws {

        // GIVEN
        let (teamOwner, teamMembers, _, _) = try await UserHelper.default.registerTeam(withMemberCount: 1)
        let member = try XCTUnwrap(teamMembers.first)

        _ = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        // WHEN
        let activeConversationPage = try app.loginUser(email: member.email, password: member.password)
            .acceptPopup()
            .tapPlusButtonToCreateGroup()
            .openUserDetailsInContactList()
            .tapStartConversationButton()
            .sendPing()

        // THEN - ping is sent
        try activeConversationPage.verifyPingSent()

        let receivedConversationPage = try activeConversationPage
            .goBackToConversationPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: teamOwner.name)
            .openConversation()

        // THEN - ping is received
        XCTAssertTrue(
            receivedConversationPage
                .receivedPing(for: member.name)
                .waitForExistence(timeout: 2),
            "Expected ping message from \(member.name) not found"
        )
    }
}

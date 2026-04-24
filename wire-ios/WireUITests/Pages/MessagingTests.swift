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

final class MessagingTests: WireUITestCase {

    @MainActor
    func testSendAndReceiveTextInGroupConversation_TC_8833_8840() async throws {

        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let messageFromMember1 = UserGenerator.generateRandomMessage()

        let (teamOwner, teamMembers, _, conversationID) = try await userHelper
            .registerTeam(
                withMemberCount: 1,
                conversation: .group(groupName)
            )

        let conversationId = try XCTUnwrap(conversationID, "conversationId is nil")

        let conversationDomain = BackendContext.current.domainInfo

        let firstTimePage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
        let conversationsPage = try firstTimePage.acceptPopup()

        // WHEN member send text
        try await testServicesClient.sendText(
            user: teamMembers[0],
            text: messageFromMember1,
            conversationId: conversationId,
            domain: conversationDomain
        )

        XCTAssertTrue(
            conversationsPage.unreadMessagesCount.waitForExistence(timeout: 2),
            "Unread messages count element did not appear"
        )

        let activeConversationPage = try conversationsPage.openConversation()

        // THEN
        let receivedMessages = activeConversationPage.fetchMessages()
        XCTAssertTrue(
            receivedMessages.contains(messageFromMember1),
            "Expected message '\(messageFromMember1)' not found in sent messages: \(receivedMessages)"
        )

        let senderName = activeConversationPage.getSenderName()
        XCTAssertEqual(
            senderName,
            teamMembers[0].name,
            "Sender info didn't match expected value \(teamMembers[0].name)"
        )
    }

    @MainActor
    func testSendImageInGroupConversation_TC_8834() async throws {

        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let (_, teamMembers, _, _) = try await userHelper
            .registerTeam(
                withMemberCount: 1,
                conversation: .group(groupName)
            )

        // WHEN
        let firstTimePage = try app.loginUser(email: teamMembers[0].email, password: teamMembers[0].password)
        let activeConversationPage = try firstTimePage.acceptPopup()
            .openConversation()
            .openPhotosAndGrantPermission()
            .selectFirstImageAndSend()

        // THEN
        XCTAssertTrue(
            activeConversationPage.imageCell.waitForExistence(timeout: 2), "No Image cell found"
        )
    }

    @MainActor
    func testReceiveImageInGroupConversation_TC_8841() async throws {

        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let (teamOwner, teamMembers, _, conversationID) = try await userHelper
            .registerTeam(
                withMemberCount: 1,
                conversation: .group(groupName)
            )

        let conversationId = try XCTUnwrap(conversationID, "conversationId is nil")

        let conversationDomain = BackendContext.current.domainInfo

        let firstTimePage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
        let conversationsPage = try firstTimePage.acceptPopup()
        let imageURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestServicesData/Img/testImage.jpg")
        let imageExtension = imageURL.pathExtension

        // WHEN member send image
        try await testServicesClient.sendImage(
            user: teamMembers[0],
            fileURL: imageURL,
            type: imageExtension,
            conversationId: conversationId,
            domain: conversationDomain
        )

        XCTAssertTrue(
            conversationsPage.unreadMessagesCount.waitForExistence(timeout: 2),
            "Unread messages count element did not appear"
        )

        let activeConversationPage = try conversationsPage.openConversation()

        // THEN
        verifyMessageReceivedAndSenderInfo(
            attachment: activeConversationPage.fileTypeIcons.firstMatch,
            on: activeConversationPage,
            expectedSenderName: teamMembers[0].name,
            failureMessage: "Expected image attachment not found"
        )
    }

    @MainActor
    func testSendAndReceiveAudioInGroupConversation_TC_8835_8842() async throws {

        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let (teamOwner, teamMembers, _, conversationID) = try await userHelper
            .registerTeam(
                withMemberCount: 1,
                conversation: .group(groupName)
            )

        let conversationId = try XCTUnwrap(conversationID, "conversationId is nil")

        let conversationDomain = BackendContext.current.domainInfo

        let firstTimePage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
        let conversationsPage = try firstTimePage.acceptPopup()

        let durationInMillis = 5000
        let normalizedLoudness = (0 ..< 10).map { _ in Int.random(in: 0 ... 255) }

        // WHEN member sends audio file
        try await testServicesClient.sendFile(
            type: "audio",
            user: teamMembers[0],
            fileName: "audio-message",
            filepath: nil,
            convoId: conversationId,
            domain: conversationDomain,
            audio: [
                "durationInMillis": durationInMillis,
                "normalizedLoudness": normalizedLoudness
            ]
        )
        XCTAssertTrue(
            conversationsPage.unreadMessagesCount.waitForExistence(timeout: 2),
            "Unread messages count element did not appear"
        )

        let activeConversationPage = try conversationsPage.openConversation()

        // THEN
        verifyMessageReceivedAndSenderInfo(
            attachment: activeConversationPage.fileTypeIcons.firstMatch,
            on: activeConversationPage,
            expectedSenderName: teamMembers[0].name,
            failureMessage: "Expected file attachment not found"
        )
    }

    @MainActor
    func testSendAndReceiveVideoFileInGroupConversation_TC_8836_8843() async throws {

        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let (teamOwner, teamMembers, _, conversationID) = try await userHelper
            .registerTeam(
                withMemberCount: 1,
                conversation: .group(groupName)
            )

        let conversationId = try XCTUnwrap(conversationID, "conversationId is nil")

        let conversationDomain = BackendContext.current.domainInfo

        let firstTimePage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
        let conversationsPage = try firstTimePage.acceptPopup()

        // WHEN member sends video file
        let videoURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestServicesData/Video/testVideo.mp4")
        let videoExtension = videoURL.pathExtension

        try await testServicesClient.sendFile(
            type: videoExtension,
            user: teamMembers[0],
            fileName: "testVideo.mp4",
            filepath: videoURL.path,
            convoId: conversationId,
            domain: conversationDomain
        )
        XCTAssertTrue(
            conversationsPage.unreadMessagesCount.waitForExistence(timeout: 2),
            "Unread messages count element did not appear"
        )

        let activeConversationPage = try conversationsPage.openConversation()

        // THEN
        verifyMessageReceivedAndSenderInfo(
            attachment: activeConversationPage.fileAttachment(name: "TESTVIDEO", type: "MP4"),
            on: activeConversationPage,
            expectedSenderName: teamMembers[0].name,
            failureMessage: "Expected MP4 video attachment not found"
        )
    }

    private func verifyMessageReceivedAndSenderInfo(
        attachment: XCUIElement,
        on activeConversationPage: ActiveConversationPage,
        expectedSenderName: String,
        timeout: TimeInterval = 5,
        failureMessage: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            attachment.waitForExistence(timeout: timeout),
            "\(failureMessage) Debug: \(attachment.debugDescription)",
            file: file,
            line: line
        )

        let senderName = activeConversationPage.getSenderName()
        XCTAssertEqual(
            senderName,
            expectedSenderName,
            "Sender info didn't match expected value \(expectedSenderName)",
            file: file,
            line: line
        )
    }

    @MainActor
    func testSendImageInOneOnOneConversation_TC_8820() async throws {

        // GIVEN
        let (teamOwner, teamMembers, _, _) = try await userHelper
            .registerTeam(
                withMemberCount: 1
            )

        // WHEN
        let firstTimePage = try app.loginUser(email: teamMembers[0].email, password: teamMembers[0].password)
        let activeConversationPage = try firstTimePage.acceptPopup()
            .tapPlusButtonToCreateGroup()
            .tapSearchBox()
            .searchUserByUserHandle(teamOwner.username)
            .tapSearchedUserCell()
            .tapStartConversationButton()
            .openPhotosAndGrantPermission()
            .selectFirstImageAndSend()

        // THEN
        XCTAssertTrue(
            activeConversationPage.imageCell.waitForExistence(timeout: 2), "No Image cell found"
        )
    }

    @MainActor
    func testReceiveImageInOneOnOneConversation_TC_8827() async throws {

        // GIVEN
        let (teamOwner, teamMembers, _, _) = try await userHelper
            .registerTeam(
                withMemberCount: 1
            )

        let firstTimePage = try app.loginUser(email: teamMembers[0].email, password: teamMembers[0].password)
        let activeConversationPage = try firstTimePage.acceptPopup()
            .tapPlusButtonToCreateGroup()
            .tapSearchBox()
            .searchUserByUserHandle(teamOwner.username)
            .tapSearchedUserCell()
            .tapStartConversationButton()

        let (conversationId, domain) = try await userHelper.getConversationId(matching: .conversationType(.group))

        let conversationDomain = try XCTUnwrap(domain, "domain is nil")

        let imageURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestServicesData/Img/testImage.jpg")
        let imageExtension = imageURL.pathExtension

        // WHEN member send image
        try await testServicesClient.sendImage(
            user: teamOwner,
            fileURL: imageURL,
            type: imageExtension,
            conversationId: conversationId,
            domain: conversationDomain
        )

        // THEN
        XCTAssertTrue(
            activeConversationPage.fileTypeIcons.firstMatch.waitForExistence(timeout: 2),
            "Expected image attachment not found"
        )

        let senderName = activeConversationPage.getSenderName()
        XCTAssertEqual(
            senderName,
            teamOwner.name,
            "Sender info didn't match expected value \(teamOwner.name)"
        )
    }
}

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
    func testSendAndReceiveImageInGroupConversation_TC_8834_8841() async throws {

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
        XCTAssertTrue(
            activeConversationPage.fileTypeIcons.firstMatch.exists,
            "Expected image attachment not found"
        )

        let senderName = activeConversationPage.getSenderName()
        XCTAssertEqual(
            senderName,
            teamMembers[0].name,
            "Sender info didn't match expected value \(teamMembers[0].name)"
        )
    }
}

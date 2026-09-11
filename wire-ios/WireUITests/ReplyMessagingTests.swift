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
final class ReplyMessagingTests: WireUITestCase {

    private typealias ReturnedTeam = (
        teamOwner: UserInfo,
        teamMember: UserInfo,
        conversationId: UUID,
        conversationDomain: String
    )

    @MainActor
    private func registerGroupTeam() async throws -> ReturnedTeam {
        let groupName = UserGenerator.generateRandomConversationName()
        let (teamOwner, teamMembers, _, conversationID) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .group(groupName)
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
    func testReplyToTextAndLinkMessageInGroupConversation_TC_11820_11823() async throws {

        // GIVEN
        let originalTextMessage = UserGenerator.generateRandomMessage()
        let originalLinkMessage = "Check this out: https://github.com/wireapp/wire-ios"
        let textReply = "Reply to Text"
        let linkReply = "Reply to link"
        let groupTeam = try await registerGroupTeam()
        let conversationsPage = try login(user: groupTeam.teamOwner)

        try await testServicesClient.sendText(
            user: groupTeam.teamMember,
            text: originalTextMessage,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        try await testServicesClient.sendText(
            user: groupTeam.teamMember,
            text: originalLinkMessage,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        XCTAssertTrue(
            conversationsPage.unreadMessagesCount.waitForExistence(timeout: 4),
            "Unread messages count element did not appear"
        )
        let activeConversationPage = try conversationsPage.openConversation()

        // WHEN - reply to text message
        let textMessageElement = activeConversationPage.message(withText: originalTextMessage)
        try activeConversationPage.replyToMessage(textMessageElement, withText: textReply)

        // THEN
        activeConversationPage.verifyReplySent(
            replyText: textReply,
            quotedContentType: "text",
            quotedSenderName: groupTeam.teamMember.name
        )

        // WHEN - reply to link message
        let linkMessageElement = activeConversationPage.message(withText: originalLinkMessage)
        try activeConversationPage.replyToMessage(linkMessageElement, withText: linkReply)

        // THEN
        activeConversationPage.verifyReplySent(
            replyText: linkReply,
            quotedContentType: "text",
            quotedSenderName: groupTeam.teamMember.name
        )
    }

    @MainActor
    func testReplyToAudioAndImageMessageInGroupConversation_TC_11821_11822() async throws {

        // GIVEN
        let audioReply = UserGenerator.generateRandomMessage()
        let imageReply = UserGenerator.generateRandomMessage()
        let groupTeam = try await registerGroupTeam()
        let conversationsPage = try login(user: groupTeam.teamOwner)
        let mediaURLs = TestServiceMediaFixtures.mediaURLs(relativeTo: #filePath)

        try await testServicesClient.sendFile(
            type: "audio",
            user: groupTeam.teamMember,
            fileName: "audio-message",
            filepath: nil,
            convoId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain,
            audio: TestServiceMediaFixtures.audioMetadata()
        )

        try await testServicesClient.sendImage(
            user: groupTeam.teamMember,
            fileURL: mediaURLs.imageURL,
            type: mediaURLs.imageExtension,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        XCTAssertTrue(
            conversationsPage.unreadMessagesCount.waitForExistence(timeout: 4),
            "Unread messages count element did not appear"
        )
        let activeConversationPage = try conversationsPage.openConversation()

        XCTAssertTrue(
            activeConversationPage.playAudioFile.waitForExistence(timeout: 5),
            "Expected audio message not found"
        )
        XCTAssertTrue(
            activeConversationPage.imageCell.waitForExistence(timeout: 5),
            "Expected image message not found"
        )

        // WHEN - reply to audio message
        try activeConversationPage.replyToMessage(activeConversationPage.playAudioFile, withText: audioReply)

        // THEN
        activeConversationPage.verifyReplySent(
            replyText: audioReply,
            quotedContentType: "audio",
            quotedSenderName: groupTeam.teamMember.name
        )

        // WHEN - reply to image message
        try activeConversationPage.replyToMessage(activeConversationPage.imageCell, withText: imageReply)

        // THEN
        activeConversationPage.verifyReplySent(
            replyText: imageReply,
            quotedContentType: "image",
            quotedSenderName: groupTeam.teamMember.name
        )
    }
}

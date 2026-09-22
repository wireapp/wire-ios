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
final class ReplyOnMessageTests: WireUITestCase {

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
    func testReplyToTextAndLinkMessageInGroupConversation_TC_11820_11823() async throws {

        // GIVEN
        let originalTextMessage = UserGenerator.generateRandomMessage()
        let originalLinkMessage = "Check this out: https://github.com/wireapp/wire-ios"
        let textReply = "Reply to Text"
        let linkReply = "Reply to link"

        let groupTeam = try await registerGroupTeam()

        let activeConversationPage = try app.loginUser(
            email: groupTeam.teamOwner.email,
            password: groupTeam.teamOwner.password
        )
        .acceptPopup()
        .openConversation()

        try await testServicesClient.sendText(
            user: groupTeam.teamMember,
            text: originalTextMessage,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        // WHEN - reply to text message
        try activeConversationPage.replyToMessage(
            activeConversationPage.message(withText: originalTextMessage),
            withText: textReply
        )

        // THEN
        activeConversationPage.verifyReplySent(
            replyText: textReply,
            quotedContentType: "text",
            quotedSenderName: groupTeam.teamMember.name,
            quotedText: originalTextMessage
        )

        try await testServicesClient.sendText(
            user: groupTeam.teamMember,
            text: originalLinkMessage,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        // WHEN - reply to link message
        try activeConversationPage.replyToMessage(
            activeConversationPage.message(withText: originalLinkMessage),
            withText: linkReply
        )

        // THEN
        activeConversationPage.verifyReplySent(
            replyText: linkReply,
            quotedContentType: "text",
            quotedSenderName: groupTeam.teamMember.name,
            quotedText: originalLinkMessage
        )
    }

    @MainActor
    func testReplyToImageAndAudioMessageInGroupConversation_TC_11821_11822() async throws {

        // GIVEN
        let imageReply = "Reply to Image"
        let audioReply = "Reply to Audio"
        let imageFileName = "image"
        let audioFileName = "audio-message"
        let groupTeam = try await registerGroupTeam()
        let mediaURLs = TestServiceMediaFixtures.mediaURLs(relativeTo: #filePath)
        let activeConversationPage = try app.loginUser(
            email: groupTeam.teamOwner.email,
            password: groupTeam.teamOwner.password
        )
        .acceptPopup()
        .openConversation()

        try await testServicesClient.sendImage(
            user: groupTeam.teamMember,
            fileURL: mediaURLs.imageURL,
            type: mediaURLs.imageExtension,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        // WHEN - reply to image message
        try activeConversationPage.replyToMessage(
            activeConversationPage.receivedFileMessage(named: imageFileName),
            withText: imageReply
        )

        // THEN
        activeConversationPage.verifyReplySent(
            replyText: imageReply,
            quotedContentType: "file",
            quotedSenderName: groupTeam.teamMember.name
        )

        try await testServicesClient.sendFile(
            type: "audio",
            user: groupTeam.teamMember,
            fileName: audioFileName,
            filepath: nil,
            convoId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain,
            audio: TestServiceMediaFixtures.audioMetadata()
        )

        // WHEN - reply to audio message
        try activeConversationPage.replyToMessage(
            activeConversationPage.receivedFileMessage(named: audioFileName),
            withText: audioReply
        )

        // THEN
        activeConversationPage.verifyReplySent(
            replyText: audioReply,
            quotedContentType: "file",
            quotedSenderName: groupTeam.teamMember.name
        )
    }

    @MainActor
    func testNotAbleToReplyToPingOrSelfDeletingMessageInGroupConversation_TC_11824_11825() async throws {

        // GIVEN
        let originalTextMessage = UserGenerator.generateRandomMessage()
        let groupTeam = try await registerGroupTeam()

        let activeConversationPage = try app.loginUser(
            email: groupTeam.teamOwner.email,
            password: groupTeam.teamOwner.password
        )
        .acceptPopup()
        .openConversation()

        try await testServicesClient.sendPing(
            user: groupTeam.teamMember,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        let pingMessage = activeConversationPage.receivedPing(for: groupTeam.teamMember.name)
        XCTAssertTrue(
            pingMessage.waitForExistence(timeout: 5),
            "Expected ping message was not found, possible that not being sent via testService"
        )

        // WHEN - long-press ping message
        pingMessage.press(forDuration: 1.0)

        // THEN - no Reply option offered
        XCTAssertFalse(
            activeConversationPage.replyMenuButton.waitForExistence(timeout: 2),
            "Reply option should not be available for ping messages"
        )

        try await testServicesClient.sendText(
            user: groupTeam.teamMember,
            text: originalTextMessage,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain,
            timeoutMillis: 60_000 // messageTimer => self-deleting message
        )

        let selfDeletingMessage = activeConversationPage.message(withText: originalTextMessage)
        XCTAssertTrue(
            selfDeletingMessage.waitForExistence(timeout: 5),
            "Expected self-deleting message was not found, possible that not being sent via testService"
        )

        // WHEN - long-press self-deleting message
        selfDeletingMessage.press(forDuration: 1.0)

        // THEN - no Reply option offered
        XCTAssertFalse(
            activeConversationPage.replyMenuButton.waitForExistence(timeout: 2),
            "Reply option should not be available for self-deleting messages"
        )
    }
}

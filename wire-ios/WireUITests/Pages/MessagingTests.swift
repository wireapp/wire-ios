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
    func testSendAndReceiveTextAndAudioInGroupConversation_TC_8833_8840_8835_8842() async throws {

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

        let durationInMillis = 5000
        let normalizedLoudness = (0 ..< 10).map { _ in Int.random(in: 0 ... 255) }

        // WHEN member sends text and audio file
        try await testServicesClient.sendText(
            user: teamMembers[0],
            text: messageFromMember1,
            conversationId: conversationId,
            domain: conversationDomain
        )

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
        let receivedMessages = activeConversationPage.fetchMessages()
        XCTAssertTrue(
            receivedMessages.contains(messageFromMember1),
            "Expected message '\(messageFromMember1)' not found in sent messages: \(receivedMessages)"
        )

        verifyMessageReceivedAndSenderInfo(
            attachment: activeConversationPage.fileTypeIcons.firstMatch,
            on: activeConversationPage,
            expectedSenderName: teamMembers[0].name,
            failureMessage: "Expected audio attachment not found"
        )
    }

    @MainActor
    func testSendAndReceiveImageAndVideoInGroupConversation_TC_8834_8841_8836_8843() async throws {

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

        let videoURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestServicesData/Video/testVideo.mp4")
        let videoExtension = videoURL.pathExtension

        // WHEN member sends image and video files
        try await testServicesClient.sendImage(
            user: teamMembers[0],
            fileURL: imageURL,
            type: imageExtension,
            conversationId: conversationId,
            domain: conversationDomain
        )

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
        XCTAssertTrue(
            activeConversationPage.fileTypeIcons.firstMatch.waitForExistence(timeout: 5),
            "Expected image attachment not found"
        )

        verifyMessageReceivedAndSenderInfo(
            attachment: activeConversationPage.fileAttachment(name: "TESTVIDEO", type: "MP4"),
            on: activeConversationPage,
            expectedSenderName: teamMembers[0].name,
            failureMessage: "Expected MP4 video attachment not found"
        )
    }

    @MainActor
    func testReceivedAudioMessagePlaybackStartsOnTap_WPB_25713() async throws {

        // GIVEN a team with 2 users sharing a group conversation
        let groupName = UserGenerator.generateRandomConversationName()
        let (userA, teamMembers, _, _) = try await userHelper
            .registerTeam(
                withMemberCount: 1,
                conversation: .group(groupName)
            )
        let userB = teamMembers[0]

        // ...login user A, then add user B as a second account in the app
        _ = try app.loginUser(email: userA.email, password: userA.password)
            .acceptPopup()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        let conversationsPageAsB = try app.loginUser(email: userB.email, password: userB.password)
            .acceptPopup()

        // WHEN user B records and sends an audio message to the shared conversation via the UI
        let conversationAsB = try conversationsPageAsB.openConversation()
        conversationAsB.registerMicrophonePermissionMonitor(testCase: self)
        try conversationAsB.recordAndSendAudioMessage(recordingDuration: 3)

        // ...and user B logs out, leaving user A as the active session
        _ = try conversationAsB
            .goBackToConversationPage()
            .openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(userB.password, expectWelcomePage: false)

        let conversationsPageAsA = try ConversationsPage()

        XCTAssertTrue(
            conversationsPageAsA.unreadMessagesCount.waitForExistence(timeout: 10),
            "Unread messages count element did not appear for user A"
        )

        let conversationAsA = try conversationsPageAsA.openConversation()

        XCTAssertTrue(
            conversationAsA.audioPlayButton.waitForExistence(timeout: 5),
            "Audio play button not found"
        )

        // ...and user A taps the play button
        conversationAsA.audioPlayButton.tap()

        // THEN playback starts (button accessibility value flips from "Play" to "Pause").
        // Regression guard for WPB-25713: tapping play on a not-yet-downloaded received audio
        // must trigger the download + playback. If userSession is not propagated to
        // AudioMessageView, the download is never enqueued and the button stays on "Play".
        let pausePredicate = NSPredicate(format: "value == %@", "Pause")
        let pauseExpectation = XCTNSPredicateExpectation(
            predicate: pausePredicate,
            object: conversationAsA.audioPlayButton
        )
        do {
            try await fulfillment(of: [pauseExpectation], timeout: 5)
        } catch {
            XCTFail("Audio did not start playing after tapping play. Button value: \(conversationAsA.audioPlayButton.value ?? "nil"). Expected to become 'Pause'.")
        }
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
}

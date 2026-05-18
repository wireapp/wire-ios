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

    @MainActor
    func testSendTextAndAudioInOneOnOneConversation_TC_8819_8821() async throws {

        // GIVEN
        let message = UserGenerator.generateRandomMessage()
        let (_, activeConversationPage) = try await openOneOnOneConversation()

        // WHEN
        try activeConversationPage
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
    func testReceivedAudioMessagePlaybackStartsOnTap_TC_10871() async throws {

        // GIVEN a team with 2 users sharing a group conversation
        let groupName = UserGenerator.generateRandomConversationName()
        let (userA, teamMembers, _, _) = try await UserHelper.default
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
            XCTFail(
                "Audio did not start playing after tapping play. Button value: \(conversationAsA.audioPlayButton.value ?? "nil"). Expected to become 'Pause'."
            )
        }
    }

    
    
    @MainActor
    func testReceiveTextAndAudioInOneOnOneConversation_TC_8826_8828() async throws {

        // GIVEN
        let message = UserGenerator.generateRandomMessage()
        let (teamOwner, activeConversationPage) = try await openOneOnOneConversation()

        let (conversationId, domain) = try await UserHelper.default
            .getConversationId(matching: .conversationType(.group))
        let conversationDomain = try XCTUnwrap(domain, "domain is nil")

        let durationInMillis = 5000
        let normalizedLoudness = (0 ..< 10).map { _ in Int.random(in: 0 ... 255) }

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
            audio: [
                "durationInMillis": durationInMillis,
                "normalizedLoudness": normalizedLoudness
            ]
        )

        // THEN
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
            user: teamOwner,
            fileURL: imageURL,
            type: imageExtension,
            conversationId: conversationId,
            domain: conversationDomain
        )

        try await testServicesClient.sendFile(
            type: videoExtension,
            user: teamOwner,
            fileName: "testVideo.mp4",
            filepath: videoURL.path,
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
    func testSendPingInOneOnOneConversation_TC_8824() async throws {

        // GIVEN
        let (_, activeConversationPage) = try await openOneOnOneConversation()

        // WHEN
        try activeConversationPage.sendPing()

        // THEN
        try activeConversationPage.verifyPingSent()
    }

    @MainActor
    func testReceivePingInOneOnOneConversation_TC_8831() async throws {

        // GIVEN
        let (teamOwner, activeConversationPage) = try await openOneOnOneConversation()

        let (conversationId, domain) = try await UserHelper.default
            .getConversationId(matching: .conversationType(.group))
        let conversationDomain = try XCTUnwrap(domain, "domain is nil")

        // WHEN
        try await testServicesClient.sendPing(
            user: teamOwner,
            conversationId: conversationId,
            domain: conversationDomain
        )

        // THEN
        XCTAssertTrue(
            activeConversationPage
                .receivedPing(for: teamOwner.name)
                .waitForExistence(timeout: 2),
            "Expected ping message from \(teamOwner.name) not found"
        )
    }
}

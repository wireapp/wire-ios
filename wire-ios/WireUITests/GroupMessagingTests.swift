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

import CoreLocation
import WireFoundation
import XCTest

/// [core-messenger]
final class GroupMessagingTests: WireUITestCase {

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

    /// [critical]
    @MainActor
    func testSendTextAndAudioInGroupConversation_TC_8833_8835() async throws {

        // GIVEN
        let message = UserGenerator.generateRandomMessage()
        let groupTeam = try await registerGroupTeam()

        // WHEN
        let activeConversationPage = try await login(user: groupTeam.teamOwner)
            .openConversation()
            .sendMessage(message)
            .recordAudioAndSend()

        // THEN
        let sentMessage = activeConversationPage.fetchMessages()
        XCTAssertTrue(
            sentMessage.contains(message),
            "Expected message '\(message)' not found in sent messages: \(sentMessage)"
        )

        XCTAssertTrue(
            activeConversationPage.playAudioFile.waitForExistence(timeout: 2), "No audio found"
        )
    }

    @MainActor
    func testReceiveTextAndAudioInGroupConversation_TC_8840_8842() async throws {

        // GIVEN
        let message = UserGenerator.generateRandomMessage()
        let groupTeam = try await registerGroupTeam()
        let conversationsPage = try login(user: groupTeam.teamOwner)

        // WHEN member sends text and audio file
        try await testServicesClient.sendText(
            user: groupTeam.teamMember,
            text: message,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        try await testServicesClient.sendFile(
            type: "audio",
            user: groupTeam.teamMember,
            fileName: "audio-message",
            filepath: nil,
            convoId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain,
            audio: TestServiceMediaFixtures.audioMetadata()
        )

        XCTAssertTrue(
            conversationsPage.unreadMessagesCount.waitForExistence(timeout: 4),
            "Unread messages count element did not appear"
        )

        let activeConversationPage = try conversationsPage.openConversation()

        // THEN
        let receivedMessages = activeConversationPage.fetchMessages()
        XCTAssertTrue(
            receivedMessages.contains(message),
            "Expected message '\(message)' not found in sent messages: \(receivedMessages)"
        )

        verifyMessageReceivedAndSenderInfo(
            attachment: activeConversationPage.fileTypeIcons.firstMatch,
            on: activeConversationPage,
            expectedSenderName: groupTeam.teamMember.name,
            failureMessage: "Expected audio attachment not found"
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
        try await conversationAsB.recordAudioAndSend()

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
            conversationAsA.playAudioFile.waitForExistence(timeout: 5),
            "Audio play button not found"
        )

        // ...and user A taps the play button
        conversationAsA.playAudioFile.tap()

        // Regression guard for WPB-25713: tapping play on a not-yet-downloaded received audio
        // must trigger the download + playback. If userSession is not propagated to
        // AudioMessageView, the download is never enqueued and the button stays on "Play".
        let pausePredicate = NSPredicate(format: "value == %@", "Pause")
        let pauseExpectation = XCTNSPredicateExpectation(
            predicate: pausePredicate,
            object: conversationAsA.playAudioFile
        )
        do {
            try await fulfillment(of: [pauseExpectation], timeout: 5)
        } catch {
            XCTFail(
                "Audio did not start playing after tapping play. Button value: \(conversationAsA.playAudioFile.value ?? "nil"). Expected to become 'Pause'."
            )
        }
    }

    /// [critical]
    @MainActor
    func testSendImageAndVideoInGroupConversation_TC_8834_8836() async throws {

        // GIVEN
        let groupTeam = try await registerGroupTeam()

        // WHEN
        let activeConversationPage = try login(user: groupTeam.teamMember)
            .openConversation()
            .openPhotosAndGrantPermission()
            .selectImageAndSend()
            .openPhotos()
            .selectVideoAndSend()

        // THEN
        XCTAssertTrue(
            activeConversationPage.imageCell.waitForExistence(timeout: 2), "No Image cell found"
        )

        XCTAssertTrue(
            activeConversationPage.videoCell.waitForExistence(timeout: 2), "No Video cell found"
        )

        XCTAssertTrue(
            activeConversationPage.videoPlayButton.waitForExistence(timeout: 2), "No Video play button found"
        )
    }

    @MainActor
    func testReceiveImageAndVideoInGroupConversation_TC_8841_8843() async throws {

        // GIVEN
        let groupTeam = try await registerGroupTeam()
        let conversationsPage = try login(user: groupTeam.teamOwner)
        let mediaURLs = TestServiceMediaFixtures.mediaURLs(relativeTo: #filePath)

        // WHEN
        try await testServicesClient.sendImage(
            user: groupTeam.teamMember,
            fileURL: mediaURLs.imageURL,
            type: mediaURLs.imageExtension,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        try await testServicesClient.sendFile(
            type: mediaURLs.videoExtension,
            user: groupTeam.teamMember,
            fileName: "testVideo.mp4",
            filepath: mediaURLs.videoURL.path,
            convoId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        XCTAssertTrue(
            conversationsPage.unreadMessagesCount.waitForExistence(timeout: 5),
            "Unread messages count element did not appear"
        )

        let activeConversationPage = try conversationsPage.openConversation()

        // THEN

        // Image verification
        XCTAssertTrue(
            activeConversationPage.fileTypeIcons.firstMatch.waitForExistence(timeout: 5),
            "Expected image attachment not found"
        )

        // Video verification
        verifyMessageReceivedAndSenderInfo(
            attachment: activeConversationPage.fileAttachment(name: "TESTVIDEO", type: "MP4"),
            on: activeConversationPage,
            expectedSenderName: groupTeam.teamMember.name,
            failureMessage: "Expected MP4 video attachment not found"
        )
    }

    @MainActor
    func testSendAndReceiveFileInGroupConversation_TC_8837_8844() async throws {

        // GIVEN
        let groupTeam = try await registerGroupTeam()

        _ = try login(user: groupTeam.teamOwner)
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        // WHEN
        let activeConversationPage = try app.loginUser(
            email: groupTeam.teamMember.email,
            password: groupTeam.teamMember.password
        )
        .acceptPopup()
        .openConversation()
        .uploadFile()

        // THEN - file is sent
        activeConversationPage.verifySharedFile(name: "TESTFILE", type: "PDF")

        let receivedConversationPage = try activeConversationPage
            .goBackToConversationPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: groupTeam.teamOwner.name)
            .openConversation()

        // THEN - file is received
        receivedConversationPage.verifySharedFile(name: "TESTFILE", type: "PDF")
    }

    @MainActor
    func testSendAndReceivePingInGroupConversation_TC_8838_8845() async throws {

        // GIVEN
        let groupTeam = try await registerGroupTeam()

        _ = try login(user: groupTeam.teamOwner)
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        // WHEN
        let activeConversationPage = try app.loginUser(
            email: groupTeam.teamMember.email,
            password: groupTeam.teamMember.password
        )
        .acceptPopup()
        .openConversation()
        .sendPing()

        // THEN - ping is sent
        try activeConversationPage.verifyPingSent()

        let receivedConversationPage = try activeConversationPage
            .goBackToConversationPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: groupTeam.teamOwner.name)
            .openConversation()

        // THEN - ping is received
        XCTAssertTrue(
            receivedConversationPage
                .receivedPing(for: groupTeam.teamMember.name)
                .waitForExistence(timeout: 2),
            "Expected ping message from \(groupTeam.teamMember.name) not found"
        )
    }

    @MainActor
    func testSendLocationAndOpenReceivedLocationInDefaultMapsApp_TC_11734() async throws {

        // GIVEN
        let groupTeam = try await registerGroupTeam()
        XCUIDevice.shared.location = XCUILocation(location: CLLocation(
            latitude: 52.52419,
            longitude: 13.40221
        ))

        let activeConversationPage = try login(user: groupTeam.teamOwner)
            .openConversation()

        // WHEN
        activeConversationPage
            .selectAndSendLocation()
            .verifyLocationShared()

        try await testServicesClient.sendLocation(
            user: groupTeam.teamMember,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain,
            latitude: 52.52419,
            longitude: 13.40221,
            locationName: "Berlin"
        )

        // THEN - Verify received location and able to open
        activeConversationPage.verifyLocationShared()
        activeConversationPage.openLocationInDefaultMapsApp(locationName: "Berlin")
    }

    @MainActor
    func testUserAbleToChangeConversationNotificationSettings_TC_8871() async throws {

        // GIVEN
        let groupTeam = try await registerGroupTeam()
        let activeConversationPage = try login(user: groupTeam.teamOwner)
            .openConversation()

        // WHEN
        let notificationOptionsPage = try activeConversationPage
            .openConversationDetails()
            .openNotificationOptions()

        // THEN
        try notificationOptionsPage
            .assertSelected(.everything)
            .selectAndVerify(.mentionsAndReplies)
            .selectAndVerify(.nothing)
            .goBackToConversationDetails()
            .assertNotificationStatus(.nothing)
            .openNotificationOptions()
            .assertSelected(.nothing)
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

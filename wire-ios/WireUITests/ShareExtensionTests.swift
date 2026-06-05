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
import WireLocators
import XCTest

final class ShareExtensionTests: WireUITestCase {

    private struct ShareScenario {
        let sender: UserInfo
        let receiver: UserInfo
        let conversationName: String
        let receiverConversationName: String
        let senderConversationsPage: ConversationsPage
    }

    private let photosAppBundleId = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
    private let filesAppBundleId = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
    private let testFileName = "testFile.pdf"
    private let testVideoName = "testVideo.mp4"
    private let timeout: TimeInterval = 2
    private let attachmentTimeout: TimeInterval = 30
    private let fileUploadTimeout: TimeInterval = 90

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        executionTimeAllowance = 600
    }

    @MainActor
    private func launchPhotosApp() async throws {
        photosAppBundleId.launch()
        XCTAssertTrue(photosAppBundleId.wait(for: .runningForeground, timeout: timeout))
    }

    @MainActor
    private func launchFilesApp() async throws {
        filesAppBundleId.terminate()
        filesAppBundleId.launch()
        XCTAssertTrue(filesAppBundleId.wait(for: .runningForeground, timeout: timeout))
    }

    @MainActor
    private func shareFirstPhotoToWire(conversationName: String, accountName: String) async throws {
        try await launchPhotosApp()

        let photosApp = try PhotosAppPage(photosApp: photosAppBundleId)
        try photosApp
            .openFirstImage()
            .shareImageToWire()
            .chooseConversationAndSend(name: conversationName, accountName: accountName)

        try await switchBackToWireApp()
    }

    @MainActor
    private func shareFixtureFileToWire(fileName: String, conversationName: String, accountName: String) async throws {
        try await launchFilesApp()

        let filesApp = try FilesAppPage(filesApp: filesAppBundleId)
        try filesApp
            .shareFileToWire(named: fileName)
            .chooseConversationAndSend(name: conversationName, accountName: accountName)

        try await switchBackToWireApp()
    }

    @MainActor
    private func switchBackToWireApp() async throws {
        app.activate()
        if !app.wait(for: .runningForeground, timeout: timeout) {
            app.launch()
            _ = app.wait(for: .runningForeground, timeout: timeout)
        }
    }

    @MainActor
    private func setupSenderAndReceiverAccountsAndSwitchToSender(
        receiver: UserInfo,
        sender: UserInfo
    ) throws -> ConversationsPage {
        let firstTimePage = try app.loginUser(email: sender.email, password: sender.password)

        _ = try firstTimePage.acceptPopup()
            .tapPlusButtonToCreateGroup()
            .openUserDetailsInContactList()
            .tapStartConversationButton()
            .goBackToConversationPage()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        let receiverConversationsPage = try app.loginUser(
            email: receiver.email,
            password: receiver.password
        )
        .acceptPopup()

        try receiverConversationsPage.letTheSyncFinish()

        return try receiverConversationsPage
            .openUserProfilePage()
            .switchUserAccountForUser(withName: sender.name)
    }

    @MainActor
    private func createOneOnOneShareScenario() async throws -> ShareScenario {
        let (teamOwner, teamMembers, _, _) = try await UserHelper.default.registerTeam(withMemberCount: 1)
        let sender = try XCTUnwrap(teamMembers.first)
        let receiver = teamOwner

        let senderConversationsPage = try setupSenderAndReceiverAccountsAndSwitchToSender(
            receiver: receiver,
            sender: sender
        )

        XCTAssertTrue(
            senderConversationsPage.conversationCell(named: receiver.name).waitForExistence(timeout: 10),
            "Conversation '\(receiver.name)' did not show up after creating 1:1"
        )

        return ShareScenario(
            sender: sender,
            receiver: receiver,
            conversationName: receiver.name,
            receiverConversationName: sender.name,
            senderConversationsPage: senderConversationsPage
        )
    }

    @MainActor
    private func createTeamShareScenario(conversation: CreateConversationOption) async throws -> ShareScenario {
        let conversationName: String = switch conversation {
        case let .group(name), let .channel(name):
            name
        }

        let (teamOwner, teamMembers, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: conversation
        )
        let receiver = try XCTUnwrap(teamMembers.first)
        let senderConversationsPage = try setupSenderAndReceiverAccountsAndSwitchToSender(
            receiver: receiver,
            sender: teamOwner
        )

        XCTAssertTrue(
            senderConversationsPage.conversationCell(named: conversationName).waitForExistence(timeout: 10),
            "Conversation '\(conversationName)' did not show up after sender login"
        )

        return ShareScenario(
            sender: teamOwner,
            receiver: receiver,
            conversationName: conversationName,
            receiverConversationName: conversationName,
            senderConversationsPage: senderConversationsPage
        )
    }

    @MainActor
    private func openConversation(
        named conversationName: String,
        on conversationsPage: ConversationsPage
    ) throws -> ActiveConversationPage {
        try conversationsPage.letTheSyncFinish()
        let conversationCell = conversationsPage.conversationCell(named: conversationName)
        XCTAssertTrue(
            conversationCell.waitForExistence(timeout: attachmentTimeout),
            "Conversation '\(conversationName)' did not show up"
        )
        XCTAssertTrue(
            conversationCell.waitAndTap(timeout: 10),
            "Conversation '\(conversationName)' was not tappable"
        )
        return try ActiveConversationPage()
    }

    @MainActor
    private func logOutSenderAndOpenReceiverConversation(
        from activeConversationPage: ActiveConversationPage,
        sender: UserInfo,
        conversationName: String
    ) throws -> ActiveConversationPage {
        _ = try activeConversationPage
            .goBackToConversationPage()
            .openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(sender.password, expectWelcomePage: false)

        let receiverConversationsPage = try ConversationsPage()
        return try openConversation(named: conversationName, on: receiverConversationsPage)
    }

    private func assertImageShared(on activeConversationPage: ActiveConversationPage) {
        XCTAssertTrue(
            activeConversationPage.imageCell.waitForExistence(timeout: attachmentTimeout),
            "No Image cell found"
        )
    }

    private func assertVideoShared(on activeConversationPage: ActiveConversationPage) {
        XCTAssertTrue(
            activeConversationPage.videoCell.waitForExistence(timeout: attachmentTimeout),
            "No Video cell found"
        )
        XCTAssertTrue(
            activeConversationPage.videoPlayButton.waitForExistence(timeout: timeout),
            "No Video play button found"
        )
    }

    @MainActor
    func testShareImageOnetoOne_TC_8915() async throws {
        let scenario = try await createOneOnOneShareScenario()

        try await shareFirstPhotoToWire(conversationName: scenario.conversationName, accountName: scenario.sender.name)

        let activeConversationPage = try openConversation(
            named: scenario.conversationName,
            on: scenario.senderConversationsPage
        )
        assertImageShared(on: activeConversationPage)
    }

    @MainActor
    func testShareVideoToOneOnOneConversation_TC_8916() async throws {
        let scenario = try await createOneOnOneShareScenario()

        try await shareFixtureFileToWire(
            fileName: testVideoName,
            conversationName: scenario.conversationName,
            accountName: scenario.sender.name
        )

        let activeConversationPage = try openConversation(
            named: scenario.conversationName,
            on: scenario.senderConversationsPage
        )
        assertVideoShared(on: activeConversationPage)
    }

    @MainActor
    func testShareFileToOneOnOneConversation_TC_8917_8918() async throws {
        let scenario = try await createOneOnOneShareScenario()

        try await shareFixtureFileToWire(
            fileName: testFileName,
            conversationName: scenario.conversationName,
            accountName: scenario.sender.name
        )

        let activeConversationPage = try openConversation(
            named: scenario.conversationName,
            on: scenario.senderConversationsPage
        )
        .verifySharedFile(name: "TESTFILE", type: "PDF", timeout: fileUploadTimeout, requireReady: true)

        try logOutSenderAndOpenReceiverConversation(
            from: activeConversationPage,
            sender: scenario.sender,
            conversationName: scenario.receiverConversationName
        )
        .verifySharedFile(name: "TESTFILE", type: "PDF")
    }

    @MainActor
    func testShareImageToGroupConversation_TC_8919() async throws {
        let groupName = UserGenerator.generateRandomConversationName()
        let scenario = try await createTeamShareScenario(conversation: .group(groupName))

        try await shareFirstPhotoToWire(conversationName: scenario.conversationName, accountName: scenario.sender.name)

        let activeConversationPage = try openConversation(
            named: scenario.conversationName,
            on: scenario.senderConversationsPage
        )
        assertImageShared(on: activeConversationPage)
    }

    @MainActor
    func testShareVideoToGroupConversation_TC_8920() async throws {
        let groupName = UserGenerator.generateRandomConversationName()
        let scenario = try await createTeamShareScenario(conversation: .group(groupName))

        try await shareFixtureFileToWire(
            fileName: testVideoName,
            conversationName: scenario.conversationName,
            accountName: scenario.sender.name
        )

        let activeConversationPage = try openConversation(
            named: scenario.conversationName,
            on: scenario.senderConversationsPage
        )
        assertVideoShared(on: activeConversationPage)
    }

    @MainActor
    func testShareFileToGroupConversation_TC_8921_8922() async throws {
        let groupName = UserGenerator.generateRandomConversationName()
        let scenario = try await createTeamShareScenario(conversation: .group(groupName))

        try await shareFixtureFileToWire(
            fileName: testFileName,
            conversationName: scenario.conversationName,
            accountName: scenario.sender.name
        )

        let activeConversationPage = try openConversation(
            named: scenario.conversationName,
            on: scenario.senderConversationsPage
        )
        .verifySharedFile(name: "TESTFILE", type: "PDF", timeout: fileUploadTimeout, requireReady: true)

        try logOutSenderAndOpenReceiverConversation(
            from: activeConversationPage,
            sender: scenario.sender,
            conversationName: scenario.receiverConversationName
        )
        .verifySharedFile(name: "TESTFILE", type: "PDF")
    }

    @MainActor
    func testShareImageToChannelConversation_TC_8923() async throws {
        let channelName = UserGenerator.generateRandomConversationName()
        let scenario = try await createTeamShareScenario(conversation: .channel(channelName))

        try await shareFirstPhotoToWire(conversationName: scenario.conversationName, accountName: scenario.sender.name)

        let activeConversationPage = try openConversation(
            named: scenario.conversationName,
            on: scenario.senderConversationsPage
        )
        assertImageShared(on: activeConversationPage)
    }

    @MainActor
    func testShareVideoToChannelConversation_TC_8924() async throws {
        let channelName = UserGenerator.generateRandomConversationName()
        let scenario = try await createTeamShareScenario(conversation: .channel(channelName))

        try await shareFixtureFileToWire(
            fileName: testVideoName,
            conversationName: scenario.conversationName,
            accountName: scenario.sender.name
        )

        let activeConversationPage = try openConversation(
            named: scenario.conversationName,
            on: scenario.senderConversationsPage
        )
        assertVideoShared(on: activeConversationPage)
    }

    @MainActor
    func testShareFileToChannelConversation_TC_8925_8926() async throws {
        let channelName = UserGenerator.generateRandomConversationName()
        let scenario = try await createTeamShareScenario(conversation: .channel(channelName))

        try await shareFixtureFileToWire(
            fileName: testFileName,
            conversationName: scenario.conversationName,
            accountName: scenario.sender.name
        )

        let activeConversationPage = try openConversation(
            named: scenario.conversationName,
            on: scenario.senderConversationsPage
        )
        .verifySharedFile(name: "TESTFILE", type: "PDF", timeout: fileUploadTimeout, requireReady: true)

        try logOutSenderAndOpenReceiverConversation(
            from: activeConversationPage,
            sender: scenario.sender,
            conversationName: scenario.receiverConversationName
        )
        .verifySharedFile(name: "TESTFILE", type: "PDF")
    }
}

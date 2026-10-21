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

/// [core-messenger]
final class ShareExtensionTests: WireUITestCase {

    private let photosAppBundleId = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
    private let filesAppBundleId = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
    private let testFileName = "testFile.pdf"
    private let testVideoName = "testVideo.mp4"
    private let shareExtensionMessage = "shared via share-ext"
    private let appLaunchTimeout: TimeInterval = 5
    private let timeout: TimeInterval = 2

    @MainActor
    private func launchPhotosApp() async throws {
        photosAppBundleId.launch()
        XCTAssertTrue(photosAppBundleId.wait(for: .runningForeground, timeout: appLaunchTimeout))
    }

    @MainActor
    private func launchFilesApp() async throws {
        filesAppBundleId.terminate()
        filesAppBundleId.launch()
        XCTAssertTrue(filesAppBundleId.wait(for: .runningForeground, timeout: appLaunchTimeout))
    }

    @MainActor
    private func shareFirstImageToWire(conversationName: String) async throws {
        try await launchPhotosApp()

        let photosApp = try PhotosAppPage(photosApp: photosAppBundleId)
        try photosApp
            .selectImageFromPhotos()
            .shareImageToWire()
            .chooseConversationAndSend(name: conversationName, message: shareExtensionMessage)

        try await switchBackToWireApp()
    }

    @MainActor
    private func shareFixtureFileToWire(fileName: String, conversationName: String) async throws {
        try await launchFilesApp()

        let filesApp = try FilesAppPage(filesApp: filesAppBundleId)
        try filesApp
            .selectAndShareFileToWire(named: fileName)
            .chooseConversationAndSend(name: conversationName, message: shareExtensionMessage)

        try await switchBackToWireApp()
    }

    @MainActor
    private func switchBackToWireApp() async throws {
        app.activate()
        if !app.wait(for: .runningForeground, timeout: appLaunchTimeout) {
            app.launch()
            _ = app.wait(for: .runningForeground, timeout: appLaunchTimeout)
        }
    }

    @MainActor
    private func createTeamAndLoginAsOwner(
        conversation: CreateConversationOption? = nil
    ) async throws -> (
        teamOwner: UserInfo,
        member: UserInfo,
        conversationName: String,
        conversationsPage: ConversationsPage
    ) {
        let (teamOwner, teamMembers, _, _) =
            if let conversation {
                try await UserHelper.default.registerTeam(
                    withMemberCount: 1,
                    conversation: conversation
                )
            } else {
                try await UserHelper.default.registerTeam(withMemberCount: 1)
            }

        let member = try XCTUnwrap(teamMembers.first)
        let conversationName =
            if let conversation {
                switch conversation {
                case let .group(name), let .channel(name):
                    name
                }
            } else {
                member.name
            }

        let firstTimePage = try app.loginUser(
            email: teamOwner.email,
            password: teamOwner.password
        )
        let conversationsPage = try firstTimePage.acceptPopup()

        return (
            teamOwner: teamOwner,
            member: member,
            conversationName: conversationName,
            conversationsPage: conversationsPage
        )
    }

    @MainActor
    private func startOneOnOneConversation(
        with userName: String,
        from conversationsPage: ConversationsPage
    ) throws -> ConversationsPage {
        let conversationsPage = try conversationsPage
            .tapPlusButtonToCreateGroup()
            .openUserDetailsInContactList()
            .tapStartConversationButton()
            .goBackToConversationPage()

        XCTAssertTrue(
            conversationsPage.conversationCell(named: userName).waitForExistence(timeout: timeout),
            "Conversation '\(userName)' did not show up after creating 1:1"
        )

        return conversationsPage
    }

    @MainActor
    private func addReceiverUserAndSwitchAccount(
        email: String,
        password: String,
        switchBackToUserName: String
    ) async throws {
        _ = try ConversationsPage()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        let firstTimePage = try app.loginUser(email: email, password: password)
        _ = try firstTimePage.acceptPopup()

        _ = try ConversationsPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: switchBackToUserName)
    }

    @MainActor
    private func openConversation(
        named conversationName: String,
        on conversationsPage: ConversationsPage
    ) throws -> ActiveConversationPage {
        try conversationsPage.letTheSyncFinish()
        let conversationCell = conversationsPage.conversationCell(named: conversationName)
        XCTAssertTrue(
            conversationCell.waitForExistence(timeout: timeout),
            "Conversation '\(conversationName)' did not show up"
        )
        XCTAssertTrue(
            conversationCell.waitAndTap(timeout: 2),
            "Conversation '\(conversationName)' was not tappable"
        )
        return try ActiveConversationPage()
    }

    private func assertImageShared(on activeConversationPage: ActiveConversationPage) {
        XCTAssertTrue(
            activeConversationPage.imageCell.waitForExistence(timeout: timeout),
            "No Image cell found"
        )
    }

    private func assertVideoShared(on activeConversationPage: ActiveConversationPage) {
        XCTAssertTrue(
            activeConversationPage.videoCell.waitForExistence(timeout: timeout),
            "No Video cell found"
        )
        XCTAssertTrue(
            activeConversationPage.videoPlayButton.waitForExistence(timeout: timeout),
            "No Video play button found"
        )
    }

    @MainActor
    private func addMemberToConversation(
        named conversationName: String,
        memberName: String
    ) throws -> ConversationsPage {
        let conversationDetailsPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        .openConversationDetails()

        return try conversationDetailsPage
            .appParticipantToConversation()
            .tapMemberCells(withLabelPrefixes: [memberName])
            .addSelectedParticipant()
            .closeConversationDetails()
            .goBackToConversationPage()
    }

    @MainActor
    func testShareImageOnetoOne_TC_8915() async throws {
        // GIVEN
        let scenario = try await createTeamAndLoginAsOwner()
        let conversationName = scenario.conversationName
        _ = try startOneOnOneConversation(
            with: conversationName,
            from: scenario.conversationsPage
        )

        // WHEN
        try await shareFirstImageToWire(conversationName: conversationName)

        // THEN
        let activeConversationPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        assertImageShared(on: activeConversationPage)
        activeConversationPage.verifyMessageSent(shareExtensionMessage)
    }

    @MainActor
    func testShareVideoToOneOnOneConversation_TC_8916() async throws {
        // GIVEN
        let scenario = try await createTeamAndLoginAsOwner()
        let conversationName = scenario.conversationName
        _ = try startOneOnOneConversation(
            with: conversationName,
            from: scenario.conversationsPage
        )

        // WHEN
        try await shareFixtureFileToWire(
            fileName: testVideoName,
            conversationName: conversationName
        )

        // THEN
        let activeConversationPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        assertVideoShared(on: activeConversationPage)
        activeConversationPage.verifyMessageSent(shareExtensionMessage)
    }

    @MainActor
    func testShareAndReceiveFileToOneOnOneConversation_TC_8917_8918() async throws {
        // GIVEN
        let scenario = try await createTeamAndLoginAsOwner()
        let teamOwner = scenario.teamOwner
        let member = scenario.member
        let conversationName = scenario.conversationName

        try await addReceiverUserAndSwitchAccount(
            email: member.email,
            password: member.password,
            switchBackToUserName: teamOwner.name
        )

        _ = try startOneOnOneConversation(
            with: conversationName,
            from: scenario.conversationsPage
        )

        // WHEN
        try await shareFixtureFileToWire(
            fileName: testFileName,
            conversationName: conversationName
        )

        try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        // THEN - file is sent
        .verifySharedFile(name: "TESTFILE", type: "PDF")
        .verifyMessageSent(shareExtensionMessage)
        .goBackToConversationPage()
        .openUserProfilePage()
        .switchUserAccountForUser(withName: member.name)

        try openConversation(
            named: teamOwner.name,
            on: try ConversationsPage()
        )
        // THEN - file is received
        .verifySharedFile(name: "TESTFILE", type: "PDF")
        .verifyMessageSent(shareExtensionMessage)
    }

    /// [critical]
    @MainActor
    func testShareImageToGroupConversation_TC_8919() async throws {
        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let scenario = try await createTeamAndLoginAsOwner(conversation: .group(groupName))
        let conversationName = scenario.conversationName

        // WHEN
        try await shareFirstImageToWire(conversationName: conversationName)

        // THEN
        let activeConversationPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        assertImageShared(on: activeConversationPage)
        activeConversationPage.verifyMessageSent(shareExtensionMessage)
    }

    @MainActor
    func testShareVideoToGroupConversation_TC_8920() async throws {
        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let scenario = try await createTeamAndLoginAsOwner(conversation: .group(groupName))
        let conversationName = scenario.conversationName

        // WHEN
        try await shareFixtureFileToWire(
            fileName: testVideoName,
            conversationName: conversationName
        )

        // THEN
        let activeConversationPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        assertVideoShared(on: activeConversationPage)
        activeConversationPage.verifyMessageSent(shareExtensionMessage)
    }

    @MainActor
    func testShareAndReceiveFileToGroupConversation_TC_8921_8922() async throws {
        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let scenario = try await createTeamAndLoginAsOwner(conversation: .group(groupName))
        let conversationName = scenario.conversationName
        let teamOwner = scenario.teamOwner
        let member = scenario.member

        try await addReceiverUserAndSwitchAccount(
            email: member.email,
            password: member.password,
            switchBackToUserName: teamOwner.name
        )

        // WHEN
        try await shareFixtureFileToWire(
            fileName: testFileName,
            conversationName: conversationName
        )

        try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        // THEN - file is sent
        .verifySharedFile(name: "TESTFILE", type: "PDF")
        .verifyMessageSent(shareExtensionMessage)
        .goBackToConversationPage()
        .openUserProfilePage()
        .switchUserAccountForUser(withName: member.name)

        try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        // THEN - file is received
        .verifySharedFile(name: "TESTFILE", type: "PDF")
        .verifyMessageSent(shareExtensionMessage)
    }

    @MainActor
    func testShareImageToChannelConversation_TC_8923() async throws {
        // GIVEN
        let channelName = UserGenerator.generateRandomConversationName()
        let scenario = try await createTeamAndLoginAsOwner(conversation: .channel(channelName))
        let conversationName = scenario.conversationName

        // WHEN
        try await shareFirstImageToWire(conversationName: conversationName)

        // THEN
        let activeConversationPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        assertImageShared(on: activeConversationPage)
        activeConversationPage.verifyMessageSent(shareExtensionMessage)
    }

    @MainActor
    func testShareVideoToChannelConversation_TC_8924() async throws {
        // GIVEN
        let channelName = UserGenerator.generateRandomConversationName()
        let scenario = try await createTeamAndLoginAsOwner(conversation: .channel(channelName))
        let conversationName = scenario.conversationName

        // WHEN
        try await shareFixtureFileToWire(
            fileName: testVideoName,
            conversationName: conversationName
        )

        // THEN
        let activeConversationPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        assertVideoShared(on: activeConversationPage)
        activeConversationPage.verifyMessageSent(shareExtensionMessage)
    }

    @MainActor
    func testShareAndReceiveFileToChannelConversation_TC_8925_8926() async throws {
        // GIVEN
        let channelName = UserGenerator.generateRandomConversationName()
        let scenario = try await createTeamAndLoginAsOwner(conversation: .channel(channelName))
        let conversationName = scenario.conversationName
        let teamOwner = scenario.teamOwner
        let member = scenario.member

        try await addReceiverUserAndSwitchAccount(
            email: member.email,
            password: member.password,
            switchBackToUserName: teamOwner.name
        )

        _ = try addMemberToConversation(
            named: conversationName,
            memberName: member.name
        )

        // WHEN
        try await shareFixtureFileToWire(
            fileName: testFileName,
            conversationName: conversationName
        )

        try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        // THEN - file is sent
        .verifySharedFile(name: "TESTFILE", type: "PDF")
        .verifyMessageSent(shareExtensionMessage)
        .goBackToConversationPage()
        .openUserProfilePage()
        .switchUserAccountForUser(withName: member.name)

        try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        // THEN - file is received
        .verifySharedFile(name: "TESTFILE", type: "PDF")
        .verifyMessageSent(shareExtensionMessage)
    }
}

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

    private let photosAppBundleId = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
    private let filesAppBundleId = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
    private let testFileName = "testFile.pdf"
    private let testVideoName = "testVideo.mp4"
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
            .openFirstImage()
            .shareImageToWire()
            .chooseConversationAndSend(name: conversationName)

        try await switchBackToWireApp()
    }

    @MainActor
    private func shareFixtureFileToWire(fileName: String, conversationName: String) async throws {
        try await launchFilesApp()

        let filesApp = try FilesAppPage(filesApp: filesAppBundleId)
        try filesApp
            .shareFileToWire(named: fileName)
            .chooseConversationAndSend(name: conversationName)

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
    private func createOneOnOneShareScenario() async throws -> String {
        let (teamOwner, teamMembers, _, _) = try await UserHelper.default.registerTeam(withMemberCount: 1)
        let member = try XCTUnwrap(teamMembers.first)

        let firstTimePage = try app.loginUser(email: member.email, password: member.password)
        let conversationsPage = try firstTimePage
            .acceptPopup()
            .tapPlusButtonToCreateGroup()
            .openUserDetailsInContactList()
            .tapStartConversationButton()
            .goBackToConversationPage()

        XCTAssertTrue(
            conversationsPage.conversationCell(named: teamOwner.name).waitForExistence(timeout: timeout),
            "Conversation '\(teamOwner.name)' did not show up after creating 1:1"
        )

        return teamOwner.name
    }

    @MainActor
    private func createTeamShareScenario(conversation: CreateConversationOption) async throws -> String {
        let conversationName: String = switch conversation {
        case let .group(name), let .channel(name):
            name
        }

        let (teamOwner, _, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: conversation
        )
        let firstTimePage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
        let conversationsPage = try firstTimePage.acceptPopup()

        XCTAssertTrue(
            conversationsPage.conversationCell(named: conversationName).waitForExistence(timeout: timeout),
            "Conversation '\(conversationName)' did not show up after sender login"
        )

        return conversationName
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
    func testShareImageOnetoOne_TC_8915() async throws {
        let conversationName = try await createOneOnOneShareScenario()

        try await shareFirstImageToWire(conversationName: conversationName)

        let activeConversationPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        assertImageShared(on: activeConversationPage)
    }

    @MainActor
    func testShareVideoToOneOnOneConversation_TC_8916() async throws {
        let conversationName = try await createOneOnOneShareScenario()

        try await shareFixtureFileToWire(
            fileName: testVideoName,
            conversationName: conversationName
        )

        let activeConversationPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        assertVideoShared(on: activeConversationPage)
    }

    @MainActor
    func testShareFileToOneOnOneConversation_TC_8917() async throws {
        let conversationName = try await createOneOnOneShareScenario()

        try await shareFixtureFileToWire(
            fileName: testFileName,
            conversationName: conversationName
        )

        try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        .verifySharedFile(name: "TESTFILE", type: "PDF")
    }

    @MainActor
    func testShareImageToGroupConversation_TC_8919() async throws {
        let groupName = UserGenerator.generateRandomConversationName()
        let conversationName = try await createTeamShareScenario(conversation: .group(groupName))

        try await shareFirstImageToWire(conversationName: conversationName)

        let activeConversationPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        assertImageShared(on: activeConversationPage)
    }

    @MainActor
    func testShareVideoToGroupConversation_TC_8920() async throws {
        let groupName = UserGenerator.generateRandomConversationName()
        let conversationName = try await createTeamShareScenario(conversation: .group(groupName))

        try await shareFixtureFileToWire(
            fileName: testVideoName,
            conversationName: conversationName
        )

        let activeConversationPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        assertVideoShared(on: activeConversationPage)
    }

    @MainActor
    func testShareFileToGroupConversation_TC_8921() async throws {
        let groupName = UserGenerator.generateRandomConversationName()
        let conversationName = try await createTeamShareScenario(conversation: .group(groupName))

        try await shareFixtureFileToWire(
            fileName: testFileName,
            conversationName: conversationName
        )

        try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        .verifySharedFile(name: "TESTFILE", type: "PDF")
    }

    @MainActor
    func testShareImageToChannelConversation_TC_8923() async throws {
        let channelName = UserGenerator.generateRandomConversationName()
        let conversationName = try await createTeamShareScenario(conversation: .channel(channelName))

        try await shareFirstImageToWire(conversationName: conversationName)

        let activeConversationPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        assertImageShared(on: activeConversationPage)
    }

    @MainActor
    func testShareVideoToChannelConversation_TC_8924() async throws {
        let channelName = UserGenerator.generateRandomConversationName()
        let conversationName = try await createTeamShareScenario(conversation: .channel(channelName))

        try await shareFixtureFileToWire(
            fileName: testVideoName,
            conversationName: conversationName
        )

        let activeConversationPage = try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        assertVideoShared(on: activeConversationPage)
    }

    @MainActor
    func testShareFileToChannelConversation_TC_8925() async throws {
        let channelName = UserGenerator.generateRandomConversationName()
        let conversationName = try await createTeamShareScenario(conversation: .channel(channelName))

        try await shareFixtureFileToWire(
            fileName: testFileName,
            conversationName: conversationName
        )

        try openConversation(
            named: conversationName,
            on: try ConversationsPage()
        )
        .verifySharedFile(name: "TESTFILE", type: "PDF")
    }
}

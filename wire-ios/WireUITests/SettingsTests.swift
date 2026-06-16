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

import XCTest

final class SettingsTests: WireUITestCase {

    private let profileColorWaitTimeout: TimeInterval = 5

    @MainActor
    func testChangeAppThemeToSystemDarkOrLight_TC_8945() async throws {
        // GIVEN
        let user = try await UserHelper.default.createPersonalUser()

        // WHEN
        var optionsPage = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openSettings()
            .openOptionsMenu()
            // THEN - system theme is selected by default
            .verifyTheme(.system)

        optionsPage = try optionsPage
            .openThemeSettings()
            .selectTheme(.dark)
            .backToOptions()
            // THEN - dark theme is selected
            .verifyTheme(.dark)

        _ = try optionsPage
            .openThemeSettings()
            .selectTheme(.light)
            .backToOptions()
            // THEN - light theme is selected
            .verifyTheme(.light)
    }

    @MainActor
    func testChangeProfileColor_TC_8942() async throws {
        // GIVEN
        let user = try await UserHelper.default.createPersonalUser()
        let profileColor = AccountSettingsPage.ProfileColor.purple

        // WHEN
        _ = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openSettings()
            .openAccountSettings()
            .selectProfileColor(profileColor)

        // THEN
        try await waitForSelfUserAccentID(
            profileColor.accentID,
            timeout: profileColorWaitTimeout
        )
    }

    @MainActor
    func testAddAndViewDisplayPicture_TC_8939_8813() async throws {
        // GIVEN
        let user = try await UserHelper.default.createPersonalUser()

        // WHEN
        let accountSettingsPage = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openSettings()
            .openAccountSettings()
            .setProfilePictureFromLibrary()

        // THEN
        _ = try accountSettingsPage
            .goBackToSettingsPage()
            .switchToConversationsTab()
            .openUserProfilePage()
            .verifyProfilePictureIsSet()
    }

    @MainActor
    func testConversationBackgroundColorMatchingProfileColor_TC_8943() async throws {
        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let (teamOwner, _, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .group(groupName)
        )
        let profileColor = AccountSettingsPage.ProfileColor.purple

        // WHEN
        let settingsPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .openSettings()
            .openAccountSettings()
            .selectProfileColor(profileColor)
            .enableConversationBackground()
            .goBackToSettingsPage()

        // THEN - profile color is updated
        try await waitForSelfUserAccentID(
            profileColor.accentID,
            timeout: profileColorWaitTimeout
        )

        // THEN - conversation background matches profile color
        let activeConversationPage = try settingsPage
            .switchToConversationsTab()
            .openConversation()

        activeConversationPage.verifyConversationBackgroundColor(profileColor)
    }

    @MainActor
    func testCreateLinkPreviewsOption_TC_8951() async throws {
        let stagingTeam = try await UserHelper.default.registerTeam(withMemberCount: 2)
        let userA = try XCTUnwrap(stagingTeam.teamMembers.first)
        let userB = try XCTUnwrap(stagingTeam.teamMembers.last)

        // Login & create conversation
        _ = try await loginToBackend(user: userA)
            .tapPlusButtonToCreateGroup()
            .tapNewGroupButton()
            .enterGroupName("Test")
            .tapMemberCells(withLabelPrefixes: [userB.name])
            .doneSelectingMembers()
            .goBackToConversationPage()

        // Disable link previews
        _ = try ConversationsPage()
            .openSettings()
            .openOptionsMenu()
            .disableCreateLinkPreviews()
            .backToSettings()
            .switchToConversationsTab()

        // Open conversation and send first link
        _ = try ConversationsPage()
            .openConversation()
            .sendMessage("First link: https://github.com/wireapp/wire-ios")
            .goBackToConversationPage()

        // Enable link previews
        _ = try ConversationsPage()
            .openSettings()
            .openOptionsMenu()
            .enableCreateLinkPreviews()
            .backToSettings()
            .switchToConversationsTab()

        // Open conversation and send first link
        let conversationPage = try ConversationsPage()
            .openConversation()
            .sendMessage("Second link: https://github.com/wireapp/wire-android")

        // Verify first message is the original message without preview
        _ = conversationPage
            .verifyMessageSent("First link: https://github.com/wireapp/wire-ios")

        // Verify second message has link preview
        _ = conversationPage
            .verifyMessageSent("Second link:")
            .verifyLinkPreviewCell()
    }

    private func waitForSelfUserAccentID(
        _ expectedAccentID: Int,
        timeout: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        var lastAccentID: Int?

        repeat {
            let selfUser = try await UserHelper.default.selfUserAPI.getSelfUser()
            lastAccentID = selfUser.accentID
            if selfUser.accentID == expectedAccentID {
                return
            }
            try await Task.sleep(for: .seconds(1))
        } while Date() < deadline

        XCTFail(
            "Expected self user accent ID \(expectedAccentID), got \(String(describing: lastAccentID))",
            file: file,
            line: line
        )
    }

}

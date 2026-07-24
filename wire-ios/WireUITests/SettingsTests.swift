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

/// [core-messenger]
final class SettingsTests: WireUITestCase {

    @MainActor
    func testChangeAppThemeToSystemDarkOrLight_TC_8945() async throws {
        // GIVEN
        let user = try await UserHelper.default.createPersonalUser()

        // WHEN
        let optionsPage = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openSettings()
            .openOptionsMenu()
            // THEN - system theme is selected by default as light
            .verifyTheme(.system)

        let themeSettingsPage = try optionsPage
            .openThemeSettings()
            .selectTheme(.dark)
            .backToOptions()
            // THEN - dark theme is selected
            .verifyTheme(.dark)

        _ = try themeSettingsPage
            .openThemeSettings()
            .selectTheme(.light)
            .backToOptions()
            // THEN - light theme is selected
            .verifyTheme(.light)
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
    func testChangeProfileColorAndConversationBackgroundColor_TC_8942_8943() async throws {
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
            // THEN - profile color is updated
            .verifyProfileColor(profileColor)
            .enableConversationBackground()
            .goBackToSettingsPage()

        let activeConversationPage = try settingsPage
            .switchToConversationsTab()
            .openConversation()

        // THEN - conversation background matches profile color
        try await activeConversationPage.verifyConversationBackgroundColor(profileColor)
    }

    @MainActor
    func testCreateLinkPreviewsOption_TC_8951() async throws {
        let (stagingTeam, _, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 2,
            conversation: .group("Test")
        )

        // Login & Disable link previews
        let conversationPage = try app.loginUser(email: stagingTeam.email, password: stagingTeam.password)
            .acceptPopup()
            .openSettings()
            .openOptionsMenu()
            .disableCreateLinkPreviews()
            .backToSettings()
            .switchToConversationsTab()
            // Open conversation and send first link
            .openConversation()
            .sendMessage("First link: https://github.com/wireapp/wire-ios")
            .goBackToConversationPage()
            // Enable link previews
            .openSettings()
            .openOptionsMenu()
            .enableCreateLinkPreviews()
            .backToSettings()
            .switchToConversationsTab()
            // Open conversation and send first link
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

    @MainActor
    func testUpdateReadReceiptSettingOnGroupConversation_TC_8947() async throws {

        // GIVEN - a group conversation (read receipts are on by default)
        let groupName = UserGenerator.generateRandomConversationName()
        let (team, _, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .group(groupName)
        )

        let activeConversationPage = try app.loginUser(email: team.email, password: team.password)
            .acceptPopup()
            .openConversation()

        // WHEN - read receipts are turned off
        _ = try activeConversationPage
            .openConversationDetails()
            .toggleGroupReadReceipts()
            .closeConversationDetails()
            // THEN - a system message confirms read receipts are off
            .verifyReadReceiptsSystemMessage(enabled: false)

        // WHEN - read receipts are turned back on
        _ = try activeConversationPage
            .openConversationDetails()
            .toggleGroupReadReceipts()
            .closeConversationDetails()
            // THEN - a system message confirms read receipts are on
            .verifyReadReceiptsSystemMessage(enabled: true)
    }
}

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

import WireLocators
import XCTest

class ConversationsPage: PageModel {
    override var pageMainElement: XCUIElement {
        conversationsButton
    }

    var conversationsButton: XCUIElement {
        app.buttons[Locators.ConversationsPage.bottomBarRecentListButton.rawValue]
    }

    var settingsButton: XCUIElement {
        app.buttons[Locators.ConversationsPage.bottomBarSettingsButton.rawValue]
    }

    var archivedButton: XCUIElement {
        app.buttons[Locators.ConversationsPage.bottomBarArchivedButton.rawValue]
    }

    var plusButtonToCreateGroup: XCUIElement {
        app.descendants(matching: .any)[Locators.ConversationsPage.createGroupOrSearchButton.rawValue].firstMatch
    }

    var conversationCell: XCUIElement {
        app.buttons[Locators.ConversationsPage.conversationCell.rawValue]
    }

    var blockButtonOnMoreOptions: XCUIElement {
        app.buttons[Locators.ConversationsPage.blockOptionOnContextMenu.rawValue]
    }

    var blockButtonOnBottomSheet: XCUIElement {
        app.buttons[Locators.ConversationsPage.blockButtonOnBottomSheet.rawValue].firstMatch
    }

    var videoCallButton: XCUIElement {
        app.descendants(matching: .any)[Locators.ActiveConversationPage.videoCallBarButton.rawValue].firstMatch
    }

    var acceptRequestButton: XCUIElement {
        app.buttons[Locators.ConnectionRequestsPage.connectRequestButton.rawValue]
    }

    var accountProfileImageView: XCUIElement {
        app.buttons[Locators.ConversationsPage.accountProfileImageView.rawValue]
    }

    func openSettings() throws -> SettingsPage {
        settingsButton.tap()
        return try SettingsPage()
    }

    func openArchived() throws -> ArchivedConversationsPage {
        archivedButton.tap()
        return try ArchivedConversationsPage()
    }

    func openUserProfilePage() throws -> UserProfilePage {
        try VerifyUserIsOnConversationsTab()

        if accountProfileImageView.waitAndTap() {
            return try UserProfilePage()
        }

        // Fallback: Sometimes observed on CI that accountProfileImageView isn't tappable after login.
        let userAccountButton = app.buttons
            .containing(NSPredicate(format: "value CONTAINS[c] %@", "account"))
            .firstMatch

        if userAccountButton.waitAndTap(timeout: 5.0) {
            return try UserProfilePage()
        }

        XCTFail("Could not open user profile: neither profile image nor account button was tappable")
        return try UserProfilePage()
    }

    func tapPlusButtonToCreateGroup() throws -> NewConversationPage {
        plusButtonToCreateGroup.tap()
        return try NewConversationPage()
    }

    func openPendingRequest() throws -> ConnectionRequestsPage {
        XCTAssertTrue(conversationCell.waitForExistence(timeout: 5), "Conversation cell did not appear")

        let maxDuration: TimeInterval = 10
        let start = Date()

        while !acceptRequestButton.exists, Date().timeIntervalSince(start) < maxDuration {
            if conversationCell.isHittable {
                conversationCell.tap()
            }
            RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        }
        return try ConnectionRequestsPage()
    }

    func openConversation() throws -> ActiveConversationPage {
        XCTAssertTrue(conversationCell.waitForExistence(timeout: 5), "Conversation cell did not appear")

        let maxDuration: TimeInterval = 10
        let start = Date()

        while !videoCallButton.exists, Date().timeIntervalSince(start) < maxDuration {
            if conversationCell.isHittable {
                conversationCell.tap()
            }
            RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        }
        return try ActiveConversationPage()
    }

    func longPressForMoreOptionOnConversation() throws -> ConversationsPage {
        conversationCell.press(forDuration: 1.0)
        return try ConversationsPage()
    }

    func blockUser() throws -> ConversationsPage {
        blockButtonOnMoreOptions.tap()
        blockButtonOnBottomSheet.tap()
        return self
    }

    func getNameLabel() -> String? {
        conversationCell.label
    }

    // Problem: Opening the user profile can occasionally fail while sync is in progress after login
    // Workaround: Assert the presence of some UI elements to give the sync time to complete.
    func VerifyUserIsOnConversationsTab() throws {
        XCTAssertTrue(plusButtonToCreateGroup.exists)
        XCTAssertTrue(archivedButton.exists)
        XCTAssert(settingsButton.exists)
    }
}

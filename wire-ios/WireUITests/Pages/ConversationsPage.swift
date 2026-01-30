//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
        plusButtonToCreateGroupOrSearch
    }

    var settingsButton: XCUIElement {
        app.buttons[Locators.ConversationsPage.bottomBarSettingsButton.rawValue]
    }

    var plusButtonToCreateGroupOrSearch: XCUIElement {
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

    func openSettings() throws -> SettingsPage {
        app.iPadOnly {
            self.app.openSidePanel()
        }
        settingsButton.tap()
        return try SettingsPage()
    }

    func openUserAccountPageForUser(with input: String) throws -> UserProfilePage {
        app.iPadOnly {
            self.app.openSidePanel()
        }
        let predicate = NSPredicate(format: "value BEGINSWITH %@", input)
        let button = app.descendants(matching: .any).matching(predicate).firstMatch
        if button.waitForExistence(timeout: 2), button.isHittable {
            button.tap()
        }
        return try UserProfilePage()
    }

    func tapPlusButtonToCreateGroup() throws -> NewConversationPage {
        app.iPadOnly {
            self.app.dismissSidePanel()
        }
        plusButtonToCreateGroupOrSearch.tap()
        return try NewConversationPage()
    }

    func openPendingRequest() throws -> ConnectionRequestsPage {
        app.iPadOnly {
            self.app.dismissSidePanel()
        }
        XCTAssertTrue(conversationCell.waitForExistence(timeout: 5), "Conversation cell did not appear")
        conversationCell.tap()

        if !acceptRequestButton.exists {
            let maxDuration: TimeInterval = 10
            let start = Date()
            let pollInterval: TimeInterval = 0.5

            repeat {
                if acceptRequestButton.exists { break }
                _ = acceptRequestButton.waitForExistence(timeout: pollInterval)
            } while Date().timeIntervalSince(start) < maxDuration
        }
        return try ConnectionRequestsPage()
    }

    func openConversation() throws -> ActiveConversationPage {
        app.iPadOnly {
            self.app.dismissSidePanel()
        }
        XCTAssertTrue(conversationCell.waitForExistence(timeout: 5), "Conversation cell did not appear")
        conversationCell.tap()

        if !videoCallButton.exists {
            let maxDuration: TimeInterval = 10
            let start = Date()
            let pollInterval: TimeInterval = 0.5

            repeat {
                if videoCallButton.exists { break }
                _ = videoCallButton.waitForExistence(timeout: pollInterval)
            } while Date().timeIntervalSince(start) < maxDuration
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
        app.iPadOnly {
            self.app.dismissSidePanel()
        }
        return conversationCell.label
    }
}

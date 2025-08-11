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

import XCTest

class ConversationsPage: PageModel {
    override var pageMainElement: XCUIElement {
        conversationsPageLabel
    }

    var conversationsPageLabel: XCUIElement {
        app.staticTexts["Conversations"]
    }

    var settingsButton: XCUIElement {
        app.buttons["bottomBarSettingsButton"]
    }

    var plusButtonToCreateGroup: XCUIElement {
        app.descendants(matching: .any)["create_group_or_search_button"].firstMatch
    }

    var conversationCell: XCUIElement {
        app.buttons["title"]
    }

    var blockButtonOnMoreOptions: XCUIElement {
        app.buttons["Block…"]
    }

    var blockButtonOnBottomSheet: XCUIElement {
        app.buttons["Block"]
    }

    func openSettings() throws -> SettingsPage {
        settingsButton.tap()
        return try SettingsPage()
    }
    
    func getGroupName() -> String? {
          conversationCell.label as? String
      }

    func openUserAccountPageForUser(with input: String) throws -> UserAccountPage {
        let predicate = NSPredicate(format: "value BEGINSWITH %@", input)
        let button = app.buttons.containing(predicate).firstMatch
        button.tap()
        return try UserAccountPage()
    }

    func tapPlusButtonToCreateGroup() throws -> NewConversationPage {
        plusButtonToCreateGroup.tap()
        return try NewConversationPage()
    }

    func openPendingRequest() throws -> ConnectionRequestsPage {
        if conversationCell.waitForExistence(timeout: 5) {
            conversationCell.tap()
        }
        return try ConnectionRequestsPage()
    }

    func openConversation() throws -> ActiveConversationPage {
        if conversationCell.waitForExistence(timeout: 5) {
            conversationCell.tap()
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
        conversationCell.label as? String
    }
    
    func waitUntilLastMessageReceivedByTestService(with sentBy: String) throws -> Bool {
          let predicate = NSPredicate(format: "label BEGINSWITH %@", sentBy)
          let button = app.staticTexts.containing(predicate).firstMatch
          return button.waitForExistence(timeout: 5)
      }
}

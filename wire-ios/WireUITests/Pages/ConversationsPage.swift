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

    var videoCallButton: XCUIElement {
        app.descendants(matching: .any)["videoCallBarButton"].firstMatch
    }

    var acceptRequestButton: XCUIElement {
        app.buttons["accept"]
    }

    var sidePanel: XCUIElement {
        app.otherElements["PopoverDismissRegion"]
    }

    var sideBarPanel: XCUIElement {
        app.buttons["ToggleSidebar"]
    }

    func openSettings() throws -> SettingsPage {
        app.onPad {
            if self.sideBarPanel.exists {
                self.sideBarPanel.tap()
            }
        }
        settingsButton.tap()
        return try SettingsPage()
    }

    func openUserAccountPageForUser(with input: String) throws -> UserAccountPage {
        app.onPad {
            if self.sideBarPanel.exists {
                self.sideBarPanel.tap()
            }
        }
        let predicate = NSPredicate(format: "value BEGINSWITH %@", input)
        let button = app.descendants(matching: .any).matching(predicate).firstMatch
        button.tap()
        return try UserAccountPage()
    }

    func tapPlusButtonToCreateGroup() throws -> NewConversationPage {
        app.onPad {
            if self.sidePanel.exists {
                self.sidePanel.tap()
            }
        }
        plusButtonToCreateGroupOrSearch.tap()
        return try NewConversationPage()
    }

    func openPendingRequest() throws -> ConnectionRequestsPage {
        app.onPad {
            if self.sidePanel.exists {
                self.sidePanel.tap()
            }
        }
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
        app.onPad {
            if self.sidePanel.exists {
                self.sidePanel.tap()
            }
        }
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
        app.onPad {
            if self.sidePanel.exists {
                self.sidePanel.tap()
            }
        }
        return conversationCell.label
    }
}

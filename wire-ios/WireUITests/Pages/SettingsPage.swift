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

class SettingsPage: PageModel {

    override var pageMainElement: XCUIElement {
        accountSettingsMenu
    }

    var accountSettingsMenu: XCUIElement {
        let elementsQuery = app.cells
        return elementsQuery["Account"]
    }

    var optionsMenu: XCUIElement {
        let elementsQuery = app.cells
        return elementsQuery["Options"]
    }

    var conversationsTab: XCUIElement {
        app.buttons["bottomBarRecentListButton"]
    }

    var sideBarPanel: XCUIElement {
        app.buttons["ToggleSidebar"]
    }

    var allConversations: XCUIElement {
        app.buttons["All"]
    }

    func openAccountSettings() throws -> AccountSettingsPage {
        accountSettingsMenu.tap()
        return try AccountSettingsPage()
    }

    func openOptionsMenu() throws -> OptionsOnSettingsPage {
        optionsMenu.tap()
        return try OptionsOnSettingsPage()
    }

    func switchToAllConversations() throws -> ConversationsPage {
        if conversationsTab.exists {
            conversationsTab.tap()
        } else {
            _ = app.iPadOnlyFlow([sideBarPanel, allConversations]) { $0.tap() }
        }
        return try ConversationsPage()
    }
}

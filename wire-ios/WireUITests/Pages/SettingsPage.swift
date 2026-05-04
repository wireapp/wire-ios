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

class SettingsPage: PageModel {

    override var pageMainElement: XCUIElement {
        accountSettingsMenu
    }

    var accountSettingsMenu: XCUIElement {
        app.cells[Locators.SettingsPage.accountCell.rawValue].firstMatch
    }

    var optionsMenu: XCUIElement {
        app.cells[Locators.SettingsPage.optionsCell.rawValue].firstMatch
    }

    var conversationsTab: XCUIElement {
        app.buttons[Locators.ConversationsPage.bottomBarRecentListButton.rawValue]
    }

    func openAccountSettings() throws -> AccountSettingsPage {
        XCTAssertTrue(accountSettingsMenu.waitForExistence(timeout: 3))
        accountSettingsMenu.tap()
        return try AccountSettingsPage()
    }

    func openOptionsMenu() throws -> OptionsOnSettingsPage {
        optionsMenu.tap()
        return try OptionsOnSettingsPage()
    }

    func switchToConversationsTab() throws -> ConversationsPage {
        conversationsTab.tap()
        return try ConversationsPage()
    }
}

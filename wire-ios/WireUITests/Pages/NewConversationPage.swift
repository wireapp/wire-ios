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

class NewConversationPage: PageModel {

    override var pageMainElement: XCUIElement {
        newGroupButton
    }

    var newGroupButton: XCUIElement {
        app.descendants(matching: .any)[Locators.NewConversationPage.createNewGroupButton.rawValue].firstMatch
    }

    func tapNewGroupButton() throws -> CreateGroupPage {
        newGroupButton.tap()
        return try CreateGroupPage()
    }

    var searchByNameOrUsernameSearchBox: XCUIElement {
        app.descendants(matching: .any)[Locators.NewConversationPage.searchByNameOrUsername.rawValue].firstMatch
    }

    var cancelButtonOnSearchedUserPage: XCUIElement {
        app.buttons[Locators.NewConversationPage.cancelUserSearch.rawValue]
    }

    var cancelButtonOnNewConversation: XCUIElement {
        app.buttons[Locators.NewConversationPage.cancel.rawValue]
    }

    func tapSearchBox() -> NewConversationPage {
        searchByNameOrUsernameSearchBox.tap()
        return self
    }

    var searchedUserCell: XCUIElement {
        app.descendants(matching: .any)[Locators.NewConversationPage.usernameCell.rawValue].firstMatch
    }

    func searchUserByUserHandle(_ handle: String) throws -> NewConversationPage {
        try searchByNameOrUsernameSearchBox.tapIfKeyboardNotFocused().typeText(handle)
        return self
    }

    func tapSearchedUserCell() throws -> UserDetailsPage {
        searchedUserCell.tap()
        return try UserDetailsPage()
    }

    func closeNewConversationPage() throws -> ConversationsPage {
        cancelButtonOnSearchedUserPage.tap()
        cancelButtonOnNewConversation.tap()
        return try ConversationsPage()
    }
}

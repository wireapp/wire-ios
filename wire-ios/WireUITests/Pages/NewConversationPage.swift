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

    var newChannelButton: XCUIElement {
        app.descendants(matching: .any)[Locators.NewConversationPage.createNewChannelButton.rawValue].firstMatch
    }

    func tapNewGroupButton() throws -> CreateGroupPage {
        newGroupButton.tap()
        return try CreateGroupPage()
    }

    func tapNewChannelButton() throws -> CreateChannelPage {
        newChannelButton.tap()
        return try CreateChannelPage()
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

    var userCellInContactList: XCUIElement {
        app.descendants(matching: .any)[Locators.NewConversationPage.userCellInContactList.rawValue].firstMatch
    }

    func tapSearchBox() -> NewConversationPage {
        searchByNameOrUsernameSearchBox.tap()
        return self
    }

    var searchedUserCell: XCUIElement {
        app.descendants(matching: .any)[Locators.NewConversationPage.usernameCell.rawValue].firstMatch
    }

    func searchedUserCell(handle: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: Locators.NewConversationPage.usernameCell.rawValue)
            .matching(NSPredicate(format: "label CONTAINS %@", handle))
            .firstMatch
    }

    func tapSearchedUserCell(handle: String) throws -> UserDetailsPage {
        searchedUserCell(handle: handle).waitAndTap()
        return try UserDetailsPage()
    }

    func searchUserByUserHandle(_ handle: String) throws -> NewConversationPage {
        try searchByNameOrUsernameSearchBox.tapIfKeyboardNotFocused().typeText(handle)
        return self
    }

    func tapSearchedUserCell() throws -> UserDetailsPage {
        searchedUserCell.tap()
        return try UserDetailsPage()
    }

    @discardableResult
    func closeNewConversationPage() throws -> ConversationsPage {
        cancelButtonOnSearchedUserPage.tap()
        cancelButtonOnNewConversation.tap()
        return try ConversationsPage()
    }

    func searchResult(named name: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: Locators.NewConversationPage.userCellInContactList.rawValue)
            .matching(NSPredicate(format: "label CONTAINS %@", name))
            .firstMatch
    }

    @discardableResult
    func verifySearchResultWithoutPendingBadge(named name: String) -> Self {
        let result = searchResult(named: name)
        XCTAssertTrue(result.waitForExistence(timeout: 15), "Teammate was not found in search results")
        XCTAssertFalse(result.label.localizedCaseInsensitiveContains("Onboarding pending"))
        XCTAssertFalse(
            result.descendants(matching: .any)
                .matching(NSPredicate(format: "label ==[c] %@", "Onboarding pending"))
                .firstMatch.exists,
            "Search results must not display an onboarding-pending badge"
        )
        return self
    }

    func openSearchResult(named name: String) throws -> UserDetailsPage {
        XCTAssertTrue(searchResult(named: name).waitAndTap(), "Could not open the teammate's search result")
        return try UserDetailsPage()
    }

    func openUserDetailsInContactList() throws -> UserDetailsPage {
        userCellInContactList.tap()
        return try UserDetailsPage()

    }
}

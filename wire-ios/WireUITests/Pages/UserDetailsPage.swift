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

class UserDetailsPage: PageModel {

    override var pageMainElement: XCUIElement {
        nameInfo
    }

    var nameInfo: XCUIElement {
        app.descendants(matching: .any)[Locators.UserProfilePage.name.rawValue].firstMatch
    }

    var userNameInfo: XCUIElement {
        app.descendants(matching: .any).matching(identifier: Locators.UserProfilePage.username.rawValue).firstMatch
    }

    var closeProfileButton: XCUIElement {
        app.buttons[Locators.UserDetailsPage.close.rawValue].firstMatch
    }

    var connectButton: XCUIElement {
        app.buttons[Locators.UserDetailsPage.connectLeftButton.rawValue]
    }

    var moreActionsButton: XCUIElement {
        app.buttons[Locators.UserDetailsPage.moreOptionRightButton.rawValue]
    }

    var removeFromConversationButton: XCUIElement {
        app.buttons[Locators.UserDetailsPage.removeFromConversation.rawValue]
    }

    var removeUserFromConversationConfirmation: XCUIElement {
        app.buttons[Locators.UserDetailsPage.removeUserFromConversationConfirmation.rawValue].firstMatch
    }

    var groupAdminToggle: XCUIElement {
        app.switches[Locators.UserDetailsPage.groupAdminToggle.rawValue].firstMatch
    }

    var backToConversationDetailsButton: XCUIElement {
        app.navigationBars.buttons.element(boundBy: 0)
    }

    func getUserName() -> String? {
        userNameInfo.value as? String
    }

    func sendConnectionRequest() -> UserDetailsPage {
        connectButton.tap()
        return self
    }

    func closeProfilePage() throws -> NewConversationPage {
        closeProfileButton.tap()
        return try NewConversationPage()
    }

    func goBackToConversationDetailsPage() throws -> ConversationDetailsPage {
        backToConversationDetailsButton.waitAndTap()
        return try ConversationDetailsPage()
    }

    @discardableResult
    func enableGroupAdmin() -> Self {
        if (groupAdminToggle.value as? String) != "1" {
            groupAdminToggle.waitAndTap()
        }

        return self
    }

    func removeParticipantFromConversation() throws -> ConversationDetailsPage {
        moreActionsButton.tap()
        removeFromConversationButton.tap()
        let confirmButton = removeUserFromConversationConfirmation
        XCTAssertTrue(
            confirmButton.waitForExistence(timeout: 2),
            "Confirm Remove From Conversation button did not appear in time"
        )
        confirmButton.tap()
        return try ConversationDetailsPage()
    }

    func tapStartConversationButton() throws -> ActiveConversationPage {
        connectButton.tap()
        return try ActiveConversationPage()
    }

    func tapConnect() throws -> Self {
        connectButton.tap()
        return self
    }

}

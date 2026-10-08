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

class AdminSelectionPage: PageModel {

    override var pageMainElement: XCUIElement {
        app.buttons[Locators.AdminSelectionPage.promoteButton.rawValue].firstMatch
    }

    @discardableResult
    func selectUser(named name: String) -> Self {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        app.staticTexts
            .matching(identifier: Locators.AdminSelectionPage.userCell.rawValue)
            .matching(predicate)
            .firstMatch
            .tap()
        return self
    }

    @discardableResult
    func tapPromote() throws -> ConversationDetailsPage {
        app.buttons[Locators.AdminSelectionPage.promoteButton.rawValue].firstMatch.tap()
        return try ConversationDetailsPage()
    }
}

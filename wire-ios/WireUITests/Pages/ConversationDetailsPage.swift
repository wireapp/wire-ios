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

import WireFoundation
import XCTest

class ConversationDetailsPage: PageModel {

    override var pageMainElement: XCUIElement {
        addParticipantsButton
    }

    var addParticipantsButton: XCUIElement {
        let elementsQuery = app.descendants(matching: .any).matching(identifier: Locators.Buttons.addParticipants)
        return elementsQuery.firstMatch
    }

    var closeConversationDetailsButton: XCUIElement {
        app.buttons[Locators.Buttons.closeDetails]
    }

    var userCells: XCUIElementQuery {
        app.staticTexts.matching(identifier: Locators.StaticTexts.userCell)
    }

    func openUserDetailsPage(byName name: String) throws -> UserDetailsPage {
        let predicate = NSPredicate(format: "label == %@", name)
        userCells.matching(predicate).firstMatch.tap()
        return try UserDetailsPage()
    }

    func closeConversationDetails() throws -> ActiveConversationPage {
        closeConversationDetailsButton.tap()
        return try ActiveConversationPage()
    }

    func appParticipantToConversation() throws -> SelectParticipantsPage {
        addParticipantsButton.tap()
        return try SelectParticipantsPage()
    }

}

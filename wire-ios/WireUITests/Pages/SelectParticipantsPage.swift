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

class SelectParticipantsPage: PageModel {

    override var pageMainElement: XCUIElement {
        searchByName
    }

    var searchByName: XCUIElement {
        app.descendants(matching: .any)[Locators.SelectParticipantsPage.searchByNameOrUsername.rawValue].firstMatch
    }

    var doneButton: XCUIElement {
        app.descendants(matching: .any)[Locators.SelectParticipantsPage.done.rawValue].firstMatch
    }

    var addParticipantsButton: XCUIElement {
        app.descendants(matching: .any)[Locators.ConversationDetailsPage.addParticipantsButton.rawValue].firstMatch
    }

    func tapMemberCells(withLabelPrefixes prefixes: [String]) -> SelectParticipantsPage {
        for prefix in prefixes {
            let matchingCell = app.cells.element(matching: NSPredicate(format: "label BEGINSWITH %@", prefix))
            matchingCell.tap()
        }
        return self
    }

    func doneSelectingMembers() throws -> ActiveConversationPage {
        doneButton.tap()
        return try ActiveConversationPage()
    }

    func addSelectedParticipant() throws -> ActiveConversationPage {
        addParticipantsButton.tap()
        return try ActiveConversationPage()
    }
}

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

class ConversationDetailsPage: PageModel {

    override var pageMainElement: XCUIElement {
        addParticipantsButton
    }

    var addParticipantsButton: XCUIElement {
        app.descendants(matching: .button)[Locators.ConversationDetailsPage.addParticipantsButton.rawValue].firstMatch
    }

    var closeConversationDetailsButton: XCUIElement {
        app.buttons[Locators.ConversationDetailsPage.close.rawValue]
    }

    var moreOptionsConversationDetailsButton: XCUIElement {
        app.buttons[Locators.ConversationDetailsPage.moreOptionsButton.rawValue]
    }

    var archiveOptionConversationDetailsButton: XCUIElement {
        app.buttons.matching(identifier: "archive").element(boundBy: 0)
    }

    var userCells: XCUIElementQuery {
        app.staticTexts.matching(identifier: Locators.ConversationDetailsPage.userCellName.rawValue)
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

    func moreOptionsConversationDetails() throws -> ConversationDetailsPage {
        moreOptionsConversationDetailsButton.tap()
        return try ConversationDetailsPage()
    }

    func archiveOptionsConversationDetails() throws -> ConversationsPage {
        archiveOptionConversationDetailsButton.tap()
        return try ConversationsPage()
    }

    func appParticipantToConversation() throws -> SelectParticipantsPage {
        addParticipantsButton.tap()
        return try SelectParticipantsPage()
    }

}

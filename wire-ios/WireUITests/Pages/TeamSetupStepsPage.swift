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

/// Some steps followed while setting up team i.e name, disclaimers etc
class TeamSetupStepsPage: PageModel {

    override var pageMainElement: XCUIElement {
        continueButton
    }

    var teamNameTextField: XCUIElement {
        app.descendants(matching: .textField)[Locators.TeamSetupStepsPage.teamNameTextField.rawValue].firstMatch
    }

    var continueButton: XCUIElement {
        app.descendants(matching: .any)[Locators.TeamSetupStepsPage.continueButton.rawValue].firstMatch
    }

    var checkbox: XCUIElement {
        app.descendants(matching: .any)[Locators.TeamSetupStepsPage.checkbox.rawValue].firstMatch
    }

    var checkboxes: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: Locators.TeamSetupStepsPage.checkbox.rawValue)
    }

    var firstCheckbox: XCUIElement { checkboxes.element(boundBy: 0) }
    var secondCheckbox: XCUIElement { checkboxes.element(boundBy: 1) }

    var backToWireButton: XCUIElement {
        app.descendants(matching: .any)[Locators.TeamSetupStepsPage.backToWireButton.rawValue].firstMatch
    }

    func tapContinue() throws -> TeamSetupStepsPage {
        continueButton.tap()
        return try TeamSetupStepsPage()
    }

    func typeTeamNameAndContinue(_ input: String) throws -> TeamSetupStepsPage {
        try teamNameTextField.tapIfKeyboardNotFocused().typeText(input)
        continueButton.tap()
        return self
    }

    func acceptTheConfirmationAndContinue() -> TeamSetupStepsPage {
        firstCheckbox.tap()
        secondCheckbox.tap()
        continueButton.tap()
        return self
    }

    func tapBackToWireButton() throws -> ConversationsPage {
        backToWireButton.tap()
        return try ConversationsPage()
    }
}

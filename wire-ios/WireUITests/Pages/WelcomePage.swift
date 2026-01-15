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

class WelcomePage: PageModel {

    override var pageMainElement: XCUIElement {
        emailTextField
    }

    var nextButton: XCUIElement {
        app.descendants(matching: .any)[Locators.WelcomePage.nextButton.rawValue].firstMatch
    }

    var emailTextField: XCUIElement {
        app.textFields[Locators.WelcomePage.emailTextField.rawValue]
    }

    var setBackendLabel: XCUIElement {
        app.descendants(matching: .any)[Locators.WelcomePage.onPremInfoButton.rawValue]
    }

    func enterEmailOrSSO(_ input: String) throws -> LoginPage {
        try typeEmailOrSSO(input)
        nextButton.waitAndTap()
        return try LoginPage()
    }

    @discardableResult
    func typeEmailOrSSO(_ input: String) throws -> WelcomePage {
        try emailTextField.tapIfKeyboardNotFocused().typeText(input)
        return self
    }
}

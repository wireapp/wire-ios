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

import WireLocators
import XCTest

class LoginPage: PageModel {

    override var pageMainElement: XCUIElement {
        createPersonalAccountLink
    }

    var createPersonalAccountLink: XCUIElement {
        let elementsQuery = app.scrollViews.otherElements
        return elementsQuery.buttons[Locators.LoginPage.createAccountLink.rawValue]
    }

    var nextButton: XCUIElement {
        app.descendants(matching: .any)[Locators.WelcomePage.nextButton.rawValue].firstMatch
    }

    var emailField: XCUIElement {
        app.textFields[Locators.LoginPage.emailTextField.rawValue]
    }

    var passwordField: XCUIElement {
        app.secureTextFields[Locators.LoginPage.passwordSecureTextField.rawValue]
    }

    func tapCreatePersonalAccountLink() throws -> CreatePersonalAccountFormPage {
        createPersonalAccountLink.tap()
        return try CreatePersonalAccountFormPage()
    }

    func enterPassword(_ password: String) throws -> FirstTimePage {
        try passwordField.tapIfKeyboardNotFocused().typeText(password)
        nextButton.tap()
        return try FirstTimePage()
    }
}

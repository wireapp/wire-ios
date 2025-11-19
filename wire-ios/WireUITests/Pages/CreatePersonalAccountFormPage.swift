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

import XCTest
import WireLocators

class CreatePersonalAccountFormPage: PageModel {

    override var pageMainElement: XCUIElement {
        nameTextField
    }

    var nameTextField: XCUIElement {
        app.descendants(matching: .textField)[Locators.CreatePersonalAccountFormPage.enterNameField.rawValue].firstMatch
    }

    var passwordField: XCUIElement {
        app.descendants(matching: .textField)[Locators.CreatePersonalAccountFormPage.enterPasswordField.rawValue].firstMatch
    }

    var confirmPasswordField: XCUIElement {
        app.descendants(matching: .textField)[Locators.CreatePersonalAccountFormPage.enterConfirmPasswordField.rawValue].firstMatch
    }

    var showPasswordIcon: XCUIElement {
        app.descendants(matching: .button)[Locators.CreatePersonalAccountFormPage.enterPasswordField.rawValue].firstMatch
    }
    
    var showConfirmPasswordIcon: XCUIElement {
        app.descendants(matching: .button)[Locators.CreatePersonalAccountFormPage.enterConfirmPasswordField.rawValue].firstMatch
    }

    var continueButton: XCUIElement {
        app.descendants(matching: .button)[Locators.CreatePersonalAccountFormPage.continueButton.rawValue].firstMatch
    }

    var acceptButton: XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons[Locators.CreatePersonalAccountFormPage.acceptTermsOfUse.rawValue]
    }

    func enterName(_ name: String) throws -> CreatePersonalAccountFormPage {
        try nameTextField.tapIfKeyboardNotFocused().typeText(name)
        return self
    }

    func enterPassword(_ password: String) throws -> CreatePersonalAccountFormPage {
        showPasswordIcon.tap()
        try passwordField.tapIfKeyboardNotFocused()
        passwordField.typeText(password)
        return self
    }

    func enterConfirmPassword(_ confirmPassword: String) throws -> CreatePersonalAccountFormPage {
        showConfirmPasswordIcon.tap()
        try confirmPasswordField.tapIfKeyboardNotFocused()
        confirmPasswordField.typeText(confirmPassword)
        return self
    }

    func tapContinueButton() throws -> CreatePersonalAccountFormPage {
        continueButton.tap()
        return self
    }

    func tapAcceptButton() throws -> VerificationCodePage {
        _ = acceptButton.waitForExistence(timeout: 10)
        acceptButton.tap()
        return try VerificationCodePage()
    }
}

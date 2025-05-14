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

class RegistrationPage: PageModel {

    override func hasLoaded() {
        let expectation = confirmButton.waitForExistence(timeout: 10)
        XCTAssert(expectation, "Registration page not loaded - can't find next button")
    }

    var nameNextButton: XCUIElement {
        let elementsQuery = nameField.buttons.matching(identifier: "ConfirmButton")
        return elementsQuery.firstMatch
    }

    var passwordNextButton: XCUIElement {
        let elementsQuery = passwordField.buttons.matching(identifier: "RevealButton")
        return elementsQuery.firstMatch
    }

    var nameField: XCUIElement {
        let elementsQuery = app.otherElements.textFields.matching(identifier: "NameField")
        return elementsQuery.firstMatch
    }

    var passwordField: XCUIElement {
        let elementsQuery = app.otherElements.secureTextFields.matching(identifier: "PasswordField")
        return elementsQuery.firstMatch
    }

    var usernameField: XCUIElement {
        let elementsQuery = app.textFields.matching(identifier: "UsernameField")
        return elementsQuery.firstMatch
    }

    var usernameConfirmButton: XCUIElement {
        let elementsQuery = usernameField.buttons
        return elementsQuery.firstMatch
    }

    var confirmButton: XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons["ConfirmButton"]
    }

    var acceptButton: XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons["Accept"]
    }

    var verificationCodeInput: XCUIElement {
        let elementsQuery = app.textViews.matching(identifier: "VerificationCode")
        return elementsQuery.firstMatch
    }

    func tapAcceptButton() -> RegistrationPage {
        acceptButton.waitForExistence(timeout: 10)
        acceptButton.tap()
        return self
    }

    func acceptPopup() -> RegistrationPage {
        let button = app.otherElements.buttons.firstMatch
        button.tap()
        return self
    }

    func tapConfirmCreateAccount() -> RegistrationPage {
        confirmButton.waitForExistence(timeout: 1)
        confirmButton.tap()
        return self
    }

    func enterVerificationCode(_ verificationCode: String) -> RegistrationPage {
        verificationCodeInput.tap()
        verificationCodeInput.typeText(verificationCode)
        return self
    }

    func setName(_ name: String) -> RegistrationPage {
        nameField.tap()
        nameField.typeText(name)
        nameNextButton.tap()
        return self
    }

    func setPassword(_ password: String) -> RegistrationPage {
        passwordField.tap()
        passwordField.typeText(password)
        passwordNextButton.tap()
        return self
    }

    func setUsername(_ username: String) -> ConversationsPage {
        usernameField.tap()
        usernameField.typeText(username)
        usernameConfirmButton.tap()
        return ConversationsPage()
    }
}

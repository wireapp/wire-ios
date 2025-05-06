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

    func nameNextButton() -> XCUIElement {
        let elementsQuery = nameField().buttons.matching(identifier: "ConfirmButton")
        return elementsQuery.firstMatch
    }

    func passwordNextButton() -> XCUIElement {
        let elementsQuery = passwordField().buttons.matching(identifier: "RevealButton")
        return elementsQuery.firstMatch
    }

    func nameField() -> XCUIElement {
        let elementsQuery = app.otherElements.textFields.matching(identifier: "NameField")
        return elementsQuery.firstMatch
    }

    func passwordField() -> XCUIElement {
        let elementsQuery = app.otherElements.secureTextFields.matching(identifier: "PasswordField")
        return elementsQuery.firstMatch
    }

    func usernameField() -> XCUIElement {
        let elementsQuery = app.textFields.matching(identifier: "UsernameField")
        return elementsQuery.firstMatch
    }

    func usernameConfirmButton() -> XCUIElement {
        let elementsQuery = usernameField().buttons
        return elementsQuery.firstMatch
    }

    func newNextButton() -> XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons["ConfirmButton"]
    }

    func acceptButton() -> XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons["Accept"]
    }

    func verificationCodeInput() -> XCUIElement {
        let elementsQuery = app.textViews.matching(identifier: "VerificationCode")
        return elementsQuery.firstMatch
    }

    func enterVerificationCode(verificationCode: String) -> RegistrationPage {
        let input = verificationCodeInput()
        input.tap()
        input.typeText(verificationCode)
        return self
    }

    func setName(name: String) -> RegistrationPage {
        let nameInput = nameField()
        nameInput.tap()
        nameInput.typeText("Smoke Tester")
        nameNextButton().tap()
        return self
    }

    func setPassword(password: String) -> RegistrationPage {
        let passwordInput = passwordField()
        passwordInput.tap()
        passwordInput.typeText(password)
        passwordNextButton().tap()
        return self
    }

    func setUsername(username: String) -> ConversationsPage {
        let usernameInput = usernameField()
        usernameInput.tap()
        usernameInput.typeText(username)
        usernameConfirmButton().tap()
        return ConversationsPage(theApp: app)
    }

    func confirmCreateAccount() -> RegistrationPage {
        let confirmButton = newNextButton()
        confirmButton.waitForExistence(timeout: 1)
        confirmButton.tap()
        return self
    }
}

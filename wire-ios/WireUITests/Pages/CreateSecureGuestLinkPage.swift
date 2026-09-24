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

class CreateSecureGuestLinkPage: PageModel {

    override var pageMainElement: XCUIElement {
        generatePasswordButton
    }

    var generatePasswordButton: XCUIElement {
        app.buttons[Locators.CreateSecureGuestLinkPage.generatePasswordButton.rawValue].firstMatch
    }

    var passwordTextField: XCUIElement {
        app.secureTextFields[Locators.CreateSecureGuestLinkPage.passwordTextField.rawValue].firstMatch
    }

    var confirmPasswordTextField: XCUIElement {
        app.secureTextFields[Locators.CreateSecureGuestLinkPage.confirmPasswordTextField.rawValue].firstMatch
    }

    var createLinkButton: XCUIElement {
        app.buttons[Locators.CreateSecureGuestLinkPage.createLinkButton.rawValue].firstMatch
    }

    var passwordCopiedAlert: XCUIElement {
        app.alerts.firstMatch
    }

    @discardableResult
    func generatePassword() -> Self {
        generatePasswordButton.waitAndTap()
        return self
    }

    func createLink() throws -> GuestOptionsPage {
        createLinkButton.waitAndTap()
        passwordCopiedAlert.buttons.firstMatch.waitAndTap()
        return try GuestOptionsPage()
    }
}

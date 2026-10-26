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

class SSOWebLoginPage: PageModel {

    override var pageMainElement: XCUIElement {
        usernameLabel
    }

    private var webView: XCUIElement {
        app.webViews.firstMatch
    }

    private var usernameLabel: XCUIElement {
        app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", Locators.SSOWebLoginPage.username.rawValue))
            .firstMatch
    }

    var usernameTextField: XCUIElement {
        app.textFields.firstMatch
    }

    var passwordSecureTextField: XCUIElement {
        app.secureTextFields.firstMatch
    }

    var signinButton: XCUIElement {
        app.buttons[Locators.SSOWebLoginPage.signInButton.rawValue].firstMatch
    }

    @MainActor
    @discardableResult
    func ssoWebLogin(email: String, password: String) async throws -> FirstTimePage {
        usernameTextField.waitAndTap()
        usernameTextField.typeText(email)
        webView.tap()

        passwordSecureTextField.waitAndTap()
        passwordSecureTextField.typeText(password + "\n")

        if !webView.waitForNonExistence(timeout: 4),
           signinButton.exists,
           signinButton.isHittable {
            signinButton.tap()
        }

        return try FirstTimePage()
    }
}

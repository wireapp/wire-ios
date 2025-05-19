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

class WelcomePage: PageModel {

    override func hasLoaded() {
        let expectation = emailTextField.waitForExistence(timeout: 10)
        XCTAssert(expectation, "Welcome page not loaded - can't find email or SSO field")
    }

    var nextButton: XCUIElement {
        let elementsQuery = app.scrollViews.otherElements
        return elementsQuery.buttons["Next"]
    }

    var emailTextField: XCUIElement {
        let elementsQuery = app.textFields
        return elementsQuery["Email or SSO code"]
    }

    func enterEmailOrSSO(_ input: String) -> LoginPage {
        emailTextField.tap()
        emailTextField.typeText(input)
        nextButton.tap()
        return LoginPage()
    }
    
    func typeEmailOrSSO(_ input: String) -> WelcomePage {
        emailTextField.tap()
        emailTextField.typeText(input)
        return self
    }
}

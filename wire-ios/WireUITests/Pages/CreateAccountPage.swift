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

class CreateAccountPage: PageModel {

    override func hasLoaded() {
        let expectation = confirmButton.waitForExistence(timeout: 10)
        XCTAssert(expectation, "Registration page not loaded - can't find next button")
    }

    var confirmButton: XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons["ConfirmButton"]
    }

    var acceptButton: XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons["Accept"]
    }

    func tapConfirmCreateAccount() -> CreateAccountPage {
        _ = confirmButton.waitForExistence(timeout: 1)
        confirmButton.tap()
        return self
    }

    func tapAcceptButton() -> VerificationCodePage {
        _ = acceptButton.waitForExistence(timeout: 10)
        acceptButton.tap()
        return VerificationCodePage()
    }
}

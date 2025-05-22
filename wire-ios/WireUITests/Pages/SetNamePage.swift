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

class SetNamePage: PageModel {

    override func hasLoaded() {
        let expectation = nameField.waitForExistence(timeout: 10)
        XCTAssert(expectation, "Registration page not loaded - can't find next button")
    }

    var nameNextButton: XCUIElement {
        let elementsQuery = nameField.buttons.matching(identifier: "ConfirmButton")
        return elementsQuery.firstMatch
    }

    var nameField: XCUIElement {
        let elementsQuery = app.otherElements.textFields.matching(identifier: "NameField")
        return elementsQuery.firstMatch
    }

    func setName(_ name: String) -> SetPasswordPage {
        nameField.tap()
        nameField.typeText(name)
        nameNextButton.tap()
        return SetPasswordPage()
    }
}

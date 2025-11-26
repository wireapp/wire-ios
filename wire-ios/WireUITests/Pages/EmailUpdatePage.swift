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

class EmailUpdatePage: PageModel {

    override var pageMainElement: XCUIElement {
        emailField
    }

    var emailField: XCUIElement {
        app.descendants(matching: .any)[Locators.EmailUpdatePage.emailField.rawValue].firstMatch
    }

    var saveButton: XCUIElement {
        app.buttons[Locators.EmailUpdatePage.save.rawValue]
    }

    func clearTextField(_ textfield: XCUIElement) {
        textfield.doubleTap()
        textfield.typeText("\u{8}")
    }

    func updateEmailAndSave(with newEmail: String) throws -> VerifyEmailPage {
        clearTextField(emailField)
        emailField.typeText(newEmail)
        saveButton.tap()
        return try VerifyEmailPage()
    }

}

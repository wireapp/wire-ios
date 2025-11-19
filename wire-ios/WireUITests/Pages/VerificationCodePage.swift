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

class VerificationCodePage: PageModel {

    override var pageMainElement: XCUIElement {
        verificationCodeInput
    }

    var verificationCodeInput: XCUIElement {
        let elementsQuery = app.descendants(matching: .any).matching(identifier: Locators.VerificationCodePage.verificationCodeTextField.rawValue)
        return elementsQuery.firstMatch
    }

    var verificationCodeConfirmButton: XCUIElement {
        let elementsQuery = app.descendants(matching: .any)[Locators.VerificationCodePage.confirmButton.rawValue]
        return elementsQuery.firstMatch
    }

    func enterVerificationCodeAndConfirm(_ verificationCode: String) throws -> SetUsernamePage {
        let element = app.textFields
        for (index, digit) in verificationCode.enumerated() {
            try element.element(boundBy: index).tapIfKeyboardNotFocused().typeText(String(digit))
        }
        verificationCodeConfirmButton.tap()
        return try SetUsernamePage()
    }

}

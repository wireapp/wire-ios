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

class SetPasscodePage: PageModel {

    override var pageMainElement: XCUIElement {
        passwordField
    }

    var passwordField: XCUIElement {
        app.secureTextFields[Locators.SetPasscodePage.passcodeField.rawValue]
    }

    var setPasscodeButton: XCUIElement {
        app.buttons[Locators.SetPasscodePage.createPasscodeButton.rawValue]
    }

    func SetPasscode(_ pass: String) throws -> OptionsOnSettingsPage {
        try passwordField.tapIfKeyboardNotFocused().typeText(pass)
        setPasscodeButton.tap()
        return try OptionsOnSettingsPage()
    }

}

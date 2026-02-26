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

class OptionsOnSettingsPage: PageModel {

    override var pageMainElement: XCUIElement {
        lockWithPasscodeSwitch
    }

    var lockWithPasscodeSwitch: XCUIElement {
        app.descendants(matching: .any)[Locators.OptionsOnSettingsPage.lockWithPasscode.rawValue].firstMatch
    }

    var conversationsButton: XCUIElement {
        app.buttons[Locators.ConversationsPage.bottomBarRecentListButton.rawValue]
    }

    func enableLockWithPasscode() throws -> SetPasscodePage {
        lockWithPasscodeSwitch.tap()
        return try SetPasscodePage()
    }

    @discardableResult
    func backgroundAndResume(
        app: XCUIApplication,
        forDelay duration: TimeInterval
    ) async throws -> OptionsOnSettingsPage {
        await XCUIDevice.shared.press(.home)
        try await Task.sleep(for: .seconds(duration))
        await app.activate()
        return self
    }

    func enterPasscode(_ passcode: String) throws -> ConversationsPage {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let passcodeField = springboard.secureTextFields["Passcode field"].firstMatch

        guard passcodeField.waitAndTap(timeout: 10)
        else {
            XCTFail("Passcode SecureTextField did not appear")
            throw XCTSkip("Passcode field not available")
        }
        try passcodeField.tapIfKeyboardNotFocused().typeText(passcode)

        let doneButton = springboard.keyboards.buttons["Done"].firstMatch
        if doneButton.waitAndTap() {
            // Tapped successfully
        } else {
            springboard.typeText(XCUIKeyboardKey.return.rawValue)
        }
        return try ConversationsPage()
    }
}

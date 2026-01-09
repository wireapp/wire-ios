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

    func enterPasscode(_ pass: String) throws -> ConversationsPage {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        try springboard.secureTextFields["Passcode field"].tapIfKeyboardNotFocused().typeText(pass)

        let doneButton = springboard.keyboards.buttons["Done"].firstMatch
        if doneButton.waitForExistence(timeout: 2.0), doneButton.isHittable {
            doneButton.tap()
        } else {
            springboard.typeText(XCUIKeyboardKey.return.rawValue)
        }
        return try ConversationsPage()
    }
}

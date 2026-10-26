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

    var backToPreviousPage: XCUIElement {
        app.navigationBars.buttons.element(boundBy: 0)
    }

    var lockWithPasscodeSwitch: XCUIElement {
        app.descendants(matching: .any)[Locators.OptionsOnSettingsPage.lockWithPasscode.rawValue].firstMatch
    }

    var createLinkPreviewsSwitch: XCUIElement {
        app.descendants(matching: .any)[Locators.OptionsOnSettingsPage.createLinkPreviews.rawValue].firstMatch
    }

    var themeButton: XCUIElement {
        app.descendants(matching: .any)[Locators.OptionsOnSettingsPage.theme.rawValue].firstMatch
    }

    var themeCell: XCUIElement {
        app.descendants(matching: .any)[Locators.OptionsOnSettingsPage.themeCell.rawValue].firstMatch
    }

    var conversationsButton: XCUIElement {
        app.buttons[Locators.ConversationsPage.bottomBarRecentListButton.rawValue]
    }

    func enableLockWithPasscode() throws -> SetPasscodePage {
        lockWithPasscodeSwitch.tap()
        return try SetPasscodePage()
    }

    func openThemeSettings() throws -> ThemeSettingsPage {
        themeButton.tap()
        return try ThemeSettingsPage()
    }

    @discardableResult
    func verifyTheme(
        _ theme: ThemeSettingsPage.Theme,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OptionsOnSettingsPage {
        let themeValues = (themeCell.value as? String)?.components(separatedBy: "|")
        let actualTheme = themeValues?.first
        let expectedTheme = theme.rawValue

        XCTAssertEqual(
            actualTheme,
            expectedTheme,
            "Theme setting should be \(expectedTheme)",
            file: file,
            line: line
        )

        if theme != .system {
            let appliedTheme = themeValues?.count == 2 ? themeValues?.last : nil
            XCTAssertEqual(
                appliedTheme,
                theme.rawValue,
                "Applied theme should be \(theme.rawValue)",
                file: file,
                line: line
            )
        }
        return self
    }

    func enterPasscode(_ passcode: String) throws -> OptionsOnSettingsPage {
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
        return try OptionsOnSettingsPage()
    }

    func enableCreateLinkPreviews(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> OptionsOnSettingsPage {
        createLinkPreviewsSwitch.tap()
        XCTAssertTrue(
            createLinkPreviewsSwitch.value as? String == "1",
            "Create link previews should be enabled",
            file: file,
            line: line
        )
        return self
    }

    func disableCreateLinkPreviews(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> OptionsOnSettingsPage {
        createLinkPreviewsSwitch.tap()
        XCTAssertTrue(
            createLinkPreviewsSwitch.value as? String == "0",
            "Create link previews should be disabled",
            file: file,
            line: line
        )
        return self
    }

    func backToSettings() throws -> SettingsPage {
        backToPreviousPage.tap()
        return try SettingsPage()
    }

}

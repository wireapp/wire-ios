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

class ThemeSettingsPage: PageModel {

    enum Theme {
        case light
        case dark
        case system

        var displayName: String {
            switch self {
            case .light:
                "Light"
            case .dark:
                "Dark"
            case .system:
                "Sync with system settings"
            }
        }

        var locator: Locators.ThemeSettingsPage {
            switch self {
            case .light:
                .lightOption
            case .dark:
                .darkOption
            case .system:
                .systemOption
            }
        }
    }

    override var pageMainElement: XCUIElement {
        optionLabel(.light)
    }

    var backToPreviousPage: XCUIElement {
        app.navigationBars.buttons.element(boundBy: 0)
    }

    func option(_ theme: Theme) -> XCUIElement {
        app.descendants(matching: .any)[theme.locator.rawValue].firstMatch
    }

    func optionLabel(_ theme: Theme) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", theme.displayName))
            .firstMatch
    }

    func selectTheme(_ theme: Theme) throws -> ThemeSettingsPage {
        var themeOption = option(theme)
        if !themeOption.waitForExistence(timeout: 2) {
            themeOption = optionLabel(theme)
        }
        if !themeOption.waitForExistence(timeout: 2) {
            app.swipeUp()
            themeOption = option(theme)
        }
        if !themeOption.waitForExistence(timeout: 2) {
            themeOption = optionLabel(theme)
        }

        XCTAssertTrue(
            themeOption.waitForExistence(timeout: 5),
            "\(theme.displayName) option did not appear"
        )
        themeOption.tap()
        return self
    }

    func backToOptions() throws -> OptionsOnSettingsPage {
        backToPreviousPage.tap()
        return try OptionsOnSettingsPage()
    }
}

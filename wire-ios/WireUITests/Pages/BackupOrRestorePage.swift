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

class BackupOrRestorePage: PageModel {

    override var pageMainElement: XCUIElement {
        backupNowButton
    }

    var backupNowButton: XCUIElement {
        app.descendants(matching: .button)[Locators.BackupOrRestorePage.backUpNowButton.rawValue]
    }

    var restoreFromBackupButton: XCUIElement {
        app.descendants(matching: .button)[Locators.BackupOrRestorePage.restoreFromBackupButton.rawValue]
    }

    var backToAccountButton: XCUIElement {
        app.buttons["Account"]
    }

    var browseButtonOnBottom: XCUIElement {
        app.tabBars.buttons[Locators.BackupOrRestorePage.browse.rawValue].firstMatch
    }

    func tapBackupNow() throws -> SetPasswordPage {
        backupNowButton.tap()
        return try SetPasswordPage()
    }

    func tapRestoreFromBackupButton() throws -> OnMyiPhonePage {
        restoreFromBackupButton.tap()
        if !browseButtonOnBottom.isSelected {
            browseButtonOnBottom.tap()
        }
        return try OnMyiPhonePage()
    }

    func goBackToAccountPage() throws -> AccountSettingsPage {
        backToAccountButton.tap()
        return try AccountSettingsPage()
    }
}

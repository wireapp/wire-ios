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

class SetPasswordPage: PageModel {

    override var pageMainElement: XCUIElement {
        passwordField
    }

    var passwordField: XCUIElement {
        app.secureTextFields[Locators.SetPasswordPage.passwordInputField.rawValue]
    }

    var backupNowButton: XCUIElement {
        app.descendants(matching: .button)[Locators.SetPasswordPage.backUpNowButton.rawValue]
    }

    var continueButton: XCUIElement {
        app.buttons[Locators.SetPasswordPage.continueButton.rawValue]
    }

    var historyRestoredAlert: XCUIElement {
        app.alerts[Locators.SetPasswordPage.historyRestoredAlert.rawValue]
    }

    var OKButtonOnAlert: XCUIElement {
        app.buttons[Locators.SetPasswordPage.ok.rawValue]
    }

    func enterBackupPasswordAndBackup(_ password: String) throws -> CreatingBackupPage {
        passwordField.tap()
        passwordField.typeText(password)
        backupNowButton.tap()
        return try CreatingBackupPage()
    }

    func enterBackupPasswordAndRestore(_ password: String) throws -> SetPasswordPage {
        passwordField.tap()
        passwordField.typeText(password)
        continueButton.tap()
        return self
    }

    func acceptHistoryrestoredAlert() throws -> BackupOrRestorePage {
        OKButtonOnAlert.tap()
        return try BackupOrRestorePage()
    }
}

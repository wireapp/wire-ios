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
import WireFoundation

class AccountSettingsPage: PageModel {

    override var pageMainElement: XCUIElement {
        nameField
    }

    var nameField: XCUIElement {
        app.textFields[Locators.TextFields.nameFieldValue]
    }

    var usernameField: XCUIElement {
        app.staticTexts[Locators.StaticTexts.usernameFieldValue]
    }

    var emailField: XCUIElement {
        app.staticTexts[Locators.StaticTexts.emailFieldValue]
    }

    var logoutButton: XCUIElement {
        app.descendants(matching: .any)[Locators.StaticTexts.logout].firstMatch
    }

    var deleteAccountButtonOnAccount: XCUIElement {
        app.descendants(matching: .any)[Locators.StaticTexts.deleteAccount].firstMatch
    }

    var oKButtonOnDeleteAccountAlert: XCUIElement {
        app.buttons[Locators.Buttons.ok]
    }

    var backupOrRestoreButton: XCUIElement {
        app.descendants(matching: .any)[Locators.StaticTexts.backUpOrRestore].firstMatch
    }

    func getAccountName() -> String? {
        nameField.value as? String
    }

    func getUsername() -> String {
        usernameField.label
    }

    func getEmail() -> String {
        emailField.label
    }

    var backToSettingsButton: XCUIElement {
        app.buttons[Locators.Buttons.settings]
    }

    @discardableResult
    func logout() throws -> LogOutPage {
        logoutButton.tap()
        return try LogOutPage()
    }

    func deleteAccount() throws -> ConversationsPage {
        deleteAccountButtonOnAccount.tap()
        oKButtonOnDeleteAccountAlert.tap()
        return try ConversationsPage()
    }

    @discardableResult
    func tapBackupOrRestore() throws -> BackupOrRestorePage {
        backupOrRestoreButton.tap()
        return try BackupOrRestorePage()
    }

    func goBackToSettingsPage() throws -> SettingsPage {
        backToSettingsButton.tap()
        return try SettingsPage()
    }
}

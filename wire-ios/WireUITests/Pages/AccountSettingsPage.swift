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

class AccountSettingsPage: PageModel {

    override var pageMainElement: XCUIElement {
        nameField
    }

    var nameField: XCUIElement {
        app.textFields[Locators.AccountSettingsPage.nameField.rawValue]
    }

    var usernameField: XCUIElement {
        app.staticTexts[Locators.AccountSettingsPage.usernameField.rawValue]
    }

    var emailField: XCUIElement {
        app.staticTexts[Locators.AccountSettingsPage.emailField.rawValue]
    }

    var domainField: XCUIElement {
        app.descendants(matching: .any)[Locators.AccountSettingsPage.domainFieldDisabled.rawValue].firstMatch
    }

    var logoutButton: XCUIElement {
        app.staticTexts[Locators.AccountSettingsPage.logOut.rawValue]
    }

    var deleteAccountButtonOnAccount: XCUIElement {
        app.descendants(matching: .any)[Locators.AccountSettingsPage.deleteAccountField.rawValue].firstMatch
    }

    var oKButtonOnDeleteAccountAlert: XCUIElement {
        app.buttons[Locators.AccountSettingsPage.ok.rawValue]
    }

    var backToPreviousPage: XCUIElement {
        app.navigationBars.buttons.element(boundBy: 0)
    }

    var backupOrRestoreButton: XCUIElement {
        app.descendants(matching: .any)[Locators.AccountSettingsPage.backuporRestoreField.rawValue].firstMatch
    }

    var resetPasswordButton: XCUIElement {
        app.descendants(matching: .any)[Locators.AccountSettingsPage.resetPasswordField.rawValue].firstMatch
    }

    func getAccountName() -> String? {
        XCTAssertTrue(
            nameField.waitForExistence(timeout: 5.0),
            "NameField should exist before reading account name"
        )
        return nameField.value as? String
    }

    func getUsername() -> String {
        usernameField.label
    }

    func getEmail() -> String {
        emailField.label
    }

    func getDomainInfo() -> String {
        domainField.value as! String
    }

    func backToSettings() throws -> SettingsPage {
        backToPreviousPage.tap()
        return try SettingsPage()
    }

    func tapEmailField() throws -> EmailUpdatePage {
        emailField.tap()
        return try EmailUpdatePage()
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
        if app.iPadOnly() {
            return try SettingsPage()
        }
        backToPreviousPage.tap()
        return try SettingsPage()
    }

    func tapOnResetPasswordButton() throws -> WebViewPage {
        resetPasswordButton.tap()
        return try WebViewPage()
    }

}

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

class AccountSettingsPage: PageModel {

    override var pageMainElement: XCUIElement {
        accountSettingsPageHeader
    }

    var accountSettingsPageHeader: XCUIElement {
        app.staticTexts["Account"]
    }

    var nameField: XCUIElement {
        app.descendants(matching: .any)["NameField"].firstMatch
    }

    var usernameField: XCUIElement {
        app.descendants(matching: .any)["UsernameField"].firstMatch
    }

    var emailField: XCUIElement {
        app.descendants(matching: .any)["EmailField"].firstMatch
    }

    var domainField: XCUIElement {
        app.descendants(matching: .any)["DomainFieldDisabled"].firstMatch
    }

    var logoutButton: XCUIElement {
        app.staticTexts["Log Out"]
    }

    var deleteAccountButtonOnAccount: XCUIElement {
        app.descendants(matching: .any)["Delete AccountField"].firstMatch
    }

    var oKButtonOnDeleteAccountAlert: XCUIElement {
        app.buttons["OK"]
    }

    var backToSettingsButton: XCUIElement {
        app.buttons["Settings"]
    }

    var backupOrRestoreButton: XCUIElement {
        app.descendants(matching: .any)["Back up or RestoreField"].firstMatch
    }

    var resetPasswordButton: XCUIElement {
        app.descendants(matching: .any)["Reset Password"].firstMatch
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

    func getDomainInfo() -> String {
        domainField.value as! String
    }

    func backToSettings() throws -> SettingsPage {
        if backToSettingsButton.exists {
            backToSettingsButton.tap()
        }
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
        if app.onPad() {
            return try SettingsPage()
        }
        backToSettingsButton.tap()
        return try SettingsPage()
    }

    func tapOnResetPasswordButton() throws -> WebViewPage {
        resetPasswordButton.tap()
        return try WebViewPage()
    }
}

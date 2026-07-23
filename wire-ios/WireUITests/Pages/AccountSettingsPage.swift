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

class AccountSettingsPage: PageModel {

    struct ProfileColor {
        static let purple = ProfileColor(displayName: "Purple", accentID: 7)

        let displayName: String
        let accentID: Int
    }

    override var pageMainElement: XCUIElement {
        accountHeader
    }

    var accountHeader: XCUIElement {
        app.navigationBars[Locators.AccountSettingsPage.accountHeader.rawValue]
    }

    var nameField: XCUIElement {
        app.textFields[Locators.AccountSettingsPage.nameField.rawValue]
    }

    var nameFieldDisabled: XCUIElement {
        app.textFields[Locators.AccountSettingsPage.nameFieldDisabled.rawValue]
    }

    var usernameField: XCUIElement {
        app.staticTexts[Locators.AccountSettingsPage.usernameField.rawValue]
    }

    var usernameFieldDisabled: XCUIElement {
        app.textFields[Locators.AccountSettingsPage.usernameFieldDisabled.rawValue]
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

    var oKButtonOnConfirmation: XCUIElement {
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

    var pictureCell: XCUIElement {
        app.descendants(matching: .any)[Locators.AccountSettingsPage.pictureCell.rawValue].firstMatch
    }

    var colorCell: XCUIElement {
        app.descendants(matching: .any)[Locators.AccountSettingsPage.colorCell.rawValue].firstMatch
    }

    var conversationBackgroundSwitch: XCUIElement {
        app.descendants(matching: .any)[Locators.AccountSettingsPage.conversationBackgroundSwitch.rawValue].firstMatch
    }

    var chooseFromLibraryButton: XCUIElement {
        app.sheets.firstMatch.buttons.element(boundBy: 0)
    }

    var confirmImageButton: XCUIElement {
        app.buttons[Locators.AccountSettingsPage.ok.rawValue].firstMatch
    }

    var photoGridImageTile: XCUIElement {
        app.images[Locators.PhotosAppPage.imageTile.rawValue].firstMatch
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

    func tapNameField() throws -> AccountSettingsPage {
        nameField.tap()
        return self
    }

    func selectProfileColor(_ color: ProfileColor) throws -> AccountSettingsPage {
        colorCell.waitAndTap()
        let colorOption = app.buttons[color.displayName].firstMatch
        XCTAssertTrue(
            colorOption.waitForExistence(timeout: 5),
            "\(color.displayName) color option did not appear"
        )
        colorOption.tap()
        XCTAssertTrue(colorOption.isSelected, "\(color.displayName) color option was not selected")
        XCTAssertTrue(backToPreviousPage.waitAndTap(), "Failed to navigate back from the color picker")
        return try AccountSettingsPage()
    }

    @discardableResult
    func enableConversationBackground(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> AccountSettingsPage {
        if conversationBackgroundSwitch.value as? String != "1" {
            conversationBackgroundSwitch.tap()
        }

        XCTAssertTrue(
            conversationBackgroundSwitch.value as? String == "1",
            "Conversation background should be enabled",
            file: file,
            line: line
        )
        return self
    }

    func setProfilePictureFromLibrary() throws -> AccountSettingsPage {
        pictureCell.waitAndTap()
        XCTAssertTrue(
            chooseFromLibraryButton.waitForExistence(timeout: 5),
            "Choose from Library did not appear"
        )
        chooseFromLibraryButton.tap()
        selectImageFromPhotoPicker()

        XCTAssertTrue(
            confirmImageButton.waitForExistence(timeout: 5),
            "Profile image confirmation did not appear"
        )
        confirmImageButton.tap()
        XCTAssertTrue(pictureCell.waitForExistence(timeout: 10), "Account settings did not reappear")
        XCTAssertTrue(
            waitForPicturePreview(timeout: 10),
            "Profile picture preview did not appear after selecting image"
        )
        return self
    }

    @discardableResult
    func verifyProfileColor(
        _ color: ProfileColor,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AccountSettingsPage {
        XCTAssertTrue(
            colorCell.waitForExistence(timeout: 5),
            "Color cell did not appear",
            file: file,
            line: line
        )
        XCTAssertEqual(
            colorCell.value as? String,
            color.displayName,
            "Profile color preview should show \(color.displayName)",
            file: file,
            line: line
        )
        return self
    }

    func hasProfilePicturePreview() -> Bool {
        pictureCell.value as? String == "image"
    }

    func tapUsernameField() throws -> UsernameUpdatePage {
        usernameField.tap()
        return try UsernameUpdatePage()
    }

    func updateName() throws -> AccountSettingsPage {
        nameField.tap()
        nameField.typeText("-updated")
        return self
    }

    @discardableResult
    func logout() throws -> LogOutPage {
        logoutButton.tap()
        return try LogOutPage()
    }

    @discardableResult
    func logoutWithoutPassword() throws -> WelcomePage {
        logoutButton.tap()
        oKButtonOnConfirmation.tap()
        return try WelcomePage()
    }

    func deleteAccount() throws -> ConversationsPage {
        deleteAccountButtonOnAccount.tap()
        oKButtonOnConfirmation.tap()
        return try ConversationsPage()
    }

    @discardableResult
    func tapBackupOrRestore() throws -> BackupOrRestorePage {
        backupOrRestoreButton.tap()
        return try BackupOrRestorePage()
    }

    func goBackToSettingsPage() throws -> SettingsPage {
        backToPreviousPage.waitAndTap()
        return try SettingsPage()
    }

    func tapOnResetPasswordButton() throws -> WebViewPage {
        resetPasswordButton.tap()
        return try WebViewPage()
    }

    private func selectImageFromPhotoPicker(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        _ = app.buttons[Locators.PhotosAppPage.select.rawValue].firstMatch.waitAndTap(timeout: 2)
        XCTAssertTrue(
            photoGridImageTile.waitForExistence(timeout: 10),
            "No selectable library image appeared",
            file: file,
            line: line
        )
        photoGridImageTile
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .tap()
    }

    private func waitForPicturePreview(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "value == %@", "image")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: pictureCell)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}

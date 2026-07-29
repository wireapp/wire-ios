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

class ManagedDevicesPage: PageModel {

    override var pageMainElement: XCUIElement {
        manageDevicesButton
    }

    var manageDevicesButton: XCUIElement {
        app.buttons[Locators.ManageDevicesPage.manageDevices.rawValue].firstMatch
    }

    var passwordField: XCUIElement {
        app.secureTextFields.firstMatch
    }

    static func removeDeviceAndContinueIfShown(app: XCUIApplication) throws -> ConversationsPage {
        let manageDevicesButton = app.buttons[Locators.ManageDevicesPage.manageDevices.rawValue].firstMatch

        // This page is optional after SSO login, so avoid ManagedDevicesPage() init waiting for it.
        guard manageDevicesButton.waitForExistence(timeout: 2) else {
            return try ConversationsPage()
        }

        return try removeFirstDeviceAndContinue(app: app, manageDevicesButton: manageDevicesButton)
    }

    func removeDeviceAndContinueIfShown() throws -> ConversationsPage {
        try Self.removeDeviceAndContinueIfShown(app: app)
    }

    func removeFirstDeviceAndContinue(password: String) throws -> ConversationsPage {
        manageDevicesButton.tap()
        app.images[Locators.ManageDevicesPage.removeDevice.rawValue].firstMatch.waitAndTap()
        app.buttons[Locators.ManageDevicesPage.deleteDevice.rawValue].firstMatch.waitAndTap()
        try passwordField.tapIfKeyboardNotFocused().typeText(password)
        app.buttons[Locators.ManageDevicesPage.ok.rawValue].firstMatch.waitAndTap()

        return try ConversationsPage()
    }

    private static func removeFirstDeviceAndContinue(
        app: XCUIApplication,
        manageDevicesButton: XCUIElement
    ) throws -> ConversationsPage {
        manageDevicesButton.tap()
        app.images[Locators.ManageDevicesPage.removeDevice.rawValue].firstMatch.waitAndTap()
        app.buttons[Locators.ManageDevicesPage.deleteDevice.rawValue].firstMatch.waitAndTap()

        return try ConversationsPage()
    }

}

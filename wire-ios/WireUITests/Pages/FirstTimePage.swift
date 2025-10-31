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

/// Page for popup on first time user login
class FirstTimePage: PageModel {
    override var pageMainElement: XCUIElement {
        okButton
    }

    deinit {
        if let token = handler?.1 {
            handler?.0.removeUIInterruptionMonitor(token)
        }
    }

    var okButton: XCUIElement {
        app.buttons[Locators.FirstTimePage.okButton.rawValue]
    }
    
    var firstTimePageMessageLabel: XCUIElement {
        app.staticTexts["It’s the first time you’re using Wire on this device."]
    }

    var savePasswordSheet: XCUIElement {
        app.staticTexts["Save Password?"]
    }

    var notNowOptionOnSavePasswordSheet: XCUIElement {
        app.buttons["Not Now"]
    }

    var handler: (XCTestCase, any NSObjectProtocol)?

    // Tap OK button on first time using Wire popup
    func acceptFirstTimeAlert() -> FirstTimePage {
        dismissSavePasswordAlertIfPresent()
        okButton.tap()
        firstTimePageMessageLabel.waitForNonExistence(timeout: 2)
        return self
    }

    func acceptPopup(with testCase: XCTestCase) throws -> ConversationsPage {
        handleNotificationPermissionAlert(testCase: testCase)
        return try ConversationsPage()
    }

    func acceptPopupOnTeamMemberSetup(with testCase: XCTestCase) throws -> SetUsernamePage {
        handleNotificationPermissionAlert(testCase: testCase)
        return try SetUsernamePage()
    }

    private func handleNotificationPermissionAlert(testCase: XCTestCase) {
        let handler = testCase
            .addUIInterruptionMonitor(withDescription: "Notifications Permission Alert") { alertElement -> Bool in
                let notifPermission = "Would Like to Send You Notifications"
                if alertElement.label.contains(notifPermission) {
                    alertElement.buttons["Allow"].tap()
                }

                return true
            }
        self.handler = (testCase, handler)
    }

    private func dismissSavePasswordAlertIfPresent() {
        if savePasswordSheet.waitForExistence(timeout: 2) {
            notNowOptionOnSavePasswordSheet.tap()
            _ = savePasswordSheet.waitToDisappear(timeout: 2)
        }
    }
}

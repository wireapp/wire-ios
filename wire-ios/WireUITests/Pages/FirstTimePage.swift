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

/// Page for popup on first time user login
class FirstTimePage: PageModel {
    override var pageMainElement: XCUIElement {
        okButton
    }

    var okButton: XCUIElement {
        app.buttons[Locators.FirstTimePage.okButton.rawValue].firstMatch
    }

    var savePasswordSheet: XCUIElement {
        app.staticTexts[Locators.FirstTimePage.savePasswordSheet.rawValue]
    }

    var notNowOptionOnSavePasswordSheet: XCUIElement {
        app.buttons[Locators.FirstTimePage.notNowOption.rawValue]
    }

    var conversationsButton: XCUIElement {
        app.buttons[Locators.ConversationsPage.bottomBarRecentListButton.rawValue]
    }

    var usernameField: XCUIElement {
        app.descendants(matching: .textField)[Locators.SetUsernamePage.usernameTextField.rawValue].firstMatch
    }

    // Tap OK button on first time using Wire popup
    func acceptFirstTimeAlert() -> FirstTimePage {
        dismissSavePasswordAlertIfPresent()
        _ = okButton.waitForExistence(timeout: 2)
        if !okButton.isHittable {
            dismissSavePasswordAlertIfPresent()
        }
        if okButton.isHittable {
            okButton.tap()
        }
        okButton.waitToDisappear()
        return self
    }

    func acceptPopup() throws -> ConversationsPage {
        // Sometimes the OK button take longer to disappear after tapping.
        guard conversationsButton.waitForExistence(timeout: 15) else {
            throw NSError(
                domain: "XCUITest Error",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "OK button loader shown longer...conversationsButton could not be shown within 15 seconds"
                ]
            )
        }
        conversationsButton.tap()
        return try ConversationsPage()
    }

    func acceptPopupOnTeamMemberSetup() throws -> SetUsernamePage {
        try SetUsernamePage()
    }

    private func dismissSavePasswordAlertIfPresent() {
        if savePasswordSheet.waitForExistence(timeout: 4) {
            notNowOptionOnSavePasswordSheet.tap()
            _ = savePasswordSheet.waitToDisappear(timeout: 4)
        }
    }
}

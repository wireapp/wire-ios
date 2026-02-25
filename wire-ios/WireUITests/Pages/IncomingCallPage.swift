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

class IncomingCallPage: PageModel {

    override var pageMainElement: XCUIElement {
        acceptButton
    }

    var acceptButton: XCUIElement {
        app.staticTexts[Locators.IncomingCallPage.acceptCall.rawValue]
    }

    func getCallerName() -> String {
        let callerElement = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "calling")).element
        return callerElement.label
    }

    func acceptIncommingCall(with testCase: XCTestCase) throws -> OngoingCallPage {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        acceptButton.tap()
        let alert = springboard.alerts.firstMatch
        if alert.waitForExistence(timeout: 2), alert.label.contains(Locators.IncomingCallPage.microphoneLabel.rawValue) {
            alert.buttons[Locators.IncomingCallPage.allowButtonOnNotification.rawValue].tap()
        }

        return try OngoingCallPage()
    }
}

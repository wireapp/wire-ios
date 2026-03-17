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

    private var handler: (XCTestCase, any NSObjectProtocol)?

    deinit {
        if let token = handler?.1 {
            handler?.0.removeUIInterruptionMonitor(token)
        }
    }

    var acceptButton: XCUIElement {
        app.staticTexts[Locators.IncomingCallPage.acceptCall.rawValue]
    }

    var turnOffMicrophoneButton: XCUIElement {
        app.staticTexts[Locators.IncomingCallPage.turnOffMicrophone.rawValue]
    }

    func getCallerName() -> String {
        let callerElement = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "calling")).element
        return callerElement.label
    }

    func acceptIncommingCall(with testCase: XCTestCase) throws -> OngoingCallPage {
        handleMicrophonePermissionAlert(testCase: testCase)
        acceptButton.tap()
        turnOffMicrophoneButton.tap()
        return try OngoingCallPage()
    }

    private func handleMicrophonePermissionAlert(testCase: XCTestCase) {
        let handler = testCase
            .addUIInterruptionMonitor(withDescription: "Microphone Permission Alert") { alertElement -> Bool in
                let microphoneKeyword = "Microphone"
                guard alertElement.label.contains(microphoneKeyword) else { return false }

                guard alertElement.buttons["Allow"].exists else { return false }
                alertElement.buttons["Allow"].tap()
                return true
            }
        self.handler = (testCase, handler)
    }
}

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

final class WireAuthenticationTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        app = XCUIApplication()
        app.launchArguments = [
            "-BackendEnvironmentTypeOverrideKey staging",
            "--preferred-api-version=8"
        ]
        app.useWireAuthentication()

        app.launch()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func test_Login_withWrongEmail_NextIsDisabled() throws {

        let textField = emailTextField()
        textField.tap()
        textField.typeText("notAnEmail.com")

        let nextButton = nextButton()
        XCTAssertFalse(nextButton.isEnabled, "nextButton should be disabled if no email")
    }

    @MainActor // note: comment @MainActor to use recorder
    func test_Login_withEmail() throws {

        let textField = emailTextField()
        textField.tap()
        textField.typeText(LoginCredentials.email)

        let errorAlert = app.alerts["Error"]
        XCTAssertFalse(errorAlert.exists)

//        let okButton = errorAlert.scrollViews.otherElements.buttons["OK"]
//        okButton.tap()
    }

    // MARK: - Helpers

    private func nextButton() -> XCUIElement {
        let elementsQuery = app.scrollViews.otherElements
        return elementsQuery.buttons["Next"]
    }

    private func emailTextField() -> XCUIElement {
        let elementsQuery = app.scrollViews.otherElements
        let textField = elementsQuery.textFields["Email or SSO code"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: textField, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        return textField
    }
}

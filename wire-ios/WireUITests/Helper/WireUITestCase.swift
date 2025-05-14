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

// Methods to reset app or simulator caused issues, so instead
// of using a script in the scheme, we delete the app using springboard

import XCTest

class WireUITestCase: XCTestCase {
    var app: XCUIApplication!
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUpWithError() throws {
        // Delete app, useful if we aren't resetting simulators between runs (locally writing tests)
        XCUIApplication().terminate()
        deleteApp()

        app = XCUIApplication()
        app.launchArguments = [
            "-BackendEnvironmentTypeOverrideKey staging",
            "--preferred-api-version=8"
        ]
        app.useWireAuthentication()

        app.launch()

        // In UI tests it is usually best to stop immediately when a failure occurs
        continueAfterFailure = false
    }

    // MARK: - Helpers

    func deleteApp() {
        let icon = springboard.icons["Wire"]
        if icon.exists {
            icon.press(forDuration: 1.3)

            springboard.buttons["com.apple.springboardhome.application-shortcut-item.remove-app"].tap()

            // For some reason the following commands were unreliable when called once
            let deleteApp = springboard.buttons["Delete App"]
            deleteApp.waitForExistence(timeout: 1)
            deleteApp.tap()
            let delete = springboard.buttons["Delete"]
            delete.waitForExistence(timeout: 1)
            delete.tap()
        }
    }
}

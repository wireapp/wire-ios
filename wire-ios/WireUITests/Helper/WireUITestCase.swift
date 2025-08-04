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
    let userHelper = UserHelper()
    let testServiceClient = TestServiceClient()

    override func setUpWithError() throws {
        XCUIApplication().terminate()

        let launchArguments = [
            "-resetData",
            "--BackendEnvironmentTypeOverrideKey=staging",
            "--persist-backend-type",
            "--preferred-api-version=8"
        ]

        app = XCUIApplication()
        app.launchArguments = launchArguments
        app.useWireAuthentication()
        app.launch()

        // In UI tests it is usually best to stop immediately when a failure occurs
        // although this does not appear to work
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        try await userHelper.deleteCreatedUsers()
    }

}

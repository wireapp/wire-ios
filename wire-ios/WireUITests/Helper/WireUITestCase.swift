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

    override func setUpWithError() throws {
        XCUIApplication().terminate()

        let launchArguments = [
            "-resetData",
            "--useEnvStaging"
        ]

        app = XCUIApplication()
        app.launchEnvironment["UITEST_APPLOCK_TIMEOUT"] = "2"
        app.launchArguments = launchArguments
        app.setDeveloperFlags([
            .useWireAuthentication: true,
            .multibackend: true
        ])
        app.launch()

        // In UI tests it is usually best to stop immediately when a failure occurs
        // although this does not appear to work
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        await userHelper.deleteCreatedUsers()
    }

    func setCustomBackend(byDeeplink deeplink: URL, timeout: TimeInterval = 5, domainInfo: String) {
        XCTContext.runActivity(named: "Set custom backend via deeplink") { _ in
            let deeplinkFullURL = "wire://access/?config=\(deeplink)"
            guard let url = URL(string: deeplinkFullURL) else {
                XCTFail("Invalid deeplink: \(deeplinkFullURL)")
                return
            }

            XCUIDevice.shared.system.open(url)

            let alert = springboard.alerts.firstMatch
            if alert.waitForExistence(timeout: 2) {
                let openButton = springboard.alerts.buttons
                    .matching(NSPredicate(format: "label BEGINSWITH[c] 'Open'"))
                    .firstMatch
                if openButton.waitForExistence(timeout: 1) {
                    openButton.tap()
                }
            }

            XCTAssertTrue(
                app.wait(for: .runningForeground, timeout: timeout),
                "App did not return to foreground after opening deeplink"
            )
            guard let welcomePage = try? SetCustomBackendPage().tapOnProceedButton() else {
                XCTFail("Failed to proceed to set custom backend")
                return
            }
            let labeltext = welcomePage.setBackendLabel.label
            XCTAssertTrue(
                labeltext.contains(domainInfo),
                "Expected domain missing from \(labeltext)"
            )
        }
    }

    func switchBackend(target: BackendTarget) throws {

        let deeplink = try EnvironmentVariables().deepLinkURL(for: target)
        setCustomBackend(byDeeplink: deeplink, domainInfo: target.domainInfo)
        // need to change for Inbucket
        BackendContext.current = target
    }
}

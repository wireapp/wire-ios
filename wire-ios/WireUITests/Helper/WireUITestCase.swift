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

// Methods to reset app or simulator caused issues, so instead
// of using a script in the scheme, we delete the app using springboard

import WireFoundation
import WireUtilities
import XCTest

class WireUITestCase: XCTestCase {

    var app: XCUIApplication!
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    var ssoHelper: SSOHelper!
    let testServicesClient = TestServicesClient()
    var callingServiceClient: CallingServiceClient!
    var callingManager: CallingManager!
    var uiTestConfig = UITestConfig()
    private var notificationPermissionMonitor: NSObjectProtocol?

    @MainActor
    override func setUpWithError() throws {
        // Tap "Allow" on permission alert from a previous failed test, so next test is not blocked
        XCUIApplication().dismissAllowIfPresent()
        XCUIApplication().terminate()
        callingServiceClient = try CallingServiceClient()
        callingManager = CallingManager(client: callingServiceClient)
        registerNotificationPermissionMonitor()
        uiTestConfig.useTripleTapForShakeGesture = true
        uiTestConfig.useMockAudioRecorder = true

        let launchArguments = [
            "-resetData",
            "--useEnvStaging"
        ]

        ssoHelper = SSOHelper()
        app = XCUIApplication()
        app.launchEnvironment["UITEST_APPLOCK_TIMEOUT"] = "2"
        app.launchEnvironment[UITestConfig.environmentKey] = uiTestConfig.encode()
        app.launchArguments = launchArguments
        var flags: [DeveloperFlag: Bool] = [.useWireAuthentication: true]
        flags.merge(additionalDeveloperFlags()) { _, new in new }
        app.setDeveloperFlags(flags)
        app.launch()

        // In UI tests it is usually best to stop immediately when a failure occurs
        // although this does not appear to work
        continueAfterFailure = false
    }

    @MainActor
    override func tearDown() async throws {
        app?.terminate()
        app = nil
        await callingServiceClient?.destroyCreatedInstances()
        await testServicesClient.deleteInstances()
        await UserHelper.deleteCreatedUsers()
        await ssoHelper?.cleanUpSSOResources()
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
    }

    @MainActor
    func loginToBackend(user: UserInfo) async throws -> ConversationsPage {
        print("login: email \(user.email) and password \(user.password)")
        let firstTimePage = try app.loginUser(email: user.email, password: user.password)

        return try firstTimePage
            .acceptPopup()
    }

    func registerNotificationPermissionMonitor() {
        guard notificationPermissionMonitor == nil else { return }

        notificationPermissionMonitor =
            addUIInterruptionMonitor(withDescription: "Notifications Permission Alert") { alertElement -> Bool in
                let notifPermission = "Would Like to"
                let allowButton = alertElement.buttons["Allow"].firstMatch

                guard alertElement.label.contains(notifPermission),
                      allowButton.waitForExistence(timeout: 1) else {
                    return false
                }

                allowButton.tap()
                return true
            }
    }

    func additionalDeveloperFlags() -> [DeveloperFlag: Bool] { [:] }

    func simulateShakeGesture() {
        app.tap(withNumberOfTaps: 3, numberOfTouches: 1)
    }
}

extension XCUIApplication {
    func dismissAllowIfPresent(timeout: TimeInterval = 1.0) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: timeout) else { return }

        let allowButtons = ["Allow While Using App", "Allow"]
        guard let button = allowButtons
            .map({ alert.buttons[$0] })
            .first(where: { $0.exists }) else {
            return
        }
        button.waitAndTap()
    }
}

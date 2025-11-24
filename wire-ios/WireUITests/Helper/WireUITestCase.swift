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

    // setup Tags
    enum UITestTag {
        static let critical = "critical"
    }

    static let testTags: [String: [String]] = [
        "test_CreateBackupAndRestoreHistory": [UITestTag.critical],
        "test_Add_MultiBackend_Accounts": [UITestTag.critical],
        "test_Register_asPersonalUser": [UITestTag.critical],
        "test_Login_asExistingPersonalUser": [UITestTag.critical],
        "test_PersonalAccountLifecycle": [UITestTag.critical],
        "test_Migrate_PersonalUserToTeam": [UITestTag.critical],
        "test_PersonalUser_InvitedToTeam": [UITestTag.critical],
        "test_TeamOwner_GroupCreatedAndSendMessage": [UITestTag.critical],
        "test_GroupAdmin_RemoveAndAddParticipantFromGroup": [UITestTag.critical],
        "test_Login_withWrongEmail_NextIsDisabled": [UITestTag.critical],
        "test_Login_withoutPassword_NextIsDisabled": [UITestTag.critical]

    ]

    private func requestedTags() -> Set<String> {
        let raw = ProcessInfo.processInfo.environment["UITEST_TAGS"] ?? ""
        let parts = raw.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        return Set(parts.filter { !$0.isEmpty })
    }

    private func currentTestMethodName() -> String {
        let components = name.split(separator: " ")
        guard let last = components.last else { return name }
        return last.replacingOccurrences(of: "]", with: "")
    }

    private func shouldSkipBasedOnTags() -> Bool {
        let requested = requestedTags()
        if requested.isEmpty { return false }

        let methodName = currentTestMethodName()
        let methodTags = Set(Self.testTags[methodName, default: []].map { $0.lowercased() })

        return requested.isDisjoint(with: methodTags)
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        if shouldSkipBasedOnTags() {
            throw XCTSkip("Skipping test \(currentTestMethodName()) due to UITEST_TAGS filter")
        }

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

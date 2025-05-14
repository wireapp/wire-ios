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

final class PersonalUsersTests: XCTestCase {
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

    override func tearDown() async throws {
//        TODO: Restore once [WPB-17516] is fixed
//        let email = context["email"] as! String
//        let password = context["password"] as! String
//        let access_token = try? await BackendClient().loginViaAPI(email:email, password:password)
//        if(access_token != nil) {
//            try? await BackendClient().deletePersonalUser(access_token:access_token!, password:password)
//            puts("Cleaned up \(email)")
//        }
    }

    @MainActor
    func test_register_asPersonalUser() async throws {
        let user = UserGenerator().generateUniqueUserInfo()

        let page = LoginPage()
            .typeEmailOrSSO(email: user.email)
            .useCreatePersonalAccountLink()
            .confirmCreateAccount()
            .tapAcceptButton()

        let verificationCode = try await InbucketClient().getVerificationCode(email: user.email)

        let finalPage = page
            .enterVerificationCode(verificationCode: verificationCode)
            .setName(name: user.name)
            .setPassword(password: user.password)
            .acceptPopup()
            .setUsername(username: user.username)
            .openSettings()
            .openAccountSettings()

        XCTAssertTrue(finalPage.getAccountName().elementsEqual(user.name), "Account name didn't match \(user.name)")
        XCTAssertTrue(finalPage.getUsername().contains(user.username), "Username didn't contain \(user.username)")
//        TODO: Restore once [WPB-17516] is fixed
//        XCTAssertTrue(accountPage.getEmail().elementsEqual(user.email))*/
    }

    // MARK: - Helpers

    func deleteApp() {
        let icon = springboard.icons["Wire"]
        if icon.exists {
            icon.press(forDuration: 1.3)

            springboard.buttons["com.apple.springboardhome.application-shortcut-item.remove-app"].tap()

            // For some reason the following commands were unreliable when called once
            springboard.buttons["Delete App"].tap()
            springboard.buttons["Delete App"].tap()
            springboard.buttons["Delete"].tap()
            springboard.buttons["Delete"].tap()
        }
    }
}

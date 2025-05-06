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
    var context: [String: Any] = [:]
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUpWithError() throws {
        // Delete app, useful if we aren't resetting simulators between runs (locally writing tests)
        XCUIApplication().terminate()
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

        app = XCUIApplication()
        app.launchArguments = [
            "-BackendEnvironmentTypeOverrideKey staging",
            "--preferred-api-version=8"
        ]
        app.useWireAuthentication()

        app.launch()

        // In UI tests it is usually best to stop immediately when a failure occurs
        continueAfterFailure = false

        context["app"] = app
    }

    override func tearDown() async throws {
//        TODO: Restore once WPB-17516 is fixed
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
        var loginPage = LoginPage(theApp: app)
        let time = Int(NSDate().timeIntervalSince1970 * 1000)
        let username = "smoketester\(time)"
        let email = "\(username)@wire.engineering"
        let password = generateRandomPassword() // TODO: Make this auto generated
        let name = "Smoke Tester"
        context["username"] = username
        context["email"] = email
        context["password"] = password

        let textField = emailTextField()
        XCTAssertTrue(textField.exists)

        loginPage = loginPage.typeEmailOrSSO(email: email)

        var registrationPage = loginPage.useCreatePersonalAccountLink()
        registrationPage.confirmCreateAccount()
        registrationPage.acceptButton().tap()

        let verificationCode = try await InbucketClient().getVerificationCode(email: email)
        registrationPage = registrationPage.enterVerificationCode(verificationCode: verificationCode)

        registrationPage = registrationPage.setName(name: name)
        registrationPage = registrationPage.setPassword(password: password)

        registrationPage.acceptPopup()

        let conversationsPage = registrationPage.setUsername(username: username)

        XCTAssertTrue(profileButton().exists)

        let settingsPage = conversationsPage.openSettings()
        let accountPage = settingsPage.openAccountSettings()

        XCTAssertTrue(accountPage.getAccountName().elementsEqual(name))
        XCTAssertTrue(accountPage.getUsername().contains(username))
//        TODO: Restore once WPB-17516 is fixed
//        XCTAssertTrue(accountPage.getEmail().elementsEqual(email))*/
    }

    // MARK: - Helpers

    // TODO: Figure out how to move to page object; expectation and waitForExpectation didn't work with simple copy
    func emailTextField() -> XCUIElement {
        let elementsQuery = app.scrollViews.otherElements
        let textField = elementsQuery.textFields["Email or SSO code"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: textField, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        return textField
    }

    // TODO: Figure out how to move to page object; expectation and waitForExpectation didn't work with simple copy
    func profileButton() -> XCUIElement {
        let elementsQuery = app.buttons.matching(identifier: "account_profile_image_view")
        let button = elementsQuery.firstMatch
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: button, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        return button
    }

    // TODO: Look into maybe using a library for this
    // TODO: When working on one of the other critical flows, pull this out into a user builder helper of some kind
    func generateRandomPassword() -> String {
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let uppercase = lowercase.uppercased()
        let numbers = "0123456789"
        let specials = "!@#$%^&*()"
        var password = ""
        for _ in 1 ... 5 {
            password += randomCharacterFrom(array: lowercase)
        }
        password += randomCharacterFrom(array: uppercase)
        password += randomCharacterFrom(array: specials)
        password += randomCharacterFrom(array: numbers)
        return password
    }

    func randomCharacterFrom(array: String) -> String {
        let randomIndex = Int.random(in: 0 ..< array.count)
        let character = array[array.index(array.startIndex, offsetBy: randomIndex)]
        return String(character)
    }

}

struct RuntimeError: LocalizedError {
    let description: String

    init(_ description: String) {
        self.description = description
    }

    var errorDescription: String? {
        description
    }
}

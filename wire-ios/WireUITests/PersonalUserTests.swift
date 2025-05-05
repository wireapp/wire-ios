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
    var context: Dictionary<String,Any> = [:]

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
        
        context["app"] = app
    }

    override func tearDown() async throws {
        let email = context["email"] as! String
        let password = context["password"] as! String
        let access_token = try? await BackendClient().loginViaAPI(email:email, password:password)
        if(access_token != nil) {
            try? await BackendClient().deletePersonalUser(access_token:access_token!, password:password)
            puts("Cleaned up \(email)")
        }
    }

    @MainActor
    func test_register_asPersonalUser() async throws {
        let loginPage = LoginPage(theApp:app)
        let email = "newUser08@wire.engineering" // TODO: Make this auto generated and unique
        context["email"] = email
        context["password"] = ProcessInfo.processInfo.environment["DEFAULT_PASSWORD"] // TODO: Make this auto generated
        
        let textField = emailTextField()
        XCTAssertTrue(textField.exists)
        textField.tap()
        textField.typeText(email)

        loginPage.nextButton().tap()

        loginPage.createPersonalAccountLink().tap()

        loginPage.newNextButton().tap()

        loginPage.acceptButton().tap()

        let verificationCode = try await InbucketClient().getVerificationCode(email:email)

        loginPage.verificationCodeInput().tap()
        loginPage.verificationCodeInput().typeText(verificationCode)
        
        let registrationPage = RegistrationPage(theApp: app)

        registrationPage.nameField().tap()
        registrationPage.nameField().typeText("Smoke Tester")
        registrationPage.nameNextButton().tap()

        registrationPage.passwordField().tap()
        registrationPage.passwordField().typeText(context["password"] as! String)
        registrationPage.passwordNextButton().tap()
        
        registrationPage.allowButton().tap()

        let fullScreenshot = XCUIScreen.main.screenshot()
        let screenshot = XCTAttachment(screenshot: fullScreenshot)
        screenshot.lifetime = .keepAlways
        add(screenshot)
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

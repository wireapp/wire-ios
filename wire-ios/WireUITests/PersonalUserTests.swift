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
    func test_register_asPersonalUser() async throws {
        let textField = emailTextField()
        let email = "adfdasfasfaewa@wire.engineering"
        textField.tap()
        textField.typeText(email)

        nextButton().tap()

        createPersonalAccountLink().tap()

        newNextButton().tap()

        acceptButton().tap()

        let verificationCode = try await getVerificationCode(email:email)

        verificationCodeInput().tap()
        verificationCodeInput().typeText(verificationCode)

        let fullScreenshot = XCUIScreen.main.screenshot()
        let screenshot = XCTAttachment(screenshot: fullScreenshot)
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    // MARK: - Helpers

    private func getVerificationCode(email:String) async throws -> String {
        let inbucketURL = "https://\(ProcessInfo.processInfo.environment["INBUCKET_URL"]!)"
        let inbucketUsername = ProcessInfo.processInfo.environment["INBUCKET_USERNAME"]!
        let inbucketPassword = ProcessInfo.processInfo.environment["INBUCKET_PASSWORD"]!
        var verificationCode:String = ""
        let url = URL(string: "\(inbucketURL)/api/v1/mailbox/\(email)/latest")
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        let loginString = String(format: "%@:%@", inbucketUsername, inbucketPassword)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        let (inbucketData,_) = try await URLSession.shared.data(for: request)

        // Convert HTTP Response Data to a simple String
        let message:InbucketMessage = try! JSONDecoder().decode(InbucketMessage.self, from:inbucketData)
        let subject:String = message.subject
        verificationCode = String(subject.prefix(6))
    
        print("Verification Code Found: \(verificationCode) for \(email)")
        return verificationCode
    }

    private func verificationCodeInput() -> XCUIElement {
        let elementsQuery = app.textViews.matching(identifier: "VerificationCode")
        return elementsQuery.firstMatch
    }

    private func nextButton() -> XCUIElement {
        let elementsQuery = app.scrollViews.otherElements
        return elementsQuery.buttons["Next"]
    }

    private func newNextButton() -> XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons.containing(.button, identifier: "ConfirmButton").firstMatch
    }

    private func emailTextField() -> XCUIElement {
        let elementsQuery = app.scrollViews.otherElements
        let textField = elementsQuery.textFields["Email or SSO code"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: textField, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        return textField
    }

    private func createPersonalAccountLink() -> XCUIElement {
        let elementsQuery = app.scrollViews.otherElements
        return elementsQuery.buttons["Create Personal Account"]
    }

    private func acceptButton() -> XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons["Accept"]
    }
}

struct InbucketMessage: Decodable {
    let subject:String
}

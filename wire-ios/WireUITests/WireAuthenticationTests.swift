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

import XCTest

final class WireAuthenticationTests: WireUITestCase {

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func test_Login_withWrongEmail_NextIsDisabled() throws {

        let welcomePage = try WelcomePage()
            .typeEmailOrSSO("notAnEmail.com")

        XCTAssertFalse(welcomePage.nextButton.isEnabled, "nextButton should be disabled if no email")
    }

    @MainActor
    func test_Login_withoutPassword_NextIsDisabled() throws {

        let loginPage = try WelcomePage()
            .enterEmailOrSSO(LoginCredentials.email)

        XCTAssertEqual(app.textFields["Enter email"].value as? String, LoginCredentials.email)
        XCTAssertTrue(loginPage.nextButton.waitForExistence(timeout: 2.0))
        XCTAssertFalse(loginPage.nextButton.isEnabled, "nextButton should be disabled if no password")
    }
}

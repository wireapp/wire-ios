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

class UserAccountPage: PageModel {

    override func hasLoaded() {
        let expectation = profileButton.waitForExistence(timeout: 10)
        XCTAssert(expectation, "Can't find profile button")
    }

    var profileButton: XCUIElement {
        let elementsQuery = app.descendants(matching: .any)["account_profile_image_view"]
        return elementsQuery.firstMatch
    }

    var createTeamButton: XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons["Create Wire Team"]
    }

    var teamNameTextField: XCUIElement {
        let elementsQuery = app.textFields
        return elementsQuery["Your Team"]
    }

    var continueButton: XCUIElement {
        let elementsQuery = app.scrollViews.otherElements
        return elementsQuery.buttons["Continue"]
    }

    var checkbox: XCUIElement {
        app.descendants(matching: .any)["square"].firstMatch
    }

    var goToTeamManagementButton: XCUIElement {
        let elementsQuery = app.buttons
        return elementsQuery["Go To Team Management"]
    }

    var backToWireButton: XCUIElement {
        let elementsQuery = app.buttons
        return elementsQuery["Back To Wire"]
    }

    var teamNameOnAccountPage: XCUIElement {
        let elementsQuery = app.staticTexts
        return elementsQuery["team name"].firstMatch
    }

    var manageTeamButton: XCUIElement {
        let elementsQuery = app.staticTexts
        return elementsQuery["Manage Team"]
    }

    func tapCreateTeamButtonAndContinue() -> UserAccountPage {
        createTeamButton.tap()
        continueButton.tap()
        return self
    }

    func typeTeamNameAndContinue(_ input: String) -> UserAccountPage {
        teamNameTextField.tap()
        teamNameTextField.typeText(input)
        continueButton.tap()
        return self
    }

    func acceptTheConfirmationAndContinue() -> UserAccountPage {
        checkbox.tap()
        checkbox.tap()
        continueButton.tap()
        return self
    }

    func tapBackToWireButton() -> ConversationsPage {
        backToWireButton.tap()
        return ConversationsPage()
    }

    func getTeamName() -> String? {
        teamNameOnAccountPage.value as? String
    }

}

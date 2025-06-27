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

/// User Account/profile page
class UserAccountPage: PageModel {

    override var pageMainElement: XCUIElement {
        qrCodeButton
    }

    var profileButton: XCUIElement {
        let elementsQuery = app.descendants(matching: .any)["account_profile_image_view"]
        return elementsQuery.firstMatch
    }

    var qrCodeButton: XCUIElement {
        let elementsQuery = app.descendants(matching: .any)["QR code button"]
        return elementsQuery.firstMatch
    }

    var createTeamButton: XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons["Create Wire Team"]
    }

    var teamNameOnAccountPage: XCUIElement {
        let elementsQuery = app.staticTexts
        return elementsQuery["team name"].firstMatch
    }

    var manageTeamButton: XCUIElement {
        let elementsQuery = app.staticTexts
        return elementsQuery["Manage Team"]
    }

    var closeButton: XCUIElement {
        let elementsQuery = app.descendants(matching: .any)["close"]
        return elementsQuery.firstMatch
    }

    func tapCreateTeamButtonAndContinue() throws -> TeamCreationStepsPage {
        createTeamButton.tap()
        return try TeamCreationStepsPage()
    }

    func closeAccountPage() throws -> ConversationsPage {
        closeButton.tap()
        return try ConversationsPage()
    }

    func getTeamName() -> String? {
        teamNameOnAccountPage.value as? String
    }

}

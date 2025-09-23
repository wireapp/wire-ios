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

import WireFoundation
import XCTest

/// User Account/profile page
class UserAccountPage: PageModel {

    override var pageMainElement: XCUIElement {
        qrCodeButton
    }

//    var profileButton: XCUIElement {
//        app.descendants(matching: .any)["account_profile_image_view"].firstMatch
//    }

    var qrCodeButton: XCUIElement {
        app.descendants(matching: .any)[Locators.Buttons.qrCode].firstMatch
    }

    var createTeamButton: XCUIElement {
        app.otherElements.buttons[Locators.Buttons.createWireTeam].firstMatch
    }

    var teamNameOnAccountPage: XCUIElement {
        app.staticTexts[Locators.StaticTexts.teamName].firstMatch
    }

    var manageTeamButton: XCUIElement {
        app.staticTexts[Locators.StaticTexts.manageTeam].firstMatch
    }

    var closeButton: XCUIElement {
        app.descendants(matching: .any)[Locators.Buttons.closeDetails].firstMatch
    }

    var addAccountOrTeamButton: XCUIElement {
        app.descendants(matching: .any)[Locators.Buttons.addAnotherAccount]
    }

    func tapCreateTeamButtonAndContinue() throws -> TeamSetupStepsPage {
        createTeamButton.tap()
        return try TeamSetupStepsPage()
    }

    func closeAccountPage() throws -> ConversationsPage {
        closeButton.tap()
        return try ConversationsPage()
    }

    func getTeamName() -> String? {
        teamNameOnAccountPage.value as? String
    }

    func tapAddAccountOrTeamButton() throws -> WelcomePage {
        addAccountOrTeamButton.tap()
        return try WelcomePage()
    }

    func switchUserAccountForUser(withName name: String) throws -> ConversationsPage {
        let predicate = NSPredicate(format: "value BEGINSWITH %@", name)
        let button = app.buttons.containing(predicate).firstMatch
        button.tap()
        return try ConversationsPage()
    }

}

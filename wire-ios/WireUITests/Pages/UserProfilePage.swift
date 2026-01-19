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

import WireLocators
import XCTest

/// User Account/profile page
class UserProfilePage: PageModel {

    override var pageMainElement: XCUIElement {
        qrCodeButton
    }

    var qrCodeButton: XCUIElement {
        app.buttons[Locators.UserProfilePage.qrCodeButton.rawValue]
    }

    var createTeamButton: XCUIElement {
        app.otherElements.buttons[Locators.UserProfilePage.createWireTeamButton.rawValue].firstMatch
    }

    var teamNameOnAccountPage: XCUIElement {
        app.descendants(matching: .any)[Locators.UserProfilePage.teamName.rawValue].firstMatch
    }

    var manageTeamButton: XCUIElement {
        app.buttons[Locators.UserProfilePage.addAccountOrTeamButton.rawValue].firstMatch
    }

    var closeButton: XCUIElement {
        app.descendants(matching: .any)[Locators.ConversationDetailsPage.close.rawValue].firstMatch
    }

    var addAccountOrTeamButton: XCUIElement {
        app.descendants(matching: .button)[Locators.UserProfilePage.addAccountOrTeamButton.rawValue].firstMatch
    }

    func tapCreateTeamButton() throws -> TeamSetupStepsPage {
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
        let predicate = NSPredicate(format: "label BEGINSWITH %@", name)
        let button = app.buttons.containing(predicate).firstMatch
        button.tap()
        return try ConversationsPage()
    }

}

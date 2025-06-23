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

final class TeamManageTests: WireUITestCase {
    
    @MainActor
    func test_CreateTeam_fromPersonalUser() async throws {
        let user = try await userManager.createPersonalUser()
        let userAccountPage = WelcomePage()
            .enterEmailOrSSO(user.email)
            .enterPassword(user.password)
            .acceptFirstTimeAlert()
            .acceptPopup()
            .openUserAccount()
            .tapCreateTeamButtonAndContinue()
            .typeTeamNameAndContinue(user.teamname)
            .acceptTheConfirmationAndContinue()
            .tapBackToWireButton()
            .openUserAccount()
        
        XCTAssertTrue(userAccountPage.getTeamName().elementsEqual(user.teamname), "Team name didn't match \(user.teamname)")
        
        // Get teamID
        let teamID = try await BackendClient.getTeamIDFromSelfRequest(email: user.email, password: user.password)
        print(teamID)
       
        
        
        
        print()
//        let app = XCUIApplication()
//        app.activate()
//        app/*@START_MENU_TOKEN@*/.buttons["Smoke Tester 1750428498194 account."]/*[[".buttons.containing(.image, identifier: \"notification_badge.info\").firstMatch",".navigationBars.buttons[\"Smoke Tester 1750428498194 account.\"]",".buttons[\"Smoke Tester 1750428498194 account.\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    
//        
//        let yourTeamTextField = app/*@START_MENU_TOKEN@*/.textFields["Your Team"]/*[[".otherElements.textFields[\"Your Team\"]",".textFields.firstMatch",".textFields[\"Your Team\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
//        yourTeamTextField.tap()
//        yourTeamTextField.tap()
//        continueButton.tap()
//        app.buttons.matching(identifier: "square").element(boundBy: 0).tap()
//        app/*@START_MENU_TOKEN@*/.otherElements.buttons["square"]/*[[".otherElements",".buttons[\"Square\"]",".buttons[\"square\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[2,0]]@END_MENU_TOKEN@*/.tap()
//        continueButton.tap()
//        app/*@START_MENU_TOKEN@*/.staticTexts["Congratulations smoke tester 1750422950266!"]/*[[".otherElements.staticTexts[\"Congratulations smoke tester 1750422950266!\"]",".staticTexts[\"Congratulations smoke tester 1750422950266!\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        app/*@START_MENU_TOKEN@*/.buttons["Back To Wire"]/*[[".otherElements.buttons[\"Back To Wire\"]",".buttons[\"Back To Wire\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        app/*@START_MENU_TOKEN@*/.buttons["account_profile_image_view"]/*[[".buttons.containing(.image, identifier: \"notification_badge.info\").firstMatch",".navigationBars",".buttons[\"Smoke Tester 1750422950266 account.\"]",".buttons[\"account_profile_image_view\"]"],[[[-1,3],[-1,2],[-1,1,1],[-1,0]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/.tap()
//        app/*@START_MENU_TOKEN@*/.staticTexts["Manage Team"]/*[[".cells.staticTexts[\"Manage Team\"]",".staticTexts[\"Manage Team\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        
        
        
    }
    
    
}

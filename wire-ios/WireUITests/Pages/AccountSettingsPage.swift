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

class AccountSettingsPage: PageModel {
    func nameField() -> XCUIElement {
        let elementsQuery = app.textFields.matching(identifier: "NameField")
        return elementsQuery.firstMatch
    }
    
    func usernameField() -> XCUIElement {
        let elementsQuery = app.staticTexts.matching(identifier: "UsernameField")
        return elementsQuery.firstMatch
    }
    
    func emailField() -> XCUIElement {
        let elementsQuery = app.staticTexts.matching(identifier: "EmailField")
        return elementsQuery.firstMatch
    }
    
    func getAccountName() -> String {
        return nameField().value as! String
    }
    
    func getUsername() -> String {
        return usernameField().label
    }
    
    func getEmail() -> String {
        return emailField().label
    }
}

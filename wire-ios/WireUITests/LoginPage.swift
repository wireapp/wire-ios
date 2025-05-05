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

class LoginPage  {
    let app:XCUIApplication
    
    init(theApp:XCUIApplication) {
        app = theApp
    }
    
    func acceptButton() -> XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons["Accept"]
    }
    
    func verificationCodeInput() -> XCUIElement {
        let elementsQuery = app.textViews.matching(identifier: "VerificationCode")
        return elementsQuery.firstMatch
    }

    func nextButton() -> XCUIElement {
        let elementsQuery = app.scrollViews.otherElements
        return elementsQuery.buttons["Next"]
    }

    func newNextButton() -> XCUIElement {
        let elementsQuery = app.otherElements
        return elementsQuery.buttons["ConfirmButton"]
    }

    func createPersonalAccountLink() -> XCUIElement {
        let elementsQuery = app.scrollViews.otherElements
        return elementsQuery.buttons["Create Personal Account"]
    }
}

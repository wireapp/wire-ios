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

class SetCustomBackendPage: PageModel {
    override var pageMainElement: XCUIElement {
        proceedButton
    }

    var proceedButton: XCUIElement {
        app.buttons[Locators.SetCustomBackendPage.proceedButton.rawValue]
    }

    func backendUrlValue(containing url: URL) -> XCUIElement {
        let backendURL = url.absoluteString.hasSuffix("/") ? String(url.absoluteString.dropLast()) : url.absoluteString
        return app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", backendURL)).firstMatch
    }

    @discardableResult
    func tapOnProceedButton() throws -> WelcomePage {
        proceedButton.waitAndTap()
        return try WelcomePage()
    }
}

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

class DeveloperToolsPage: PageModel {
    
    override var pageMainElement: XCUIElement {
        app.navigationBars["Developer tools"]
    }
    
    
    var memoryStatusCell:  XCUIElement {
        app.staticTexts["UserSession"]
    }

    func isUserSessionMemoryStatus(deallocated: Bool) -> Self {
        let state = !deallocated ? "retained" : "deallocated"
        let memoryValue = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '\(state)'")).firstMatch
        XCTAssertTrue(
            memoryValue.waitForExistence(timeout: 2),
            "UserSession should be deallocated after logout. " +
            "Check Developer Tools > Memory Status section for current state. " +
            "If it shows 'retained', there's a MEMORY LEAK in tearDown()."
        )
        return self
    }

    static func show(from app: XCUIApplication) throws -> DeveloperToolsPage {
        // Triple tap to open Developer Tools (works on simulator)
        app.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        return try DeveloperToolsPage()
    }

    func hide() {
        app.buttons["Close"].firstMatch.tap()
    }
    
}

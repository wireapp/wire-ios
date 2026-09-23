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

class ConversationTimeoutOptionsPage: PageModel {

    override var pageMainElement: XCUIElement {
        closeButton
    }

    private var closeButton: XCUIElement {
        app.buttons[Locators.ConversationTimeoutOptionsPage.timeOutOptionsCloseButton.rawValue].firstMatch
    }

    func option(displayString: String) -> XCUIElement {
        app.cells.matching(NSPredicate(format: "label == %@", displayString)).firstMatch
    }

    @discardableResult
    func select(displayString: String) -> Self {
        XCTAssertTrue(
            option(displayString: displayString).waitAndTap(),
            "Self-deleting message timer option '\(displayString)' did not appear"
        )
        return self
    }

    @discardableResult
    func assertSelected(
        displayString: String
    ) -> Self {
        let timeoutOption = option(displayString: displayString)
        XCTAssertTrue(
            timeoutOption.waitForExistence(timeout: 2),
            "Self-deleting message timer option '\(displayString)' did not appear"
        )
        XCTAssertEqual(
            timeoutOption.value as? String,
            "Selected",
            "Self-deleting message timer option '\(displayString)' is not selected"
        )
        return self
    }

    func closeTimeoutOptions() throws -> ActiveConversationPage {
        closeButton.waitAndTap()
        return try ActiveConversationPage()
    }
}

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

class MeetingFormPage: PageModel {
    override var pageMainElement: XCUIElement {
        titleField
    }

    var titleField: XCUIElement {
        app.textFields["meetingFormTitle"]
    }

    var saveButton: XCUIElement {
        app.buttons["meetingFormSave"]
    }

    @discardableResult
    func replaceTitle(with title: String) -> MeetingFormPage {
        let clearButton = app.descendants(matching: .any)["meetingFormClearTitle"].firstMatch
        if clearButton.exists {
            clearButton.tap()
        }
        titleField.tap()
        titleField.typeText(title)
        return self
    }

    @discardableResult
    func save() throws -> MeetingsPage {
        XCTAssertTrue(saveButton.waitAndTap(timeout: 10), "Meeting form save button was not available")
        XCTAssertTrue(titleField.waitToDisappear(timeout: 30), "Meeting form did not close after save")
        return try MeetingsPage()
    }
}

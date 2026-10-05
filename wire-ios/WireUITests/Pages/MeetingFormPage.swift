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

    var participantsButton: XCUIElement {
        app.buttons["meetingFormParticipants"]
    }

    var saveButton: XCUIElement {
        app.buttons["meetingFormSave"]
    }

    var memberSearchField: XCUIElement {
        app.searchFields["Enter a name"]
    }

    var selectMembersButton: XCUIElement {
        app.buttons["meetingMembersSelect"]
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
    func addParticipants(_ users: [UserInfo]) throws -> MeetingFormPage {
        participantsButton.tap()
        XCTAssertTrue(memberSearchField.waitForExistence(timeout: 5), "Meeting member search did not appear")

        for user in users {
            memberSearchField.tap()
            memberSearchField.typeText(user.name)

            let member = app.buttons["meetingMember.\(user.id.uppercased())"]
            XCTAssertTrue(member.waitAndTap(timeout: 10), "Meeting member '\(user.name)' did not appear")

            XCTAssertTrue(memberSearchField.buttons["Clear text"].waitAndTap(), "Member search did not clear")
        }

        XCTAssertTrue(selectMembersButton.waitAndTap(), "Select members button did not appear")
        XCTAssertTrue(
            participantsButton.waitForExistence(timeout: 5),
            "Meeting form did not return from member selection"
        )
        return self
    }

    @discardableResult
    func save() throws -> MeetingsPage {
        XCTAssertTrue(saveButton.waitAndTap(timeout: 10), "Meeting form save button was not available")
        XCTAssertTrue(titleField.waitToDisappear(timeout: 30), "Meeting form did not close after save")
        return try MeetingsPage()
    }
}

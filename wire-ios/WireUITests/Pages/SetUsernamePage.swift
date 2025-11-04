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

class SetUsernamePage: PageModel {

    override var pageMainElement: XCUIElement {
        usernameField
    }

    var usernameField: XCUIElement {
        app.descendants(matching: .textField)["UsernameField"].firstMatch
    }

    var confirmUsernameButton: XCUIElement {
        app.descendants(matching: .button)["ConfirmButton"].firstMatch
    }

    func setUsername(_ username: String) throws -> ConversationsPage {
        if usernameField.exists, usernameField.isHittable {
            try usernameField.tapIfKeyboardNotFocused().typeText(username)
        }
        confirmUsernameButton.tap()
        return try ConversationsPage()
    }
}

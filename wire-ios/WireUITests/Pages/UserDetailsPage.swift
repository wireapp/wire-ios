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

class UserDetailsPage: PageModel {

    override var pageMainElement: XCUIElement {
        userNameInfo
    }

    var userNameInfo: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "username").firstMatch
    }

    var closeProfileButton: XCUIElement {
        app.buttons["close"].firstMatch
    }

    var connectButton: XCUIElement {
        app.staticTexts["Connect"].firstMatch
    }

    func getUserName() -> String? {
        userNameInfo.value as? String
    }

    func sendConnectionRequest() -> UserDetailsPage {
        connectButton.tap()
        return self
    }

    func closeProfilePage() throws -> NewConversationPage {
        closeProfileButton.tap()
        return try NewConversationPage()
    }

}

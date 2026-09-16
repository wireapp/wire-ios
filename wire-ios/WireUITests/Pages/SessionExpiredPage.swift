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

/// Alert shown when the self user's session becomes invalid while logged in,
/// e.g. after being removed from the team.
class SessionExpiredPage: PageModel {

    override var pageMainElement: XCUIElement {
        alert
    }

    var alert: XCUIElement {
        app.alerts[Locators.SessionExpiredPage.alertTitle.rawValue]
    }

    var okButton: XCUIElement {
        alert.buttons[Locators.SessionExpiredPage.okButton.rawValue]
    }

    func confirm() throws -> ReauthenticatePage {
        okButton.tap()
        return try ReauthenticatePage()
    }
}

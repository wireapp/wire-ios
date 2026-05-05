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

class ShareDebugReportPage: PageModel {

    private typealias ids = Locators.ShareDebugReportPage

    override var pageMainElement: XCUIElement {
        app.descendants(matching: .any)[ids.actionSheet.rawValue].firstMatch
    }

    var shareViaWireButton: XCUIElement {
        app.descendants(matching: .any)[ids.shareViaWireButton.rawValue].firstMatch
    }

    var sendEmailButton: XCUIElement {
        app.descendants(matching: .any)[ids.sendEmailButton.rawValue].firstMatch
    }

    var shareButton: XCUIElement {
        app.descendants(matching: .any)[ids.shareButton.rawValue].firstMatch
    }

    var cancelButton: XCUIElement {
        app.descendants(matching: .any)[ids.cancelButton.rawValue].firstMatch
    }

    @discardableResult
    func selectShare() -> Self {
        shareButton.tap()
        return self
    }

    @discardableResult
    func selectShareViaWire() -> Self {
        shareViaWireButton.tap()
        return self
    }

    @discardableResult
    func selectSendEmail() -> Self {
        sendEmailButton.tap()
        return self
    }
}

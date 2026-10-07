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

class GuestOptionsPage: PageModel {

    override var pageMainElement: XCUIElement {
        guestLinkHeader
    }

    var guestLinkHeader: XCUIElement {
        let predicate = NSPredicate(
            format: "identifier IN %@",
            [
                Locators.GuestOptionsPage.linkHeader.rawValue,
                Locators.GuestOptionsPage.secureLinkHeader.rawValue
            ]
        )
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    var linkHeader: XCUIElement {
        app.descendants(matching: .any)[Locators.GuestOptionsPage.linkHeader.rawValue].firstMatch
    }

    var secureLinkHeader: XCUIElement {
        app.descendants(matching: .any)[Locators.GuestOptionsPage.secureLinkHeader.rawValue].firstMatch
    }

    var createLinkButton: XCUIElement {
        app.descendants(matching: .any)[Locators.GuestOptionsPage.createLinkButton.rawValue].firstMatch
    }

    var linkText: XCUIElement {
        app.descendants(matching: .any)[Locators.GuestOptionsPage.linkText.rawValue].firstMatch
    }

    var createLinkWithPasswordAction: XCUIElement {
        app.buttons[Locators.GuestOptionsPage.createLinkWithPasswordAction.rawValue].firstMatch
    }

    var createLinkWithoutPasswordAction: XCUIElement {
        app.buttons[Locators.GuestOptionsPage.createLinkWithoutPasswordAction.rawValue].firstMatch
    }

    var revokeLinkButton: XCUIElement {
        app.descendants(matching: .any)[Locators.GuestOptionsPage.revokeLinkButton.rawValue].firstMatch
    }

    var confirmRevokeButton: XCUIElement {
        app.buttons[Locators.AlertActions.confirm.rawValue].firstMatch
    }

    func startCreatingLinkWithPassword() throws -> CreateSecureGuestLinkPage {
        createLinkButton.waitAndTap()
        createLinkWithPasswordAction.waitAndTap()
        return try CreateSecureGuestLinkPage()
    }

    @discardableResult
    func createLinkWithoutPassword() -> Self {
        createLinkButton.waitAndTap()
        createLinkWithoutPasswordAction.waitAndTap()
        return self
    }

    @discardableResult
    func revokeLink() -> Self {
        revokeLinkButton.waitAndTap()
        confirmRevokeButton.waitAndTap()
        XCTAssertTrue(createLinkButton.waitForExistence(timeout: 10), "Create link button did not appear after revoke")
        return self
    }

    @discardableResult
    func assertLinkCreated(passwordSecured: Bool) -> Self {
        XCTAssertTrue(linkText.waitForExistence(timeout: 10), "Guest link did not appear")
        XCTAssertTrue(
            linkText.label.contains("http"),
            "Guest link text '\(linkText.label)' does not look like a link"
        )
        XCTAssertTrue(createLinkButton.waitToDisappear(), "Create link button still visible after link was created")
        XCTAssertEqual(
            secureLinkHeader.exists,
            passwordSecured,
            passwordSecured
                ? "Link should be shown as password secured"
                : "Link should not be shown as password secured"
        )
        return self
    }
}

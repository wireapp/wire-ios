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

class UserDetailsPage: PageModel {

    override var pageMainElement: XCUIElement {
        nameInfo
    }

    var nameInfo: XCUIElement {
        app.descendants(matching: .any)[Locators.UserProfilePage.name.rawValue].firstMatch
    }

    var userNameInfo: XCUIElement {
        app.descendants(matching: .any).matching(identifier: Locators.UserProfilePage.username.rawValue).firstMatch
    }

    var closeProfileButton: XCUIElement {
        app.buttons[Locators.UserDetailsPage.close.rawValue].firstMatch
    }

    var connectButton: XCUIElement {
        app.buttons[Locators.UserDetailsPage.connectLeftButton.rawValue]
    }

    var moreActionsButton: XCUIElement {
        app.buttons[Locators.UserDetailsPage.moreOptionRightButton.rawValue]
    }

    var removeFromConversationButton: XCUIElement {
        app.buttons[Locators.UserDetailsPage.removeFromConversation.rawValue]
    }

    var removeUserFromConversationConfirmation: XCUIElement {
        app.buttons[Locators.UserDetailsPage.removeUserFromConversationConfirmation.rawValue].firstMatch
    }

    var contactStatusHint: XCUIElement {
        app.staticTexts["profile.contact_status.hint"].firstMatch
    }

    @discardableResult
    func verifyStartConversationEnabled(_ enabled: Bool) -> Self {
        XCTAssertTrue(connectButton.waitForExistence(timeout: 15), "Start conversation button did not appear")
        XCTAssertEqual(connectButton.label, "Start conversation")
        let state = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == %@", NSNumber(value: enabled)),
            object: connectButton
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [state], timeout: 15),
            .completed,
            "Start conversation did not become \(enabled ? "enabled" : "disabled")"
        )
        return self
    }

    @discardableResult
    func verifyPendingOnboardingHint(name: String) -> Self {
        XCTAssertTrue(contactStatusHint.waitForExistence(timeout: 15), "Pending onboarding hint did not appear")
        XCTAssertEqual(contactStatusHint.label, "You can communicate with \(name) once they are set up.")
        return self
    }

    @discardableResult
    func verifyNoPendingOnboardingHint() -> Self {
        XCTAssertFalse(contactStatusHint.exists, "A fully onboarded teammate must not show the setup hint")
        XCTAssertFalse(app.staticTexts["Onboarding pending"].exists)
        return self
    }

    /// Reproduce a physical tap without requiring the disabled control to be enabled.
    @discardableResult
    func attemptDisabledStartConversation() -> Self {
        verifyStartConversationEnabled(false)
        connectButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(pageMainElement.exists, "A tap on the disabled action must leave the profile open")
        return self
    }

    func getUserName() -> String? {
        userNameInfo.value as? String
    }

    @discardableResult
    func verifyName(_ name: String) -> UserDetailsPage {
        XCTAssertEqual(
            nameInfo.value as? String ?? nameInfo.label,
            name,
            "Name did not match \(name)"
        )
        return self
    }

    @discardableResult
    func verifyUsername(_ username: String) -> UserDetailsPage {
        let expectedUsername = "@\(username)"

        XCTAssertEqual(
            userNameInfo.value as? String ?? userNameInfo.label,
            expectedUsername,
            "Username did not match \(expectedUsername)"
        )
        return self
    }

    func sendConnectionRequest() -> UserDetailsPage {
        connectButton.tap()
        return self
    }

    func closeProfilePage() throws -> NewConversationPage {
        closeProfileButton.tap()
        return try NewConversationPage()
    }

    func removeParticipantFromConversation() throws -> ConversationDetailsPage {
        moreActionsButton.tap()
        removeFromConversationButton.tap()
        let confirmButton = removeUserFromConversationConfirmation
        XCTAssertTrue(
            confirmButton.waitForExistence(timeout: 2),
            "Confirm Remove From Conversation button did not appear in time"
        )
        confirmButton.tap()
        return try ConversationDetailsPage()
    }

    func tapStartConversationButton() throws -> ActiveConversationPage {
        connectButton.tap()
        return try ActiveConversationPage()
    }

    func tapConnect() throws -> Self {
        connectButton.tap()
        return self
    }

}

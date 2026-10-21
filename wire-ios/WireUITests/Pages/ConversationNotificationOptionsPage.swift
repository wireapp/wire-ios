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

class ConversationNotificationOptionsPage: PageModel {

    override var pageMainElement: XCUIElement {
        everythingOption
    }

    enum NotificationMode {
        case everything
        case mentionsAndReplies
        case nothing

        var locator: Locators.ConversationNotificationOptionsPage {
            switch self {
            case .everything:
                .everythingOption
            case .mentionsAndReplies:
                .mentionsAndRepliesOption
            case .nothing:
                .nothingOption
            }
        }

        var title: String {
            switch self {
            case .everything:
                "Everything"
            case .mentionsAndReplies:
                "Mentions and Replies"
            case .nothing:
                "Nothing"
            }
        }
    }

    func option(_ notificationMode: NotificationMode) -> XCUIElement {
        app.descendants(matching: .any)[notificationMode.locator.rawValue].firstMatch
    }

    var everythingOption: XCUIElement {
        option(.everything)
    }

    var mentionsAndRepliesOption: XCUIElement {
        option(.mentionsAndReplies)
    }

    var nothingOption: XCUIElement {
        option(.nothing)
    }

    private var backButton: XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@ AND label == %@", "BackButton", "Back")
        return app.buttons.matching(predicate).firstMatch
    }

    @discardableResult
    func select(_ notificationMode: NotificationMode) -> Self {
        XCTAssertTrue(
            option(notificationMode).waitAndTap(),
            "Notification option did not appear"
        )
        return self
    }

    @discardableResult
    func assertSelected(
        _ notificationMode: NotificationMode,
    ) -> Self {
        let notificationOption = option(notificationMode)
        XCTAssertTrue(
            notificationOption.waitForExistence(timeout: 2),
            "Notification option did not appear",
        )
        XCTAssertEqual(
            notificationOption.value as? String,
            "Selected",
            "Notification option is not selected",
        )
        return self
    }

    @discardableResult
    func selectAndVerify(_ notificationMode: NotificationMode) -> Self {
        select(notificationMode)
            .assertSelected(notificationMode)
    }

    func goBackToConversationDetails() throws -> ConversationDetailsPage {
        backButton.waitAndTap()
        return try ConversationDetailsPage()
    }
}

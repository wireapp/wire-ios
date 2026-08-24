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

class ConversationDetailsPage: PageModel {

    override var pageMainElement: XCUIElement {
        navigationTitleView
    }

    var navigationTitleView: XCUIElement {
        app.descendants(matching: .any)[Locators.ConversationDetailsPage.title.rawValue].firstMatch
    }

    var addParticipantsButton: XCUIElement {
        app.descendants(matching: .button)[Locators.ConversationDetailsPage.addParticipantsButton.rawValue].firstMatch
    }

    var closeConversationDetailsButton: XCUIElement {
        app.buttons[Locators.ConversationDetailsPage.close.rawValue]
    }

    var moreOptionsConversationDetailsButton: XCUIElement {
        app.buttons[Locators.ConversationDetailsPage.moreOptionsButton.rawValue]
    }

    var archiveOptionConversationDetailsButton: XCUIElement {
        app.buttons.matching(identifier: Locators.ConversationDetailsActions.archive.rawValue).element(boundBy: 0)
    }

    var clearContentOptionConversationDetailsButton: XCUIElement {
        app.buttons.matching(identifier: Locators.ConversationDetailsActions.clearContent.rawValue).element(boundBy: 0)
    }

    var leaveConversationOptionConversationDetailsButton: XCUIElement {
        app.buttons.matching(identifier: Locators.ConversationDetailsActions.leaveConversation.rawValue)
            .element(boundBy: 0)
    }

    var userCells: XCUIElementQuery {
        app.staticTexts.matching(identifier: Locators.ConversationDetailsPage.userCellName.rawValue)
    }

    var cannotLeaveAlert: XCUIElement {
        app.alerts.firstMatch
    }

    func userCell(named name: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        return userCells.matching(predicate).firstMatch
    }

    func adminCell(named name: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        return app.cells
            .matching(identifier: Locators.ConversationDetailsPage.adminCell.rawValue)
            .matching(predicate)
            .firstMatch
    }

    func memberCell(named name: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        return app.cells
            .matching(identifier: Locators.ConversationDetailsPage.memberCell.rawValue)
            .matching(predicate)
            .firstMatch
    }

    func openUserDetailsPage(byName name: String) throws -> UserDetailsPage {
        let predicate = NSPredicate(format: "label == %@", name)
        userCells.matching(predicate).firstMatch.tap()
        return try UserDetailsPage()
    }

    @discardableResult
    func closeConversationDetails() throws -> ActiveConversationPage {
        closeConversationDetailsButton.tap()
        return try ActiveConversationPage()
    }

    func moreOptionsConversationDetails() throws -> ConversationDetailsPage {
        moreOptionsConversationDetailsButton.tap()
        return try ConversationDetailsPage()
    }

    func archiveOptionsConversationDetails() throws -> ConversationsPage {
        archiveOptionConversationDetailsButton.tap()
        return try ConversationsPage()
    }

    func unarchiveOptionsConversationDetails() throws -> ConversationsPage {
        try archiveOptionsConversationDetails()
    }

    func clearContentOptionsConversationDetails() throws -> Self {
        clearContentOptionConversationDetailsButton.tap()
        return self
    }

    func leaveOptionsConversationDetails() throws -> Self {
        leaveConversationOptionConversationDetailsButton.tap()
        return self
    }

    func tapCannotLeaveAlert() throws -> Self {
        if cannotLeaveAlert.waitForExistence(timeout: 1) {
            cannotLeaveAlert.buttons.firstMatch.tap()
        }
        return self
    }

    func tapPromoteNewAdmin() throws -> AdminSelectionPage {
        promoteNewAdminButton.waitAndTap()
        return try AdminSelectionPage()
    }

    var promoteNewAdminButton: XCUIElement {
        app.buttons[Locators.LastAdminLeaveAlert.promoteNewAdmin.rawValue].firstMatch
    }

    func tapDeleteConversationAndConfirm() throws -> ConversationsPage {
        deleteConversationButton.waitAndTap()
        app.buttons[Locators.AlertActions.confirm.rawValue].firstMatch.waitAndTap()
        return try ConversationsPage()
    }

    var deleteConversationButton: XCUIElement {
        app.buttons[Locators.LastAdminLeaveAlert.deleteGroup.rawValue].firstMatch
    }

    var readReceiptsSwitch: XCUIElement {
        app.switches[Locators.ConversationDetailsPage.readReceiptsSwitch.rawValue].firstMatch
    }

    var notificationOptionsCell: XCUIElement {
        app.descendants(matching: .any)[Locators.ConversationDetailsPage.notificationOptionsCell.rawValue].firstMatch
    }

    @discardableResult
    func toggleGroupReadReceipts() -> ConversationDetailsPage {
        readReceiptsSwitch.waitAndTap()
        return self
    }

    func openNotificationOptions() throws -> ConversationNotificationOptionsPage {
        XCTAssertTrue(
            notificationOptionsCell.waitAndTap(),
            "Notification options cell did not appear"
        )
        return try ConversationNotificationOptionsPage()
    }

    @discardableResult
    func assertNotificationStatus(
        _ mode: ConversationNotificationOptionsPage.NotificationMode,
    ) -> Self {
        XCTAssertTrue(
            notificationOptionsCell.waitForExistence(timeout: 2),
            "Notification options cell did not appear",
        )
        XCTAssertTrue(
            notificationOptionsCell.label.contains(mode.title),
            "Notification options cell did not show \(mode.title)",
        )
        return self
    }

    func appParticipantToConversation() throws -> SelectParticipantsPage {
        addParticipantsButton.tap()
        return try SelectParticipantsPage()
    }

    @discardableResult
    func clearContent() throws -> ConversationDetailsPage {
        clearButtonOnBottomSheet.tap()
        clearButtonOnBottomSheet.waitToDisappear()
        return try ConversationDetailsPage()
    }

    @discardableResult
    func leaveConversation() throws -> ConversationDetailsPage {
        leaveConversationButtonOnBottomSheet.waitAndTap()
        return try ConversationDetailsPage()
    }

    @discardableResult
    func leaveAndClearConversation() throws -> ConversationDetailsPage {
        leaveAndClearConversationButtonOnBottomSheet.waitAndTap()
        leaveAndClearConversationButtonOnBottomSheet.waitToDisappear(andThenWaitFor: navigationTitleView)
        return self
    }

    var clearButtonOnBottomSheet: XCUIElement {
        app.buttons[Locators.ConversationsPage.clearButtonOnBottomSheet.rawValue].firstMatch
    }

    var leaveConversationButtonOnBottomSheet: XCUIElement {
        app.buttons[Locators.ConversationsPage.leaveButtonOnBottomSheet.rawValue].firstMatch
    }

    var leaveAndClearConversationButtonOnBottomSheet: XCUIElement {
        app.buttons[Locators.ConversationsPage.leaveAndClearButtonOnBottomSheet.rawValue].firstMatch
    }
}

class ConversationNotificationOptionsPage: PageModel {

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

    override var pageMainElement: XCUIElement {
        everythingOption
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
    func select(_ mode: NotificationMode) -> Self {
        XCTAssertTrue(
            option(mode).waitAndTap(),
            "Notification option did not appear"
        )
        return self
    }

    @discardableResult
    func assertSelected(
        _ mode: NotificationMode,
    ) -> Self {
        let option = option(mode)
        XCTAssertTrue(
            option.waitForExistence(timeout: 2),
            "Notification option did not appear",
        )
        XCTAssertTrue(
            waitUntilSelected(option),
            "Notification option is not selected",
        )
        return self
    }

    func goBackToConversationDetails() throws -> ConversationDetailsPage {
        XCTAssertTrue(
            backButton.waitAndTap(),
            "Notification options back button did not appear"
        )
        return try ConversationDetailsPage()
    }

    private func option(_ mode: NotificationMode) -> XCUIElement {
        app.descendants(matching: .any)[mode.locator.rawValue].firstMatch
    }

    private func selectedValue(for option: XCUIElement) -> String {
        (option.value as? String) ?? ""
    }

    private func waitUntilSelected(_ option: XCUIElement, timeout: TimeInterval = 3) -> Bool {
        let end = Date().addingTimeInterval(timeout)

        while Date() < end {
            if !selectedValue(for: option).isEmpty {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        return !selectedValue(for: option).isEmpty
    }
}

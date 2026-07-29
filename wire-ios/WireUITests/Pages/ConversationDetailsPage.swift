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

    @discardableResult
    func toggleGroupReadReceipts() -> ConversationDetailsPage {
        readReceiptsSwitch.waitAndTap()
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
        return try ConversationDetailsPage()
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

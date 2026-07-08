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

class ConversationsPage: PageModel {
    override var pageMainElement: XCUIElement {
        conversationsButton
    }

    var conversationsButton: XCUIElement {
        app.buttons[Locators.ConversationsPage.bottomBarRecentListButton.rawValue]
    }

    var settingsButton: XCUIElement {
        app.buttons[Locators.ConversationsPage.bottomBarSettingsButton.rawValue]
    }

    var archivedButton: XCUIElement {
        app.buttons[Locators.ConversationsPage.bottomBarArchivedButton.rawValue]
    }

    var plusButtonToCreateGroup: XCUIElement {
        app.descendants(matching: .any)[Locators.ConversationsPage.createGroupOrSearchButton.rawValue].firstMatch
    }

    var conversationCell: XCUIElement {
        app.buttons[Locators.ConversationsPage.conversationCell.rawValue]
    }

    func conversationCell(named name: String) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(
                format: "identifier == %@ AND label == %@",
                Locators.ConversationsPage.conversationCell.rawValue,
                name
            )
        ).firstMatch
    }

    var unreadMessagesCount: XCUIElement {
        app.staticTexts[Locators.ConversationsPage.unreadMessageCount.rawValue]
    }

    var textFilteredByFavourites: XCUIElement {
        app.staticTexts[Locators.ConversationsPage.textFilteredByFavourites.rawValue]
    }

    var textFilteredByGroups: XCUIElement {
        app.staticTexts[Locators.ConversationsPage.textFilteredByGroups.rawValue]
    }

    var textFilteredByChannels: XCUIElement {
        app.staticTexts[Locators.ConversationsPage.textFilteredByChannels.rawValue]
    }

    var textFilteredByOneOnOne: XCUIElement {
        app.staticTexts[Locators.ConversationsPage.textFilteredByOneOnOne.rawValue]
    }

    var blockButtonOnMoreOptions: XCUIElement {
        app.buttons[Locators.ConversationsPage.blockOptionOnContextMenu.rawValue]
    }

    var unblockButtonOnMoreOptions: XCUIElement {
        app.buttons[Locators.ConversationsPage.unblockOptionOnContextMenu.rawValue]
    }

    var clearButtonOnMoreOptions: XCUIElement {
        app.buttons[Locators.ConversationsPage.clearOptionOnContextMenu.rawValue]
    }

    var addFavouriteButtonOnMoreOptions: XCUIElement {
        app.buttons[Locators.ConversationsPage.addToFavourite.rawValue]
    }

    var removeFavouriteButtonOnMoreOptions: XCUIElement {
        app.buttons[Locators.ConversationsPage.removeFromFavourite.rawValue]
    }

    var filterByFavourite: XCUIElement {
        app.buttons[Locators.ConversationsPage.filterByFavourites.rawValue]
    }

    var filterByGroupConversation: XCUIElement {
        app.buttons[Locators.ConversationsPage.filterByGroups.rawValue]
    }

    var filterByChannelConversation: XCUIElement {
        app.buttons[Locators.ConversationsPage.filterByChannels.rawValue]
    }

    var filterByOneOnOneConversation: XCUIElement {
        app.buttons[Locators.ConversationsPage.filterByOneOnOneConversation.rawValue]
    }

    var filterConversationsButton: XCUIElement {
        app.buttons[Locators.ConversationsPage.filterConversations.rawValue]
    }

    var blockButtonOnBottomSheet: XCUIElement {
        app.buttons[Locators.ConversationsPage.blockButtonOnBottomSheet.rawValue].firstMatch
    }

    var clearButtonOnBottomSheet: XCUIElement {
        app.buttons[Locators.ConversationsPage.clearButtonOnBottomSheet.rawValue].firstMatch
    }

    var videoCallButton: XCUIElement {
        app.descendants(matching: .any)[Locators.ActiveConversationPage.videoCallBarButton.rawValue].firstMatch
    }

    var connectionsRequestCell: XCUIElement {
        app.cells[Locators.ConversationsPage.connectionRequestsCell.rawValue]
    }

    var accountProfileImageView: XCUIElement {
        app.buttons[Locators.ConversationsPage.accountProfileImageView.rawValue]
    }

    var mentionStatus: XCUIElement {
        app.otherElements[Locators.ConversationsPage.status.rawValue]
    }

    var loadBar: XCUIElement {
        app.descendants(matching: .any)[Locators.ConversationsPage.loadBar.rawValue]
    }

    func getGroupName() -> String? {
        conversationCell.label
    }

    func openSettings() throws -> SettingsPage {
        settingsButton.tap()
        return try SettingsPage()
    }

    func openArchived() throws -> ArchivedConversationsPage {
        archivedButton.tap()
        return try ArchivedConversationsPage()
    }

    func openUserProfilePage() throws -> UserProfilePage {
        try letTheSyncFinish()
        accountProfileImageView.waitAndTap()
        return try UserProfilePage()
    }

    func tapPlusButtonToCreateGroup() throws -> NewConversationPage {
        plusButtonToCreateGroup.tap()
        return try NewConversationPage()
    }

    func openPendingRequest() throws -> ConnectionRequestsPage {
        try letTheSyncFinish()

        let maxDuration: TimeInterval = 10
        guard connectionsRequestCell.waitForExistence(timeout: maxDuration) else {
            throw Error.connectionRequestsCellNotFound
        }

        connectionsRequestCell.tap()
        return try ConnectionRequestsPage()
    }

    func verifyDriveTabButtonIsHidden() {
        XCTAssertFalse(
            app.tabBars.buttons[Locators.ConversationsPage.bottomBarDriveButton.rawValue]
                .waitForExistence(timeout: 2)
        )
    }

    @discardableResult
    func openConversation() throws -> ActiveConversationPage {
        try letTheSyncFinish()
        XCTAssertTrue(conversationCell.waitForExistence(timeout: 5), "Conversation cell did not appear")

        let maxDuration: TimeInterval = 10
        let start = Date()

        while !videoCallButton.exists, Date().timeIntervalSince(start) < maxDuration {
            if conversationCell.isHittable {
                conversationCell.tap()
                break
            }
            RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        }
        return try ActiveConversationPage()
    }

    @discardableResult
    func openConversationWithGuest(groupName: String) throws -> ActiveConversationPage {
        try letTheSyncFinish()
        let groupConversationWithGuestCell = app.buttons
            .matching(
                NSPredicate(
                    format: "identifier == %@ AND label CONTAINS[c] %@",
                    Locators.ConversationsPage.conversationCell.rawValue,
                    groupName
                )
            )
            .firstMatch

        XCTAssertTrue(
            groupConversationWithGuestCell.waitForExistence(timeout: 5),
            "Group conversation with guest cell did not appear"
        )

        let maxDuration: TimeInterval = 10
        let start = Date()

        while !videoCallButton.exists, Date().timeIntervalSince(start) < maxDuration {
            if groupConversationWithGuestCell.isHittable {
                groupConversationWithGuestCell.tap()
                break
            }
            RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        }
        return try ActiveConversationPage()
    }

    @discardableResult
    func longPressForMoreOptionOnConversation() throws -> ConversationsPage {
        conversationCell.press(forDuration: 1.0)
        return try ConversationsPage()
    }

    @discardableResult
    func blockUser() throws -> ConversationsPage {
        blockButtonOnMoreOptions.tap()
        blockButtonOnBottomSheet.tap()
        return self
    }

    @discardableResult
    func unblockUser() throws -> ConversationsPage {
        unblockButtonOnMoreOptions.tap()
        blockButtonOnBottomSheet.tap()
        return self
    }

    @discardableResult
    func clearContent() throws -> ConversationsPage {
        clearButtonOnMoreOptions.tap()
        clearButtonOnBottomSheet.tap()
        return self
    }

    func tapConnectionRequestsCell() throws -> ConnectionRequestsPage {
        connectionsRequestCell.tap()
        return try ConnectionRequestsPage()
    }

    func getNameLabel() -> String? {
        conversationCell.label
    }

    func letTheSyncFinish() throws {
        loadBar.waitToDisappear()
    }

    func markConversationAsFavourite() throws -> ConversationsPage {
        addFavouriteButtonOnMoreOptions.tap()
        return self
    }

    func filterConversationByFavourite() throws -> ConversationsPage {
        filterConversationsButton.tap()
        filterByFavourite.tap()
        return self
    }

    func filterConversationByGroup() throws -> ConversationsPage {
        filterConversationsButton.tap()
        filterByGroupConversation.tap()
        return self
    }

    func filterConversationByChannel() throws -> ConversationsPage {
        filterConversationsButton.tap()
        filterByChannelConversation.tap()
        return self
    }

    func filterConversationByOneOnOne() throws -> ConversationsPage {
        filterConversationsButton.tap()
        filterByOneOnOneConversation.tap()
        return self
    }

    func getUnreadMessageCountValue() throws -> String {
        unreadMessagesCount.value as! String
    }

    enum Error: Swift.Error {
        case connectionRequestsCellNotFound
    }
}

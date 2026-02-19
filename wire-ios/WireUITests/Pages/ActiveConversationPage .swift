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

class ActiveConversationPage: PageModel {

    override var pageMainElement: XCUIElement {
        videoCallButton
    }

    var videoCallButton: XCUIElement {
        app.descendants(matching: .any)[Locators.ActiveConversationPage.videoCallBarButton.rawValue].firstMatch
    }

    var inputMessageField: XCUIElement {
        app.textViews[Locators.ActiveConversationPage.inputField.rawValue]
    }

    var sendButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.sendButton.rawValue]
    }

    var conversationBackButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.conversationBackButton.rawValue]
    }

    var senderNameLabel: XCUIElement {
        app.descendants(matching: .any)[Locators.ActiveConversationPage.authorName.rawValue].firstMatch
    }

    var messageLabels: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: Locators.ActiveConversationPage.message.rawValue)
    }

    var mentionButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.mentionButton.rawValue]
    }

    func getSenderName() -> String? {
        senderNameLabel.label
    }

    var conversationTitleButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.conversationTitleButton.rawValue]
    }

    var conversationDetailsButton: XCUIElement {
        app.buttons[Locators.ActiveConversationPage.conversationDetailsButton.rawValue]
    }

    var imageCell: XCUIElement {
        app.otherElements[Locators.ActiveConversationPage.imageCell.rawValue]
    }

    func fetchMessages() -> [String] {
        var messages: [String] = []
        for i in 0 ..< messageLabels.count {
            let element = messageLabels.element(boundBy: i)
            if let value = element.value as? String {
                // Normalize spaces inserted by UI
                let normalized = value.replacingOccurrences(of: "\u{00A0}", with: " ")
                messages.append(normalized)
            }
        }
        return messages
    }

    func sendMessage(_ message: String) throws -> ActiveConversationPage {
        try inputMessageField.tapIfKeyboardNotFocused().typeText(message)
        sendButton.tap()
        return self
    }

    func goBackToConversationPage() throws -> ConversationsPage {
        conversationBackButton.tap()
        return try ConversationsPage()
    }

    func openConversationDetails() throws -> ConversationDetailsPage {
        conversationTitleButton.tap()
        conversationDetailsButton.tap()
        return try ConversationDetailsPage()
    }

    func chooseUser(nameOfUser: String) {
        let predicate = NSPredicate(
            format: "identifier == %@ AND label == %@",
            Locators.ActiveConversationPage.userCellName.rawValue,
            nameOfUser
        )
        let user = app.staticTexts.matching(predicate).firstMatch
        user.tap()
    }

    func mentionUserAndSendMessage(nameOfUser: String,) throws -> ActiveConversationPage {
        mentionButton.tap()
        chooseUser(nameOfUser: nameOfUser)
        sendButton.tap()
        return self
    }
}

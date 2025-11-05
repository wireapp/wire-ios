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

import WireLocators
import XCTest

// class GroupConversationPage: PageModel {
//
//    override var pageMainElement: XCUIElement {
//        videoCallButton
//    }
//
//    var videoCallButton: XCUIElement {
//        app.descendants(matching: .any)[Locators.ActiveConversationPage.videoCallBarButton.rawValue].firstMatch
//    }
//
//    var typeMessageField: XCUIElement {
//        app.descendants(matching: .any)[Locators.ActiveConversationPage.inputField.rawValue].firstMatch
//    }
//
//    var sendButton: XCUIElement {
//        app.descendants(matching: .any)[Locators.ActiveConversationPage.sendButton.rawValue].firstMatch
//    }
//
//    var senderNameLabel: XCUIElement {
//        app.descendants(matching: .any)[Locators.ActiveConversationPage.authorName.rawValue].firstMatch
//    }
//
//    var messageLabels: XCUIElementQuery {
//        app.textViews.matching(identifier: "Message")
//    }
//
//    func sendMessage(input: String) throws -> GroupConversationPage {
//        try typeMessageField.tapIfKeyboardNotFocused().typeText(input)
//        sendButton.tap()
//        return self
//    }
//
//    func getSenderName() -> String? {
//        senderNameLabel.label
//    }
//
//    func getSentMessages() -> [String] {
//        var messages: [String] = []
//
//        for i in 0 ..< messageLabels.count {
//            let element = messageLabels.element(boundBy: i)
//            if let value = element.value as? String {
//                messages.append(value)
//            }
//        }
//        return messages
//    }
// }

//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import Foundation
import WireTesting
import XCTest
@testable import WireDataModel

class ZMConversationLastMessagesTest: ZMBaseManagedObjectTest {
    override class func setUp() {
        DeveloperFlag.storage = UserDefaults(suiteName: UUID().uuidString)!
        var flag = DeveloperFlag.proteusViaCoreCrypto
        flag.isOn = false

        super.setUp()
    }

    override class func tearDown() {
        super.tearDown()
        DeveloperFlag.storage = UserDefaults.standard
    }

    func createConversation(on moc: NSManagedObjectContext? = nil) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: moc ?? uiMOC)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        return conversation
    }

    func testThatItFetchesLastMessage() throws {
        // GIVEN
        let conversation = createConversation()

        // WHEN
        try (0 ... 40).forEach { i in
            let message = try conversation.appendText(content: "\(i)") as? ZMClientMessage
            message?.updateServerTimestamp(with: Double(i))
        }

        // THEN
        XCTAssertEqual(conversation.lastMessage?.textMessageData?.messageText, "40")
    }

    func testThatItFetchesLastMessagesWithLimit() throws {
        // GIVEN
        let conversation = createConversation()

        // WHEN
        try (0 ... 40).forEach { i in
            let message = try conversation.appendText(content: "\(i)") as? ZMClientMessage
            message?.updateServerTimestamp(with: Double(i))
        }

        // THEN
        let lastMessages = conversation.lastMessages(limit: 10)
        XCTAssertEqual(lastMessages.count, 10)
        XCTAssertEqual(lastMessages.last?.textMessageData?.messageText, "31")
        XCTAssertEqual(lastMessages.first?.textMessageData?.messageText, "40")
    }

    func testThatItFetchesLastMessages() throws {
        // GIVEN
        let conversation = createConversation()

        // WHEN
        try (0 ... 40).forEach { i in
            let message = try conversation.appendText(content: "\(i)") as? ZMClientMessage
            message?.updateServerTimestamp(with: Double(i))
        }

        // THEN
        let lastMessages = conversation.lastMessages()
        XCTAssertEqual(lastMessages.count, 41)
        XCTAssertEqual(lastMessages.last?.textMessageData?.messageText, "0")
        XCTAssertEqual(lastMessages.first?.textMessageData?.messageText, "40")
    }

    func testThatItDoesNotIncludeMessagesFromOtherConversations() throws {
        // GIVEN
        let conversation = createConversation()
        let otherConversation = createConversation()

        // WHEN
        try (1 ... 10).forEach { i in
            let message = try conversation.appendText(content: "\(i)") as? ZMClientMessage
            message?.updateServerTimestamp(with: Double(i))
        }

        try (1 ... 10).forEach { i in
            let message = try otherConversation.appendText(content: "Other \(i)") as? ZMClientMessage
            message?.updateServerTimestamp(with: Double(i))
        }

        // THEN
        let lastMessages = conversation.lastMessages()
        XCTAssertEqual(lastMessages.count, 10)
        XCTAssertEqual(lastMessages.last?.textMessageData?.messageText, "1")

        let otherLastMessages = otherConversation.lastMessages()
        XCTAssertEqual(otherLastMessages.last?.textMessageData?.messageText, "Other 1")
    }

    func testThatItReturnsMessageIfLastMessageIsEditedTextAndSentBySelfUser() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)

        // when
        let message = try conversation.appendText(content: "Test Message") as! ZMMessage
        message.sender = ZMUser.selfUser(in: uiMOC)
        message.markAsSent()
        message.textMessageData?.editText("Edited Test Message", mentions: [], fetchLinkPreview: true)

        // then
        XCTAssertEqual(conversation.lastEditableMessage, message)
    }
}

//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import XCTest
@testable import Wire

final class ConversationMessageSectionControllerTests: XCTestCase {

    // MARK: - Properties

    var context: ConversationMessageContext!
    var mockSelfUser: MockUserType!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        mockSelfUser = MockUserType.createDefaultSelfUser()
        context = ConversationMessageContext(isSameSenderAsPrevious: false,
                                             isTimeIntervalSinceLastMessageSignificant: false,
                                             isTimestampInSameMinuteAsPreviousMessage: false,
                                             isFirstMessageOfTheDay: false,
                                             isFirstUnreadMessage: false,
                                             isLastMessage: false,
                                             searchQueries: [],
                                             previousMessageIsKnock: false,
                                             spacing: 0)
    }

    // MARK: - tearDown

    override func tearDown() {
        context = nil
        mockSelfUser = nil

        super.tearDown()
    }

    // MARK: - Tests

    func testThatItReturnsCellsInCorrectOrder_Normal() {

        // GIVEN
        let section = ConversationMessageSectionController(message: MockMessage(), context: context)
        section.cellDescriptions.removeAll()
        section.useInvertedIndices = false

        // WHEN
        section.add(description: MockCellDescription<Bool>())
        section.add(description: MockCellDescription<String>())

        // THEN
        let cell1 = section.tableViewCellDescriptions[0]
        let cell2 = section.tableViewCellDescriptions[1]

        XCTAssertEqual(String(describing: cell1.baseType), "MockCellDescription<Bool>")
        XCTAssertEqual(String(describing: cell2.baseType), "MockCellDescription<String>")
    }

    func testThatItReturnsCellsInCorrectOrder_UpsideDown() {
        // GIVEN
        let section = ConversationMessageSectionController(message: MockMessage(), context: context)
        section.cellDescriptions.removeAll()
        section.useInvertedIndices = true

        // WHEN
        section.add(description: MockCellDescription<Bool>())
        section.add(description: MockCellDescription<String>())

        // THEN
        let cell1 = section.tableViewCellDescriptions[0]
        let cell2 = section.tableViewCellDescriptions[1]

        XCTAssertEqual(String(describing: cell1.baseType), "MockCellDescription<String>")
        XCTAssertEqual(String(describing: cell2.baseType), "MockCellDescription<Bool>")
    }

    func testThatWeDoShowSenderDetails_WhenIsNotSameSenderAsPrevious() {
        // GIVEN
        let message = MockMessageFactory.textMessage(
            withText: "Hello"
        )
        message.serverTimestamp = .today(at: 9, 41)
        message.senderUser = mockSelfUser

        context = ConversationMessageContext(isSameSenderAsPrevious: false,
                                             isTimeIntervalSinceLastMessageSignificant: false,
                                             isTimestampInSameMinuteAsPreviousMessage: false,
                                             isFirstMessageOfTheDay: false,
                                             isFirstUnreadMessage: false,
                                             isLastMessage: false,
                                             searchQueries: [],
                                             previousMessageIsKnock: false,
                                             spacing: 0)

        // WHEN
        let section = ConversationMessageSectionController(message: message, context: context)

        // THEN
        let conversationSenderMessageCellDescription = section.cellDescriptions.element(atIndex: 0)?.instance as? ConversationSenderMessageCellDescription
        XCTAssertNotNil(conversationSenderMessageCellDescription?.configuration.timestamp)

        let conversationTextMessageCellDescription = section.cellDescriptions.element(atIndex: 1)?.instance as? ConversationTextMessageCellDescription
        XCTAssertNotNil(conversationTextMessageCellDescription)

        let messageToolBoxCellDescription = section.cellDescriptions.element(atIndex: 2)?.instance as? ConversationMessageToolboxCellDescription
        XCTAssertEqual(messageToolBoxCellDescription?.message?.nonce, message.nonce)
        XCTAssertEqual(messageToolBoxCellDescription?.message?.deliveryState, message.deliveryState)

        XCTAssert(section.cellDescriptions.count == 3)
    }

    func testThatWeDontShowSenderDetails_WhenIsSameSenderAsPrevious() {
        // GIVEN
        let message = MockMessageFactory.textMessage(
            withText: "Welcome to Dub Dub"
        )
        message.serverTimestamp = .today(at: 9, 41)
        message.senderUser = mockSelfUser

        context = ConversationMessageContext(isSameSenderAsPrevious: true,
                                             isTimeIntervalSinceLastMessageSignificant: false,
                                             isTimestampInSameMinuteAsPreviousMessage: true,
                                             isFirstMessageOfTheDay: false,
                                             isFirstUnreadMessage: false,
                                             isLastMessage: false,
                                             searchQueries: [],
                                             previousMessageIsKnock: false,
                                             spacing: 0)

        // WHEN
        let section = ConversationMessageSectionController(message: message, context: context)

        // THEN
        let conversationSenderMessageCellDescription = section.cellDescriptions.element(atIndex: 0)?.instance as? ConversationSenderMessageCellDescription
        XCTAssertNil(conversationSenderMessageCellDescription)
        XCTAssertNil(conversationSenderMessageCellDescription?.configuration.timestamp)

        let conversationTextMessageCellDescription = section.cellDescriptions.element(atIndex: 0)?.instance as? ConversationTextMessageCellDescription
        XCTAssertNotNil(conversationTextMessageCellDescription)

        let messageToolBoxCellDescription = section.cellDescriptions.element(atIndex: 1)?.instance as? ConversationMessageToolboxCellDescription
        XCTAssertEqual(messageToolBoxCellDescription?.message?.nonce, message.nonce)
        XCTAssertEqual(messageToolBoxCellDescription?.message?.deliveryState, message.deliveryState)

        XCTAssert(section.cellDescriptions.count == 2)
    }

    func testThatWeShowSenderDetails_WhenPreviousMessageIsKnock() {
        // GIVEN
        let message = MockMessageFactory.textMessage(
            withText: "Welcome to Dub Dub 2023"
        )
        message.serverTimestamp = .today(at: 9, 41)
        message.senderUser = mockSelfUser

        context = ConversationMessageContext(isSameSenderAsPrevious: false,
                                             isTimeIntervalSinceLastMessageSignificant: false,
                                             isTimestampInSameMinuteAsPreviousMessage: false,
                                             isFirstMessageOfTheDay: false,
                                             isFirstUnreadMessage: false,
                                             isLastMessage: false,
                                             searchQueries: [],
                                             previousMessageIsKnock: true,
                                             spacing: 0)

        // WHEN
        let section = ConversationMessageSectionController(message: message, context: context)

        // THEN
        let conversationSenderMessageCellDescription = section.cellDescriptions.element(atIndex: 0)?.instance as? ConversationSenderMessageCellDescription
        XCTAssertNotNil(conversationSenderMessageCellDescription?.configuration.timestamp)

        let conversationTextMessageCellDescription = section.cellDescriptions.element(atIndex: 1)?.instance as? ConversationTextMessageCellDescription
        XCTAssertNotNil(conversationTextMessageCellDescription)

        let messageToolBoxCellDescription = section.cellDescriptions.element(atIndex: 2)?.instance as? ConversationMessageToolboxCellDescription
        XCTAssertEqual(messageToolBoxCellDescription?.message?.nonce, message.nonce)
        XCTAssertEqual(messageToolBoxCellDescription?.message?.deliveryState, message.deliveryState)

        XCTAssert(section.cellDescriptions.count == 3)
    }

    func testThatWeShowSenderDetails_WhenTimestampIsNotInSameMinuteAsPreviousMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(
            withText: "Let's discuss those things during tomorrow's standup"
        )
        message.serverTimestamp = .today(at: 9, 41)
        message.senderUser = mockSelfUser

        context = ConversationMessageContext(isSameSenderAsPrevious: true,
                                             isTimeIntervalSinceLastMessageSignificant: false,
                                             isTimestampInSameMinuteAsPreviousMessage: false,
                                             isFirstMessageOfTheDay: false,
                                             isFirstUnreadMessage: false,
                                             isLastMessage: false,
                                             searchQueries: [],
                                             previousMessageIsKnock: true,
                                             spacing: 0)

        // WHEN
        let section = ConversationMessageSectionController(message: message, context: context)

        // THEN
        let conversationSenderMessageCellDescription = section.cellDescriptions.element(atIndex: 0)?.instance as? ConversationSenderMessageCellDescription
        XCTAssertNotNil(conversationSenderMessageCellDescription?.configuration.timestamp)

        // We need to add small delay so configuration.timestamp isn't nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(conversationSenderMessageCellDescription?.configuration.timestamp as? Date, message.serverTimestamp)
        }

        let conversationTextMessageCellDescription = section.cellDescriptions.element(atIndex: 1)?.instance as? ConversationTextMessageCellDescription
        XCTAssertNotNil(conversationTextMessageCellDescription)

        let messageToolBoxCellDescription = section.cellDescriptions.element(atIndex: 2)?.instance as? ConversationMessageToolboxCellDescription
        XCTAssertEqual(messageToolBoxCellDescription?.message?.nonce, message.nonce)
        XCTAssertEqual(messageToolBoxCellDescription?.message?.deliveryState, message.deliveryState)

        XCTAssert(section.cellDescriptions.count == 3)
    }

}

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

import WireCommonComponents
import WireFoundation
import XCTest

@testable import Wire

final class ConversationMessageSectionControllerTests: XCTestCase {

    // MARK: - Properties

    var context: ConversationMessageContext!
    var mockSelfUser: MockUserType!
    var userSession: UserSessionMock!

    lazy var collapseOwnMessagesStorage = PrivateUserDefaults<CollapseKey>(userID: mockSelfUser.remoteIdentifier!)

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        mockSelfUser = MockUserType.createDefaultSelfUser()
        userSession = UserSessionMock(mockUser: mockSelfUser)
        context = ConversationMessageContext(
            isSameSenderAsPrevious: false,
            isTimestampInSameMinuteAsPreviousMessage: false,
            isFirstMessageOfTheDay: false,
            isFirstUnreadMessage: false,
            isLastMessage: false,
            searchQueries: [],
            previousMessageIsKnock: false,
            spacing: 0
        )
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
        let section = ConversationMessageSectionController(
            message: MockMessage(),
            context: context,
            userSession: userSession,
            useInvertedIndices: false,
            contentWidth: 0
        )
        section.cellDescriptionsForTesting.removeAll()

        // WHEN
        section.addForTesting(description: MockCellDescription<Bool>())
        section.addForTesting(description: MockCellDescription<String>())

        // THEN
        let cell1 = section.tableViewCellDescriptions[0]
        let cell2 = section.tableViewCellDescriptions[1]

        XCTAssertEqual(String(describing: cell1.baseType), "MockCellDescription<Bool>")
        XCTAssertEqual(String(describing: cell2.baseType), "MockCellDescription<String>")
    }

    func testThatItReturnsCellsInCorrectOrder_UpsideDown() {
        // GIVEN
        let section = ConversationMessageSectionController(
            message: MockMessage(),
            context: context,
            userSession: userSession,
            useInvertedIndices: true,
            contentWidth: 0
        )
        section.cellDescriptionsForTesting.removeAll()

        // WHEN
        section.addForTesting(description: MockCellDescription<Bool>())
        section.addForTesting(description: MockCellDescription<String>())

        // THEN
        let cell1 = section.tableViewCellDescriptions[0]
        let cell2 = section.tableViewCellDescriptions[1]

        XCTAssertEqual(String(describing: cell1.baseType), "MockCellDescription<String>")
        XCTAssertEqual(String(describing: cell2.baseType), "MockCellDescription<Bool>")
    }

    func testCellGrouping_SenderIsDifferentFromPrevious() throws {
        // Given
        let message = MockMessageFactory.textMessage(withText: "Hello")
        let context = ConversationMessageContext(isSameSenderAsPrevious: false)

        // When
        let section = ConversationMessageSectionController(
            message: message,
            context: context,
            userSession: userSession,
            useInvertedIndices: false,
            contentWidth: 0
        )

        // Then
        let cellDescriptions = section.cellDescriptionsForTesting
        guard
            cellDescriptions.count == 1,
            let stackViewCellDescription = cellDescriptions.first?.instance as? StackViewCellDescription,
            stackViewCellDescription.cellDescriptions.count == 3
        else { return XCTFail("Expected a single stack view cell description with three combined cells") }

        let stackedCellDescriptions = stackViewCellDescription.cellDescriptions
        XCTAssertTrue(stackedCellDescriptions[0].instance is ConversationSenderMessageCellDescription)
        XCTAssertTrue(stackedCellDescriptions[1].instance is ConversationTextMessageCellDescription)
        XCTAssertTrue(stackedCellDescriptions[2].instance is ConversationMessageToolboxCellDescription)
    }

    func testCellGrouping_SenderIsSameAsPreviousAndTimestampInSameMinuteAsPreviousMessage() throws {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Welcome to Dub Dub")
        let context = ConversationMessageContext(
            isSameSenderAsPrevious: true,
            isTimestampInSameMinuteAsPreviousMessage: true
        )

        // WHEN
        let section = ConversationMessageSectionController(
            message: message,
            context: context,
            userSession: userSession,
            useInvertedIndices: false,
            contentWidth: 0
        )

        // THEN
        let cellDescriptions = section.cellDescriptionsForTesting
        guard
            cellDescriptions.count == 1,
            let stackViewCellDescription = cellDescriptions.first?.instance as? StackViewCellDescription,
            stackViewCellDescription.cellDescriptions.count == 2
        else { return XCTFail("Expected a single stack view cell description with two combined cells") }

        let stackedCellDescriptions = stackViewCellDescription.cellDescriptions
        XCTAssertTrue(stackedCellDescriptions[0].instance is ConversationTextMessageCellDescription)
        XCTAssertTrue(stackedCellDescriptions[1].instance is ConversationMessageToolboxCellDescription)
    }

    func testCellGrouping_PreviousMessageIsKnock() throws {
        // Given
        let message = MockMessageFactory.textMessage(withText: "Hello")
        let context = ConversationMessageContext(previousMessageIsKnock: true)

        // When
        let section = ConversationMessageSectionController(
            message: message,
            context: context,
            userSession: userSession,
            useInvertedIndices: false,
            contentWidth: 0
        )

        // Then
        let cellDescriptions = section.cellDescriptionsForTesting
        guard
            cellDescriptions.count == 1,
            let stackViewCellDescription = cellDescriptions.first?.instance as? StackViewCellDescription,
            stackViewCellDescription.cellDescriptions.count == 3
        else { return XCTFail("Expected a single stack view cell description with three combined cells") }

        let stackedCellDescriptions = stackViewCellDescription.cellDescriptions
        XCTAssertTrue(stackedCellDescriptions[0].instance is ConversationSenderMessageCellDescription)
        XCTAssertTrue(stackedCellDescriptions[1].instance is ConversationTextMessageCellDescription)
        XCTAssertTrue(stackedCellDescriptions[2].instance is ConversationMessageToolboxCellDescription)
    }

    func testCellGrouping_SenderIsSameAsPreviousAndTimeStampIsNotInTheSameMinuteAsPreviousMessage() throws {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Hello")
        let context = ConversationMessageContext(
            isSameSenderAsPrevious: true,
            isTimestampInSameMinuteAsPreviousMessage: false
        )
        // WHEN
        let section = ConversationMessageSectionController(
            message: message,
            context: context,
            userSession: userSession,
            useInvertedIndices: false,
            contentWidth: 0
        )

        let cellDescriptions = section.cellDescriptionsForTesting
        guard
            cellDescriptions.count == 1,
            let stackViewCellDescription = cellDescriptions.first?.instance as? StackViewCellDescription,
            stackViewCellDescription.cellDescriptions.count == 3
        else { return XCTFail("Expected a single stack view cell description with three combined cells") }

        let stackedCellDescriptions = stackViewCellDescription.cellDescriptions
        XCTAssertTrue(stackedCellDescriptions[0].instance is ConversationSenderMessageCellDescription)
        XCTAssertTrue(stackedCellDescriptions[1].instance is ConversationTextMessageCellDescription)
        XCTAssertTrue(stackedCellDescriptions[2].instance is ConversationMessageToolboxCellDescription)
    }

    func testPassIsCollapsedToActionController() {
        let message = MockMessageFactory.textMessage(withText: "Hello")
        let context = ConversationMessageContext(
            isSameSenderAsPrevious: true,
            isTimestampInSameMinuteAsPreviousMessage: false
        )
        // WHEN
        let section = ConversationMessageSectionController(
            message: message,
            context: context,
            userSession: userSession,
            useInvertedIndices: false,
            contentWidth: 0
        )

        let actionController = ConversationMessageActionController(
            responder: nil,
            message: message,
            context: .content,
            view: UIView()
        )

        section.actionController = actionController

        XCTAssertEqual(section.isCollapsed, false)
        XCTAssertNil(actionController.isCollapsed)

        section.collapse()

        XCTAssertEqual(section.isCollapsed, true)
        XCTAssertEqual(actionController.isCollapsed, true)

        section.collapse()

        XCTAssertEqual(section.isCollapsed, false)
        XCTAssertEqual(actionController.isCollapsed, false)
    }

    func testInitialCollapseValue_systemMessage_collapseOwnMessagesDisabled() throws {
        let message = try XCTUnwrap(MockMessageFactory.systemMessage(with: .conversationNameChanged))
        let sut = makeSUT(message: message)
        XCTAssertTrue(sut.isCollapsed)
    }

    func testInitialCollapseValue_systemMessage_collapseOwnMessagesEnabled() throws {
        collapseOwnMessagesStorage.set(true, forKey: .collapseOwnMessages)
        let message = try XCTUnwrap(MockMessageFactory.systemMessage(with: .conversationNameChanged))
        let sut = makeSUT(message: message)
        XCTAssertTrue(sut.isCollapsed)
    }

    func testInitialCollapseValue_textMessageWithFailedToSendUsers_collapseOwnMessagesDisabled() throws {
        let message = try XCTUnwrap(
            MockMessageFactory.systemMessage(with: .domainsStoppedFederating)
        )
        message.failedToSendUsers = [MockUserType.createDefaultOtherUser()]
        let sut = makeSUT(message: message)
        XCTAssertTrue(sut.isCollapsed)
    }

    func testInitialCollapseValue_textMessageWithFailedToSendUsers_collapseOwnMessagesEnabled() throws {
        collapseOwnMessagesStorage.set(true, forKey: .collapseOwnMessages)
        let message = try XCTUnwrap(MockMessageFactory.systemMessage(with: .conversationNameChanged))
        message.failedToSendUsers = [MockUserType.createDefaultOtherUser()]
        let sut = makeSUT(message: message)
        XCTAssertTrue(sut.isCollapsed)
    }

    func testInitialCollapseValue_textMessage_collapseOwnMessagesDisabled() throws {
        let message = try XCTUnwrap(MockMessageFactory.textMessage(withText: "Hello"))
        let sut = makeSUT(message: message)
        XCTAssertFalse(sut.isCollapsed)
    }

    func testInitialCollapseValue_textMessage_collapseOwnMessagesEnabled() throws {
        collapseOwnMessagesStorage.set(true, forKey: .collapseOwnMessages)
        let message = try XCTUnwrap(MockMessageFactory.textMessage())
        let sut = makeSUT(message: message)
        XCTAssertFalse(sut.isCollapsed)
    }

    func testInitialCollapseValue_fileMessage_sentBySelfUser_collapseOwnMessagesDisabled() throws {
        let message = try XCTUnwrap(MockMessageFactory.fileTransferMessage())
        message.senderUser = mockSelfUser
        let sut = makeSUT(message: message)
        XCTAssertFalse(sut.isCollapsed)
    }

    func testInitialCollapseValue_fileMessage_sentBySelfUser_collapseOwnMessagesEnabled() throws {
        collapseOwnMessagesStorage.set(true, forKey: .collapseOwnMessages)
        let message = try XCTUnwrap(MockMessageFactory.fileTransferMessage())
        message.senderUser = mockSelfUser
        let sut = makeSUT(message: message)
        XCTAssertTrue(sut.isCollapsed)
    }

    func testInitialCollapseValue_fileMessage_sentByOtherUser_collapseOwnMessagesDisabled() throws {
        let message = try XCTUnwrap(MockMessageFactory.fileTransferMessage())
        message.senderUser = MockUserType.createDefaultOtherUser()
        let sut = makeSUT(message: message)
        XCTAssertFalse(sut.isCollapsed)
    }

    func testInitialCollapseValue_fileMessage_sentByOtherUser_collapseOwnMessagesEnabled() throws {
        collapseOwnMessagesStorage.set(true, forKey: .collapseOwnMessages)
        let message = try XCTUnwrap(MockMessageFactory.fileTransferMessage())
        message.senderUser = MockUserType.createDefaultOtherUser()
        let sut = makeSUT(message: message)
        XCTAssertFalse(sut.isCollapsed)
    }

    private func makeSUT(message: MockMessage) -> ConversationMessageSectionController {
        let context = ConversationMessageContext(
            isSameSenderAsPrevious: true,
            isTimestampInSameMinuteAsPreviousMessage: false
        )
        // WHEN
        let section = ConversationMessageSectionController(
            message: message,
            context: context,
            userSession: userSession,
            useInvertedIndices: false,
            contentWidth: 0
        )

        trackForMemoryLeaks(section)

        return section
    }

}

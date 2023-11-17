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
import WireCommonComponents
@testable import Wire

final class ConversationMessageSectionControllerTests: XCTestCase {

    // MARK: - Properties

    var context: ConversationMessageContext!
    var mockSelfUser: MockUserType!
    var userSession: UserSessionMock!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        mockSelfUser = MockUserType.createDefaultSelfUser()
        userSession = UserSessionMock(mockUser: mockSelfUser)
        context = ConversationMessageContext(isSameSenderAsPrevious: false,
                                             isTimeIntervalSinceLastMessageSignificant: false,
                                             isTimestampInSameMinuteAsPreviousMessage: false,
                                             isFirstMessageOfTheDay: false,
                                             isFirstUnreadMessage: false,
                                             isLastMessage: false,
                                             searchQueries: [],
                                             previousMessageIsKnock: false,
                                             spacing: 0)

        FontScheme.configure(with: .large)

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
            userSession: userSession
        )
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
        let section = ConversationMessageSectionController(message: MockMessage(), context: context, userSession: userSession)
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

    func testCellGrouping_SenderIsDifferentFromPrevious() throws {
        // Given
        let message = MockMessageFactory.textMessage(withText: "Hello")
        let context = ConversationMessageContext(isSameSenderAsPrevious: false)

        // When
        let section  = ConversationMessageSectionController(
            message: message,
            context: context,
            userSession: userSession
        )

        // Then
        let cellDescriptions = section.cellDescriptions
        guard cellDescriptions.count == 3 else {
            return XCTFail("Expected 3 cells")
        }

        XCTAssertTrue(cellDescriptions[0].instance is ConversationSenderMessageCellDescription)
        XCTAssertTrue(cellDescriptions[1].instance is ConversationTextMessageCellDescription)
        XCTAssertTrue(cellDescriptions[2].instance is ConversationMessageToolboxCellDescription)
    }

    func testCellGrouping_SenderIsSameAsPreviousAndTimestampInSameMinuteAsPreviousMessage() throws {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Welcome to Dub Dub")
        let context = ConversationMessageContext(isSameSenderAsPrevious: true,
                                                 isTimestampInSameMinuteAsPreviousMessage: true)

        // WHEN
        let section  = ConversationMessageSectionController(
            message: message,
            context: context,
            userSession: userSession
        )

        // THEN
        let cellDescriptions = section.cellDescriptions
        guard cellDescriptions.count == 2 else {
            return XCTFail("Expected 2 cells")
        }

        XCTAssertTrue(cellDescriptions[0].instance is ConversationTextMessageCellDescription)
        XCTAssertTrue(cellDescriptions[1].instance is ConversationMessageToolboxCellDescription)
    }

    func testCellGrouping_PreviousMessageIsKnock() throws {
        // Given
        let message = MockMessageFactory.textMessage(withText: "Hello")
        let context = ConversationMessageContext(previousMessageIsKnock: true)

        // When
        let section  = ConversationMessageSectionController(
            message: message,
            context: context, userSession: userSession
        )

        // Then
        let cellDescriptions = section.cellDescriptions
        guard cellDescriptions.count == 3 else {
            return XCTFail("Expected 3 cells")
        }

        XCTAssertTrue(cellDescriptions[0].instance is ConversationSenderMessageCellDescription)
        XCTAssertTrue(cellDescriptions[1].instance is ConversationTextMessageCellDescription)
        XCTAssertTrue(cellDescriptions[2].instance is ConversationMessageToolboxCellDescription)
    }

    func testCellGrouping_SenderIsSameAsPreviousAndTimeStampIsNotInTheSameMinuteAsPreviousMessage() throws {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Hello")
        let context = ConversationMessageContext(isSameSenderAsPrevious: true,
                                                 isTimestampInSameMinuteAsPreviousMessage: false)
        // WHEN
        let section  = ConversationMessageSectionController(
            message: message,
            context: context,
            userSession: userSession
        )

        let cellDescriptions = section.cellDescriptions
        guard cellDescriptions.count == 3 else {
            return XCTFail("Expected 3 cells")
        }

        XCTAssertTrue(cellDescriptions[0].instance is ConversationSenderMessageCellDescription)
        XCTAssertTrue(cellDescriptions[1].instance is ConversationTextMessageCellDescription)
        XCTAssertTrue(cellDescriptions[2].instance is ConversationMessageToolboxCellDescription)
    }

}

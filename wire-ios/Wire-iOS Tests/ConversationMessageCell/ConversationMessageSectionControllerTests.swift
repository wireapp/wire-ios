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

final class ConversationMessageSectionControllerTests: ZMSnapshotTestCase {

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

    func testThatWeDoNotShowSenderDetails_WhenIsSameSenderAsPrevious() {
        // GIVEN
        let message = MockMessageFactory.textMessage(
            withText: "Hello",
            sender: mockSelfUser
        )

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
        XCTAssertFalse(section.shouldShowSenderDetails(in: context))
    }

    func testThatWeShowSenderDetails_WhenIsNotSameSenderAsPrevious() {
        // GIVEN
        let message = MockMessageFactory.textMessage(
            withText: "Welcome to Dub Dub",
            sender: mockSelfUser
        )

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
        XCTAssertTrue(section.shouldShowSenderDetails(in: context))
    }

    func testIfWeShowSenderDetails_WhenPreviousMessageIsKnock() {
        // GIVEN
        let message = MockMessageFactory.textMessage(
            withText: "Welcome to Dub Dub",
            sender: mockSelfUser
        )

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
        XCTAssertTrue(section.shouldShowSenderDetails(in: context))
    }

}

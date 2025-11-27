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
import WireFoundationSupport
import XCTest

@testable import Wire

final class ConversationMessageSectionControllerTests: XCTestCase {

    // MARK: - Properties

    var context: ConversationMessageContext!
    var mockSelfUser: MockUserType!
    var userSession: UserSessionMock!
    var mockUserDefaults = UserDefaultsProtocolMock()

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
            previousMessageIsKnock: false
        )
        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = []
        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = false
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
        let section = makeSUT()
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
        let section = makeSUT(useInvertedIndices: true)
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
        let section = makeSUT(message: message, context: context)

        // Then
        let cellDescriptions = section.cellDescriptionsForTesting
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
        let context = ConversationMessageContext(
            isSameSenderAsPrevious: true,
            isTimestampInSameMinuteAsPreviousMessage: true
        )

        // WHEN
        let section = makeSUT(message: message, context: context)

        // THEN
        let cellDescriptions = section.cellDescriptionsForTesting
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
        let section = makeSUT(message: message, context: context)

        // Then
        let cellDescriptions = section.cellDescriptionsForTesting
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
        let context = ConversationMessageContext(
            isSameSenderAsPrevious: true,
            isTimestampInSameMinuteAsPreviousMessage: false
        )
        // WHEN
        let section = makeSUT(message: message, context: context)

        // THEN
        let cellDescriptions = section.cellDescriptionsForTesting
        guard cellDescriptions.count == 3 else {
            return XCTFail("Expected 3 cells")
        }

        XCTAssertTrue(cellDescriptions[0].instance is ConversationSenderMessageCellDescription)
        XCTAssertTrue(cellDescriptions[1].instance is ConversationTextMessageCellDescription)
        XCTAssertTrue(cellDescriptions[2].instance is ConversationMessageToolboxCellDescription)
    }

    func testPassIsCollapsedToActionController() {
        let message = MockMessageFactory.textMessage(withText: "Hello")
        let context = ConversationMessageContext(
            isSameSenderAsPrevious: true,
            isTimestampInSameMinuteAsPreviousMessage: false
        )
        // WHEN
        let section = makeSUT(message: message, context: context)

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
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()

//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = try XCTUnwrap(MockMessageFactory.systemMessage(with: .conversationNameChanged))
//        let sut = makeSUT(message: message)
//        XCTAssertTrue(sut.isCollapsed)
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
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()

//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = try XCTUnwrap(MockMessageFactory.systemMessage(with: .conversationNameChanged))
//        message.failedToSendUsers = [MockUserType.createDefaultOtherUser()]
//        let sut = makeSUT(message: message)
//        XCTAssertTrue(sut.isCollapsed)
    }

    func testInitialCollapseValue_textMessage_collapseOwnMessagesDisabled() throws {
        let message = try XCTUnwrap(MockMessageFactory.textMessage(withText: "Hello"))
        let sut = makeSUT(message: message)
        XCTAssertFalse(sut.isCollapsed)
    }

    func testInitialCollapseValue_textMessage_collapseOwnMessagesEnabled() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()

//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = try XCTUnwrap(MockMessageFactory.textMessage())
//        let sut = makeSUT(message: message)
//        XCTAssertFalse(sut.isCollapsed)
    }

    func testInitialCollapseValue_fileMessage_sentBySelfUser_collapseOwnMessagesDisabled() throws {
        let message = try XCTUnwrap(MockMessageFactory.fileTransferMessage())
        message.senderUser = mockSelfUser
        let sut = makeSUT(message: message)
        XCTAssertFalse(sut.isCollapsed)
    }

    func testInitialCollapseValue_fileMessage_sentBySelfUser_collapseOwnMessagesEnabled() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()

//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = try XCTUnwrap(MockMessageFactory.fileTransferMessage())
//        message.senderUser = mockSelfUser
//        let sut = makeSUT(message: message)
//        XCTAssertTrue(sut.isCollapsed)
    }

    func testInitialCollapseValue_fileMessage_sentByOtherUser_collapseOwnMessagesDisabled() throws {
        let message = try XCTUnwrap(MockMessageFactory.fileTransferMessage())
        message.senderUser = MockUserType.createDefaultOtherUser()
        let sut = makeSUT(message: message)
        XCTAssertFalse(sut.isCollapsed)
    }

    func testInitialCollapseValue_fileMessage_sentByOtherUser_collapseOwnMessagesEnabled() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()
        
//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = try XCTUnwrap(MockMessageFactory.fileTransferMessage())
//        message.senderUser = MockUserType.createDefaultOtherUser()
//        let sut = makeSUT(message: message)
//        XCTAssertFalse(sut.isCollapsed)
    }

    func testSavingWasUncollapsed_FileMessage() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()
        
//        // Given
//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = try XCTUnwrap(MockMessageFactory.fileTransferMessage())
//        message.senderUser = mockSelfUser
//        let nonce = message.nonce!.uuidString
//        let sut = makeSUT(message: message)
//        XCTAssertTrue(sut.isCollapsed)
//
//        let expectation = XCTestExpectation()
//        mockUserDefaults.setValueAnyForKeyDefaultNameStringVoidClosure = { value, _ in
//            XCTAssertEqual(value as? [String], [nonce])
//            expectation.fulfill()
//        }
//
//        // When: uncollapse
//        sut.collapse()
//        // Then
//        XCTAssertFalse(sut.isCollapsed)
//        wait(for: [expectation])
    }

    func testResetWasUncollapsed_FileMessage() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()
        
//        // Given already saved that was uncollapsed
//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = try XCTUnwrap(MockMessageFactory.fileTransferMessage())
//        message.senderUser = mockSelfUser
//        let nonce = message.nonce!.uuidString
//        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = [nonce]
//        // When
//        let sut = makeSUT(message: message)
//        // Then not collapsed
//        XCTAssertFalse(sut.isCollapsed)
//
//        // Given
//        let expectation = XCTestExpectation()
//        mockUserDefaults.setValueAnyForKeyDefaultNameStringVoidClosure = { value, _ in
//            XCTAssertEqual(value as? [String], [])
//            expectation.fulfill()
//        }
//        // When collapse back
//        sut.collapse()
//        // Then is collapsed and removed what was saved
//        XCTAssertTrue(sut.isCollapsed)
//        wait(for: [expectation])
    }

    func testWhenWasUncollapsedBefore_File() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()
        
//        // Given
//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = try XCTUnwrap(MockMessageFactory.fileTransferMessage())
//        message.senderUser = mockSelfUser
//        let nonce = message.nonce!.uuidString
//        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = [nonce]
//        // When
//        let sut = makeSUT(message: message)
//        // Then re-create expected to take into account that it was uncollapsed before and stay uncollapsed
//        XCTAssertFalse(sut.isCollapsed)
    }

    func testNotSavingWasUncollapsed_TextMessage() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()
        
//        // Given
//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let longText = """
//        one
//        two
//        three
//        four
//        """
//        let message = try XCTUnwrap(
//            MockMessageFactory.textMessage(withText: longText)
//        )
//        message.senderUser = mockSelfUser
//        let sut = makeSUT(message: message)
//        XCTAssertTrue(sut.isCollapsed)
//
//        let expectation = XCTestExpectation()
//        expectation.isInverted = true
//        mockUserDefaults.setValueAnyForKeyDefaultNameStringVoidClosure = { _, _ in
//            expectation.fulfill()
//        }
//
//        // When uncollapse
//        sut.collapse()
//        // Then not collapsed
//        XCTAssertFalse(sut.isCollapsed)
//        // And not saved
//        wait(for: [expectation], timeout: 0)
    }

    func testSavingWasUncollapsed_TextMessageWithLink() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()
        
//        // Given
//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = try XCTUnwrap(
//            MockMessageFactory.textMessageWithLinkAttachment(withText: "onetwothreefour")
//        )
//        message.senderUser = mockSelfUser
//        let sut = makeSUT(message: message)
//        XCTAssertTrue(sut.isCollapsed)
//
//        let expectation = XCTestExpectation()
//        mockUserDefaults.setValueAnyForKeyDefaultNameStringVoidClosure = { _, _ in
//            expectation.fulfill()
//        }
//
//        // When uncollapse
//        sut.collapse()
//        // Then after re-created expected to take into account that it was uncollapsed before and stay uncollapsed
//        XCTAssertFalse(sut.isCollapsed)
//        // And saved
//        wait(for: [expectation], timeout: 0)
    }

    func testNotCollapsed_TextMessageWithLink_SentByOther() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()
        
//        // Given
//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = try XCTUnwrap(
//            MockMessageFactory.textMessageWithLinkAttachment(withText: "onetwothreefour")
//        )
//        message.senderUser = MockUserType.createDefaultOtherUser()
//        // When
//        let sut = makeSUT(message: message)
//        // Then
//        XCTAssertFalse(sut.isCollapsed)
    }

    func testRecreatedCellBecomesCollapsed_LinkAttachmentMessage() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()
        
//        // Given
//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = MockMessageFactory.textMessage(withText: "www.example.com")
//        message.senderUser = mockSelfUser
//        let sut = makeSUT(message: message)
//        XCTAssertFalse(sut.isCollapsed)
//        XCTAssertEqual(sut.cellDescriptionsForTesting.count, 3)
//
//        // When
//        message.linkAttachments = [LinkAttachment(
//            type: .youTubeVideo,
//            title: "Lagar mat med Fernando Di Luca",
//            permalink: URL(string: "https://www.youtube.com/watch?v=l7aqpSTa234")!,
//            thumbnails: [],
//            originalRange: NSRange(location: 0, length: 5)
//        )]
//
//        sut.recreateCellDescriptions(in: sut.context)
//        // Then
//        XCTAssertEqual(sut.cellDescriptionsForTesting.count, 1)
//        XCTAssertTrue(sut.cellDescriptionsForTesting.first?.instance is ConversationCollapsedMessageCellDescription)
    }

    func testRecreatedCellNotBecomesCollapsed_LinkAttachmentMessage_FromOther() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()
        
//        // Given
//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = MockMessageFactory.textMessage(withText: "www.example.com")
//        message.senderUser = MockUserType()
//        let sut = makeSUT(message: message)
//        XCTAssertFalse(sut.isCollapsed)
//        XCTAssertEqual(sut.cellDescriptionsForTesting.count, 3)
//        // When
//        message.linkAttachments = [LinkAttachment(
//            type: .youTubeVideo,
//            title: "Lagar mat med Fernando Di Luca",
//            permalink: URL(string: "https://www.youtube.com/watch?v=l7aqpSTa234")!,
//            thumbnails: [],
//            originalRange: NSRange(location: 0, length: 5)
//        )]
//
//        sut.recreateCellDescriptions(in: sut.context)
//        // Then
//        XCTAssertEqual(sut.cellDescriptionsForTesting.count, 4)
    }

    func testRecreatedCellBecomesCollapsed_LinkPreviewMessage() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()
        
//        // Given
//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = MockMessageFactory.textMessage(withText: "www.example.com")
//        message.senderUser = mockSelfUser
//        let sut = makeSUT(message: message)
//        XCTAssertFalse(sut.isCollapsed)
//        XCTAssertEqual(sut.cellDescriptionsForTesting.count, 3)
//        // When
//        let textData = MockTextMessageData()
//        let article = ArticleMetadata(
//            originalURLString: "http://foo.bar/baz",
//            permanentURLString: "http://foo.bar/baz",
//            resolvedURLString: "http://foo.bar/baz",
//            offset: 0
//        )
//        textData.backingLinkPreview = article
//        message.backingTextMessageData = textData
//
//        sut.recreateCellDescriptions(in: sut.context)
//        // Then
//        XCTAssertEqual(sut.cellDescriptionsForTesting.count, 1)
//        XCTAssertTrue(sut.cellDescriptionsForTesting.first?.instance is ConversationCollapsedMessageCellDescription)
    }

    func testRecreatedCellNotBecomesCollapsed_LinkPreviewMessage_FromOther() throws {
        // Skipping test because collapsing own messages feature is
        // temporarily disabled due to conflicts with chat bubbles
        // https://wearezeta.atlassian.net/browse/WPB-18939
        
        throw XCTSkip()

//        // Given
//        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
//        let message = MockMessageFactory.textMessage(withText: "www.example.com")
//        message.senderUser = MockUserType()
//        let sut = makeSUT(message: message)
//        XCTAssertFalse(sut.isCollapsed)
//        XCTAssertEqual(sut.cellDescriptionsForTesting.count, 3)
//        // When
//        let textData = MockTextMessageData()
//        let article = ArticleMetadata(
//            originalURLString: "http://foo.bar/baz",
//            permanentURLString: "http://foo.bar/baz",
//            resolvedURLString: "http://foo.bar/baz",
//            offset: 0
//        )
//        textData.backingLinkPreview = article
//        message.backingTextMessageData = textData
//
//        sut.recreateCellDescriptions(in: sut.context)
//        // Then
//        XCTAssertEqual(sut.cellDescriptionsForTesting.count, 3)
    }

    private func makeSUT(
        message: MockMessage = MockMessage(),
        context: ConversationMessageContext? = nil,
        useInvertedIndices: Bool = false
    ) -> ConversationMessageSectionController {

        let section = ConversationMessageSectionController(
            message: message,
            context: context ?? self.context,
            selfUser: mockSelfUser,
            userSession: userSession,
            useInvertedIndices: useInvertedIndices,
            contentWidth: 0,
            userDefaults: mockUserDefaults
        )

        trackForMemoryLeaks(section)

        return section
    }

}

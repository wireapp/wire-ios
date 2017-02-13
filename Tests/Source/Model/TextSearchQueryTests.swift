//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


import ZMTesting
@testable import ZMCDataModel


fileprivate class MockTextSearchQueryDelegate: TextSearchQueryDelegate {

    var fetchedResults = [TextQueryResult]()

    fileprivate func textSearchQueryDidReceive(result: TextQueryResult) {
        fetchedResults.append(result)
    }
}


class TextSearchQueryTests: BaseZMClientMessageTests {

    func testThatItOnlyReturnsResultFromTheCorrectConversationNotYetIndexed() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        let otherConversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = conversation.appendMessage(withText: "This is the first message in the conversation") as! ZMMessage
        let otherMessage = otherConversation.appendMessage(withText: "This is the first message in the other conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 40, normalized: false)
        fillConversationWithMessages(conversation: otherConversation, messageCount: 40, normalized: false)
        [firstMessage, otherMessage].forEach {
            $0.normalizedText = nil
        }

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNil(firstMessage.normalizedText)
        XCTAssertNil(otherMessage.normalizedText)
        XCTAssertEqual(conversation.messages.count, 41)
        XCTAssertEqual(otherConversation.messages.count, 41)

        // When
        let delegate = MockTextSearchQueryDelegate()
        let sut = TextSearchQuery(conversation: conversation, query: "in the conversation", delegate: delegate)!
        sut.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        guard delegate.fetchedResults.count == 1 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)") }

        let result = delegate.fetchedResults.first!
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.matches.count, 1)

        let match = result.matches[0]
        XCTAssertEqual(match, firstMessage)
        verifyAllMessagesAreIndexed(in: conversation)
    }

    func testThatItOnlyReturnsResultFromTheCorrectConversationAlreadayIndexed() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        let otherConversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = conversation.appendMessage(withText: "This is the first message in the conversation") as! ZMMessage
        let otherMessage = otherConversation.appendMessage(withText: "This is the first message in the other conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 40, normalized: true)
        fillConversationWithMessages(conversation: otherConversation, messageCount: 40, normalized: true)

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(firstMessage.normalizedText)
        XCTAssertNotNil(otherMessage.normalizedText)
        XCTAssertEqual(conversation.messages.count, 41)
        XCTAssertEqual(otherConversation.messages.count, 41)

        // When
        let delegate = MockTextSearchQueryDelegate()
        let sut = TextSearchQuery(conversation: conversation, query: "in the conversation", delegate: delegate)!
        sut.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        guard delegate.fetchedResults.count == 1 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)") }

        let result = delegate.fetchedResults.first!
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.matches.count, 1)

        let match = result.matches[0]
        XCTAssertEqual(match, firstMessage)
        verifyAllMessagesAreIndexed(in: conversation)
    }

    func testThatItPopulatesTheNormalizedTextFieldAndReturnsTheQueryResults() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = conversation.appendMessage(withText: "This is the first message in the conversation") as! ZMMessage
        let secondMessage = conversation.appendMessage(withText: "This is the second message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 400, normalized: false)
        let lastMessage = conversation.appendMessage(withText: "This is the last message in the conversation") as! ZMMessage
        [firstMessage, secondMessage, lastMessage].forEach {
            $0.normalizedText = nil
        }

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNil(firstMessage.normalizedText)
        XCTAssertNil(secondMessage.normalizedText)
        XCTAssertNil(lastMessage.normalizedText)
        XCTAssertEqual(conversation.messages.count, 403)

        // When
        let delegate = MockTextSearchQueryDelegate()
        let sut = TextSearchQuery(conversation: conversation, query: "in the conversation", delegate: delegate)!
        sut.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        guard delegate.fetchedResults.count == 3 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)") }
        for result in delegate.fetchedResults.dropLast() {
            XCTAssertTrue(result.hasMore)
        }

        let finalResult = delegate.fetchedResults.last!
        XCTAssertFalse(finalResult.hasMore)
        XCTAssertEqual(finalResult.matches.count, 3)

        let (first, second, third) = (finalResult.matches[0], finalResult.matches[1], finalResult.matches[2])
        XCTAssertEqual(first.textMessageData?.messageText, lastMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(third.textMessageData?.messageText, firstMessage.textMessageData?.messageText)

        verifyAllMessagesAreIndexed(in: conversation)
    }

    func testThatItReturnsMatchesWhenAllMessagesAreIndexedInTheCorrectOrder() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = conversation.appendMessage(withText: "This is the first message in the conversation") as! ZMMessage
        firstMessage.serverTimestamp = Date()
        let secondMessage = conversation.appendMessage(withText: "This is the second message in the conversation") as! ZMMessage
        secondMessage.serverTimestamp = firstMessage.serverTimestamp?.addingTimeInterval(100)

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(firstMessage.normalizedText)
        XCTAssertNotNil(secondMessage.normalizedText)
        XCTAssertEqual(conversation.messages.count, 2)

        // When
        let delegate = MockTextSearchQueryDelegate()
        let sut = TextSearchQuery(conversation: conversation, query: "in the conversation", delegate: delegate)
        sut?.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        guard delegate.fetchedResults.count == 1 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)") }

        let result = delegate.fetchedResults.first!
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.matches.count, 2)

        let (first, second) = (result.matches[0], result.matches[1])
        XCTAssertEqual(first.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, firstMessage.textMessageData?.messageText)
    }


    func testThatItReturnsMatchesWhenAllMessagesAreIndexed() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = conversation.appendMessage(withText: "This is the first message in the conversation") as! ZMMessage
        let secondMessage = conversation.appendMessage(withText: "This is the second message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 400, normalized: true)
        let lastMessage = conversation.appendMessage(withText: "This is the last message in the conversation") as! ZMMessage

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(firstMessage.normalizedText)
        XCTAssertNotNil(secondMessage.normalizedText)
        XCTAssertNotNil(lastMessage.normalizedText)
        XCTAssertEqual(conversation.messages.count, 403)

        // When
        let delegate = MockTextSearchQueryDelegate()
        let sut = TextSearchQuery(conversation: conversation, query: "in the conversation", delegate: delegate)
        sut?.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        guard delegate.fetchedResults.count == 3 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)") }

        for fetchedResult in delegate.fetchedResults.dropLast() {
            XCTAssert(fetchedResult.hasMore)
        }

        let result = delegate.fetchedResults.last!
        XCTAssertFalse(result.hasMore)
        XCTAssertEqual(result.matches.count, 3)

        let (first, second, third) = (result.matches[0], result.matches[1], result.matches[2])
        XCTAssertEqual(first.textMessageData?.messageText, lastMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(third.textMessageData?.messageText, firstMessage.textMessageData?.messageText)
    }

    func testThatItReturnsAllMatchesWhenMultipleIndexedBatchesNeedToBeFetched() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        let firstMessage = conversation.appendMessage(withText: "This is the first message in the conversation") as! ZMMessage
        let secondMessage = conversation.appendMessage(withText: "This is the second message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 2, normalized: true)
        let lastMessage = conversation.appendMessage(withText: "This is the last message in the conversation") as! ZMMessage

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNotNil(firstMessage.normalizedText)
        XCTAssertNotNil(secondMessage.normalizedText)
        XCTAssertNotNil(lastMessage.normalizedText)
        XCTAssertEqual(conversation.messages.count, 5)

        // When
        let delegate = MockTextSearchQueryDelegate()
        let configuration = TextSearchQueryFetchConfiguration(notIndexedBatchSize: 2, indexedBatchSize: 2)
        let sut = TextSearchQuery(conversation: conversation, query: "in the conversation", delegate: delegate, configuration: configuration)
        sut?.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        guard delegate.fetchedResults.count == 3 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)") }

        let firstResult = delegate.fetchedResults.first!
        XCTAssertTrue(firstResult.hasMore)
        XCTAssertEqual(firstResult.matches.count, 2)

        let secondResult = delegate.fetchedResults.last!
        XCTAssertFalse(secondResult.hasMore)
        XCTAssertEqual(secondResult.matches.count, 3)

        let (first, second, third) = (firstResult.matches[0], firstResult.matches[1], secondResult.matches[2])
        XCTAssertEqual(first.textMessageData?.messageText, lastMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(third.textMessageData?.messageText, firstMessage.textMessageData?.messageText)
    }

    func testThatItReturnsAllMatchesIfMessagesAreNotYetAllIndexedAndIndexesNotIndexedMessages() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        // We insert old messages that have not yet been indexed
        let firstMessage = conversation.appendMessage(withText: "This is the first message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 200, normalized: false)
        let secondMessage = conversation.appendMessage(withText: "This is the second message in the conversation") as! ZMMessage
        fillConversationWithMessages(conversation: conversation, messageCount: 200, normalized: true)
        let lastMessage = conversation.appendMessage(withText: "This is the last message in the conversation") as! ZMMessage
        [firstMessage, secondMessage].forEach {
            $0.normalizedText = nil
        }

        XCTAssert(uiMOC.saveOrRollback())
        XCTAssertNil(firstMessage.normalizedText)
        XCTAssertNil(secondMessage.normalizedText)
        XCTAssertNotNil(lastMessage.normalizedText)
        XCTAssertEqual(conversation.messages.count, 403)

        // When
        let delegate = MockTextSearchQueryDelegate()
        let sut = TextSearchQuery(conversation: conversation, query: "in the conversation", delegate: delegate)!
        sut.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        guard delegate.fetchedResults.count == 4 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)") }
        for result in delegate.fetchedResults.dropLast() {
            XCTAssertTrue(result.hasMore)
        }

        let finalResult = delegate.fetchedResults.last!
        XCTAssertFalse(finalResult.hasMore)
        XCTAssertEqual(finalResult.matches.count, 3)

        let (first, second, third) = (finalResult.matches[0], finalResult.matches[1], finalResult.matches[2])
        XCTAssertEqual(first.textMessageData?.messageText, lastMessage.textMessageData?.messageText)
        XCTAssertEqual(second.textMessageData?.messageText, secondMessage.textMessageData?.messageText)
        XCTAssertEqual(third.textMessageData?.messageText, firstMessage.textMessageData?.messageText)

        verifyAllMessagesAreIndexed(in: conversation)
    }

    func testThatItFindsSpecialCharactersInNormalizedTextMessages() {
        verifyThatItFindsMessage(withText: "Hello Håkon", whenSearchingFor: "hakon")
        verifyThatItFindsMessage(withText: "Hello hakon", whenSearchingFor: "Håkon")
        verifyThatItFindsMessage(withText: "Hello björn", whenSearchingFor: "björn")
        verifyThatItFindsMessage(withText: "Hello björn", whenSearchingFor: "bjorn")
        verifyThatItFindsMessage(withText: "Let's meet in Saint-Étienne", whenSearchingFor: "etienne")
        verifyThatItFindsMessage(withText: "Let's meet in Saint-Etienne", whenSearchingFor: "ētienne")
        verifyThatItFindsMessage(withText: "Coração", whenSearchingFor: "Coracao")
        verifyThatItFindsMessage(withText: "Coracao", whenSearchingFor: "Coração")
        verifyThatItFindsMessage(withText: "❤️🍕", whenSearchingFor: "❤️🍕")
        verifyThatItFindsMessage(withText: "苹果", whenSearchingFor: "苹果")
        verifyThatItFindsMessage(withText: "苹果", whenSearchingFor: "Ping guo")
        verifyThatItFindsMessage(withText: "苹果", whenSearchingFor: "Ping")
        verifyThatItFindsMessage(withText: "苹果", whenSearchingFor: "gu")
        verifyThatItFindsMessage(withText: "Ping guo", whenSearchingFor: "苹果")
        verifyThatItFindsMessage(withText: "सेवफलम्", whenSearchingFor: "sevaphalam")
        verifyThatItFindsMessage(withText: "सेवफलम्", whenSearchingFor: "सेवफलम्")
        verifyThatItFindsMessage(withText: "sevaphalam", whenSearchingFor: "सेवफलम्")
        verifyThatItFindsMessage(withText: "μήλο", whenSearchingFor: "μήλο")
        verifyThatItFindsMessage(withText: "μήλο", whenSearchingFor: "melo")
        verifyThatItFindsMessage(withText: "Яблоко", whenSearchingFor: "abloko")
        verifyThatItFindsMessage(withText: "abloko", whenSearchingFor: "Яблоко")
        verifyThatItFindsMessage(withText: "خطای سطح دسترسی", whenSearchingFor: "khtay sth dstrsy")
        verifyThatItFindsMessage(withText: "khtay sth dstrsy", whenSearchingFor: "خطای سطح دسترسی")
        verifyThatItFindsMessage(withText: "תפוח", whenSearchingFor: "tpwh")
        verifyThatItFindsMessage(withText: "tpwh", whenSearchingFor: "תפוח")
        verifyThatItFindsMessage(withText: "ᑭᒻᒥᓇᐅᔭᖅ", whenSearchingFor: "ᑭᒻᒥᓇᐅᔭᖅ")
        verifyThatItFindsMessage(withText: "aa aa aa", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "aa.aa", whenSearchingFor: "aa")
        verifyThatItFindsMessage(withText: "11:45", whenSearchingFor: "11:45")
    }

    func testThatItUsesANDConjunctionForSearchTerms() {
        verifyThatItFindsMessage(withText: "This is a test message", whenSearchingFor: "this message")
        verifyThatItFindsMessage(withText: "This is a test message", whenSearchingFor: "this conversation", shouldFind: false)
    }

    func testThatItDoesNotCreateASearchQueryWithQuerySmallerThanTwoCharacters() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()

        // Then
        XCTAssertNil(TextSearchQuery(conversation: conversation, query: "", delegate: MockTextSearchQueryDelegate()))
        XCTAssertNil(TextSearchQuery(conversation: conversation, query: "a", delegate: MockTextSearchQueryDelegate()))
        XCTAssertNotNil(TextSearchQuery(conversation: conversation, query: "ab", delegate: MockTextSearchQueryDelegate()))
    }

    func testThatItDoesNotReturnsAnyResultsWithOnlyOneCharacterSearchTerms() {
        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        _ = conversation.appendMessage(withText: "aa bb a b c dd") as! ZMMessage
        XCTAssert(uiMOC.saveOrRollback())

        let delegate = MockTextSearchQueryDelegate()
        guard let sut = TextSearchQuery(conversation: conversation, query: "a b c d", delegate: delegate) else {
            return XCTFail("Should have created a `TextSearchQuery`")
        }

        // When
        sut.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        guard delegate.fetchedResults.count == 1 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)") }
        let result = delegate.fetchedResults.first!
        XCTAssertFalse(result.hasMore)

        XCTAssertTrue(result.matches.isEmpty, "Expected to not find a match")
    }

    // MARK: Helper

    func fillConversationWithMessages(conversation: ZMConversation, messageCount: Int, normalized: Bool) {
        for index in 0..<messageCount {
            let text = "This is the text message at index \(index)"
            let message = conversation.appendMessage(withText: text) as! ZMMessage
            if normalized {
                message.updateNormalizedText()
            } else {
                message.normalizedText = nil
            }
        }

        uiMOC.saveOrRollback()
    }

    func verifyAllMessagesAreIndexed(in conversation: ZMConversation, file: StaticString = #file, line: UInt = #line) {
        let predicate = ZMClientMessage.predicateForNotIndexedMessages()
                     && ZMClientMessage.predicateForMessages(inConversationWith: conversation.remoteIdentifier!)
        let request = ZMClientMessage.sortedFetchRequest(with: predicate)!
        let notIndexedMessageCount = (try? uiMOC.count(for: request)) ?? 0

        if notIndexedMessageCount > 0 {
            recordFailure(
                withDescription: "Found \(notIndexedMessageCount) messages in conversation",
                inFile: String(describing: file),
                atLine: line,
                expected: true
            )
        }
    }

    func verifyThatItFindsMessage(
        withText text: String,
        whenSearchingFor query: String,
        shouldFind: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
        ) {

        // Given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        let message = conversation.appendMessage(withText: text) as! ZMMessage
        XCTAssert(uiMOC.saveOrRollback(), file: file, line: line)

        // When
        let delegate = MockTextSearchQueryDelegate()
        let sut = TextSearchQuery(conversation: conversation, query: query, delegate: delegate)!
        sut.execute()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)

        // Then
        guard delegate.fetchedResults.count == 1 else { return XCTFail("Unexpected count \(delegate.fetchedResults.count)", file: file, line: line) }
        let result = delegate.fetchedResults.first!
        XCTAssertFalse(result.hasMore, file: file, line: line)

        if shouldFind {
            guard let match = result.matches.first else { return XCTFail("No match found", file: file, line: line) }
            XCTAssertEqual(match.textMessageData?.messageText, message.textMessageData?.messageText, file: file, line: line)
            verifyAllMessagesAreIndexed(in: conversation, file: file, line: line)
        } else {
            XCTAssertTrue(result.matches.isEmpty, "Expected to not find a match", file: file, line: line)
        }
    }

}

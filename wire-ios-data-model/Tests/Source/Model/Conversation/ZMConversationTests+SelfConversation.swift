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
@testable import WireDataModel

class ZMConversationTests_SelfConversation: ZMConversationTestsBase {
    // MARK: Internal

    // MARK: - Post last read

    func test_UpdateSelfConversationWithLastRead() throws {
        // Given self conversations
        let proteusSelfConversation = try XCTUnwrap(ZMConversation.selfConversation(in: uiMOC))
        let mlsSelfConversation = createMLSSelfConversation()

        // A conversation with a last read time stamp
        let conversationID = UUID.create()
        let lastReadTimestamp = Date(timeIntervalSince1970: 0)

        let conversation = createConversation(in: uiMOC)
        conversation.remoteIdentifier = conversationID
        conversation.lastReadServerTimeStamp = lastReadTimestamp

        // When
        try  ZMConversation.updateSelfConversation(withLastReadOf: conversation)

        // Then a last read message is posted in the proteus self conversation
        guard
            let lastProteusMessage = proteusSelfConversation.lastMessage as? ZMClientMessage,
            let proteusGenericMessage = lastProteusMessage.underlyingMessage,
            proteusGenericMessage.hasLastRead
        else {
            XCTFail("expected a last read generic message")
            return
        }

        let proteusLastRead = proteusGenericMessage.lastRead
        XCTAssertEqual(proteusLastRead.conversationID, conversationID.transportString())
        XCTAssertEqual(proteusLastRead.lastReadTimestamp, Int64(lastReadTimestamp.timeIntervalSince1970 * 1000))

        // Then a last read message is posted in the mls self conversation
        guard
            let lastMLSMessage = mlsSelfConversation.lastMessage as? ZMClientMessage,
            let mlsGenericMessage = lastMLSMessage.underlyingMessage,
            mlsGenericMessage.hasLastRead
        else {
            XCTFail("expected a last read generic message")
            return
        }

        let mlsLastRead = mlsGenericMessage.lastRead
        XCTAssertEqual(mlsLastRead.conversationID, conversationID.transportString())
        XCTAssertEqual(mlsLastRead.lastReadTimestamp, Int64(lastReadTimestamp.timeIntervalSince1970 * 1000))
    }

    // MARK: - Post cleared

    func test_UpdateSelfConversationWithCleared() throws {
        // Given self conversations
        let proteusSelfConversation = try XCTUnwrap(ZMConversation.selfConversation(in: uiMOC))
        let mlsSelfConversation = createMLSSelfConversation()

        // A conversation with a cleared time stamp
        let conversationID = UUID.create()
        let clearedTimestamp = Date(timeIntervalSince1970: 0)

        let conversation = createConversation(in: uiMOC)
        conversation.remoteIdentifier = conversationID
        conversation.clearedTimeStamp = clearedTimestamp

        // When
        try  ZMConversation.updateSelfConversation(withClearedOf: conversation)

        // Then a cleared message is posted in the proteus self conversation
        guard
            let lastProteusMessage = proteusSelfConversation.lastMessage as? ZMClientMessage,
            let proteusGenericMessage = lastProteusMessage.underlyingMessage,
            proteusGenericMessage.hasCleared
        else {
            XCTFail("expected a cleared generic message")
            return
        }

        let proteusCleared = proteusGenericMessage.cleared
        XCTAssertEqual(proteusCleared.conversationID, conversationID.transportString())
        XCTAssertEqual(proteusCleared.clearedTimestamp, Int64(clearedTimestamp.timeIntervalSince1970 * 1000))

        // Then a cleared message is posted in the mls self conversation
        guard
            let lastMLSMessage = mlsSelfConversation.lastMessage as? ZMClientMessage,
            let mlsGenericMessage = lastMLSMessage.underlyingMessage,
            mlsGenericMessage.hasCleared
        else {
            XCTFail("expected a cleared generic message")
            return
        }

        let mlsCleared = mlsGenericMessage.cleared
        XCTAssertEqual(mlsCleared.conversationID, conversationID.transportString())
        XCTAssertEqual(mlsCleared.clearedTimestamp, Int64(clearedTimestamp.timeIntervalSince1970 * 1000))
    }

    // MARK: - Process last read

    func testThatItUpdatesTheLastReadTimestamp() {
        // GIVEN
        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = nonce
        conversation.lastReadServerTimeStamp = Date(timeIntervalSince1970: 0)

        let timeinterval: Int64 = 10000
        let lastRead = LastRead.with {
            $0.conversationID = nonce.transportString()
            $0.lastReadTimestamp = timeinterval
        }

        // WHEN
        performPretendingUiMocIsSyncMoc {
            ZMConversation.updateConversation(
                withLastReadFromSelfConversation: lastRead,
                in: self.uiMOC
            )
        }
        uiMOC.saveOrRollback()

        // THEN
        XCTAssertEqual(conversation.lastReadServerTimeStamp, Date(timeIntervalSince1970: Double(timeinterval) / 1000))
    }

    // MARK: - Process cleared

    func testThatItUpdatesClearedTimestamp() {
        // GIVEN
        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = nonce
        conversation.clearedTimeStamp = Date(timeIntervalSince1970: 0)

        let timeinterval: Int64 = 10000
        let cleared = Cleared.with {
            $0.conversationID = nonce.transportString()
            $0.clearedTimestamp = timeinterval
        }

        // WHEN
        performPretendingUiMocIsSyncMoc {
            ZMConversation.updateConversation(
                withClearedFromSelfConversation: cleared,
                in: self.uiMOC
            )
        }
        uiMOC.saveOrRollback()

        // THEN
        XCTAssertEqual(conversation.clearedTimeStamp, Date(timeIntervalSince1970: Double(timeinterval) / 1000))
    }

    // MARK: Private

    private func createMLSSelfConversation() -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.mlsGroupID = .random()
        conversation.messageProtocol = .mls
        conversation.mlsStatus = .ready
        conversation.conversationType = .`self`
        return conversation
    }
}

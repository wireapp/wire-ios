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

import XCTest

@testable import WireDataModel

final class ZMMessageTests_GenericMessage: BaseZMClientMessageTests {
    func testThatItDoesNotSetTheServerTimestampFromEventDataEvenIfMessageAlreadyExists() throws {
        try syncMOC.performGroupedAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.remoteIdentifier = UUID.create()

            let nonce = UUID.create()

            let textMessage = GenericMessage(
                content: Text(content: self.name, mentions: [], linkPreviews: [], replyingTo: nil),
                nonce: nonce
            )
            let msg = ZMClientMessage(nonce: nonce, managedObjectContext: syncMOC)
            try msg.setUnderlyingMessage(textMessage)

            msg.visibleInConversation = conversation
            msg.serverTimestamp = Date(timeIntervalSinceReferenceDate: 400_000_000)

            let data: NSDictionary = try [
                "content": self.name,
                "nonce": XCTUnwrap(msg.nonce?.transportString()),
            ]
            let payload = self.payloadForMessage(
                in: conversation,
                type: EventConversationAdd,
                data: data,
                time: Date(timeIntervalSinceReferenceDate: 450_000_000)
            )
            let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)

            XCTAssertNotNil(event)

            // when
            msg.update(with: event!, for: conversation)

            // then
            XCTAssertEqual(msg.serverTimestamp!.timeIntervalSinceReferenceDate, 400_000_000, accuracy: 1)
        }
    }
}

// MARK: - KnockMessage

extension ZMMessageTests_GenericMessage {
    func testThatItCreatesOtrKnockMessageFromAnUpdateEvent() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let senderClientID = String.randomClientIdentifier()
        let nonce = UUID.create()
        let knockMessage = GenericMessage(content: Knock.with { $0.hotKnock = false }, nonce: nonce)

        let contentData = try XCTUnwrap(knockMessage.serializedData())
        let data: NSDictionary = [
            "sender": senderClientID,
            "text": contentData.base64String(),
        ]
        let payload = payloadForMessage(
            in: conversation,
            type: EventConversationAddOTRMessage,
            data: data,
            time: Date(timeIntervalSinceReferenceDate: 450_000_000)
        )
        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)

        // when
        var message: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            message = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.conversation, conversation)
        XCTAssertEqual(message?.sender?.remoteIdentifier.transportString(), payload["from"] as? String)
        XCTAssertEqual(message?.serverTimestamp?.transportString(), payload["time"] as? String)
        XCTAssertEqual(message?.senderClientID, senderClientID)
        XCTAssertEqual(message?.nonce, nonce)
    }

    func testThatAClientMessageHasKnockMessageData() throws {
        // given
        let knock = GenericMessage(content: Knock.with { $0.hotKnock = false }, nonce: UUID.create())
        let message = ZMClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        try message.setUnderlyingMessage(knock)

        // then
        XCTAssertNil(message.textMessageData?.messageText)
        XCTAssertNil(message.systemMessageData)
        XCTAssertNil(message.imageMessageData)
        XCTAssertNotNil(message.knockMessageData)
    }
}

// MARK: - Deletion

extension ZMMessageTests_GenericMessage {
    func testThatATextMessageGenericDataIsRemoved() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        // when
        let message = try! conversation.appendText(content: "Test") as! ZMOTRMessage
        let dataSet = message.dataSet

        XCTAssertNotNil(message.managedObjectContext)

        message.hideForSelfUser()
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(dataSet.count, 1)
        dataSet.compactMap { $0 as? ZMGenericMessageData }.forEach { messageData in
            XCTAssertNil(messageData.managedObjectContext)
        }
        XCTAssertNil(message.managedObjectContext)
    }

    func testThatATextMessageGenericDataIsRemoved_Asset() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        // when
        let message = try! conversation.appendImage(from: verySmallJPEGData()) as! ZMOTRMessage
        let dataSet = message.dataSet

        XCTAssertNotNil(message.managedObjectContext)

        message.hideForSelfUser()
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(dataSet.count, 1)
        dataSet.compactMap { $0 as? ZMGenericMessageData }.forEach { messageData in
            XCTAssertNil(messageData.managedObjectContext)
        }
        XCTAssertNil(message.managedObjectContext)
    }
}

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

final class ClientMessageTests: BaseZMClientMessageTests {
    override static func setUp() {
        super.setUp()
        DeveloperFlag.storage = UserDefaults(suiteName: UUID().uuidString)!
        var flag = DeveloperFlag.proteusViaCoreCrypto
        flag.isOn = false
    }

    override static func tearDown() {
        super.tearDown()
        DeveloperFlag.storage = UserDefaults.standard
    }

    func testThatItDoesNotCreateTextMessagesFromUpdateEventIfThereIsAlreadyAClientMessageWithTheSameNonce() {
        // given
        let nonce = UUID.create()

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let clientMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        clientMessage.visibleInConversation = conversation

        let data = [
            "content": name,
            "nonce": nonce.transportString(),
        ]

        let payload = payloadForMessage(in: conversation, type: EventConversationAdd, data: data)

        let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: TextMessage?
        performPretendingUiMocIsSyncMoc { [self] in
            sut = TextMessage.createOrUpdate(from: event!, in: uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNil(sut)
        XCTAssert(conversation.lastMessage == clientMessage)
    }

    func testThatItCreatesClientMessagesFromUpdateEvent() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let nonce = UUID.create()
        let message = GenericMessage(
            content: Text(content: name, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )
        let contentData = try XCTUnwrap(message.serializedData())
        let data = contentData.base64String()

        let payload = payloadForMessage(in: conversation, type: EventConversationAddClientMessage, data: data)
        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut?.conversation, conversation)
        XCTAssertTrue(conversation.needsToCalculateUnreadMessages)
        XCTAssertEqual(sut?.sender?.remoteIdentifier.transportString(), payload["from"] as? String)
        XCTAssertEqual(sut?.serverTimestamp?.transportString(), payload["time"] as? String)

        XCTAssertEqual(sut?.nonce, nonce)
        let messageData = try? sut?.underlyingMessage?.serializedData()
        XCTAssertEqual(messageData, contentData)
    }

    func testThatItCreatesOTRMessagesFromUpdateEvent() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let senderClientID: String = .randomClientIdentifier()
        let nonce = UUID.create()
        let message = GenericMessage(
            content: Text(content: name, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )
        let contentData = try XCTUnwrap(message.serializedData())

        let data: NSDictionary = [
            "sender": senderClientID,
            "text": contentData.base64String(),
        ]
        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRMessage, data: data)

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut?.conversation, conversation)
        XCTAssertTrue(conversation.needsToCalculateUnreadMessages)
        XCTAssertEqual(sut?.sender?.remoteIdentifier.transportString(), payload["from"] as? String)
        XCTAssertEqual(sut?.serverTimestamp?.transportString(), payload["time"] as? String)
        XCTAssertEqual(sut?.senderClientID, senderClientID)

        XCTAssertEqual(sut?.nonce, nonce)
        let messageData = try? sut?.underlyingMessage?.serializedData()
        XCTAssertEqual(messageData, contentData)
    }

    func testThatItIgnores_AnyAdditionalFieldsInTheLinkPreviewUpdate() throws {
        // given
        let initialText = "initial text"

        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let selfClient = createSelfClient()

        let existingMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        let message = GenericMessage(
            content: Text(content: initialText, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )

        try existingMessage.setUnderlyingMessage(message)

        existingMessage.visibleInConversation = conversation
        existingMessage.sender = selfUser
        existingMessage.senderClientID = selfClient.remoteIdentifier

        // We add a quote to the link preview update

        let linkPreview = LinkPreview.with {
            $0.url = "http://www.sunet.se"
            $0.permanentURL = "http://www.sunet.se"
            $0.urlOffset = 0
            $0.title = "Test"
        }
        let messageText = Text.with {
            $0.content = initialText
            $0.mentions = []
            $0.linkPreview = [linkPreview]
            $0.quote = Quote.with {
                $0.quotedMessageID = existingMessage.nonce?.transportString() ?? ""
                $0.quotedMessageSha256 = existingMessage.hashOfContent!
            }
        }
        let modifiedMessage = GenericMessage(content: messageText, nonce: nonce)

        let modifiedMessageData = try? modifiedMessage.serializedData().base64String()
        let data: NSDictionary = try [
            "sender": XCTUnwrap(selfClient.remoteIdentifier),
            "recipient": XCTUnwrap(selfClient.remoteIdentifier),
            "text": XCTUnwrap(modifiedMessageData),
        ]
        let payload = payloadForMessage(
            in: conversation,
            type: EventConversationAddOTRMessage,
            data: data,
            time: Date(),
            from: selfUser
        )

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNotNil(sut)
        XCTAssertNotNil(existingMessage.linkPreview)
        XCTAssertFalse(existingMessage.underlyingMessage!.textData!.hasQuote)
        XCTAssertEqual(existingMessage.textMessageData?.messageText, initialText)
    }

    func testThatItIgnoresBlacklistedLinkPreview() throws {
        // given
        let initialText = "initial text"

        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let selfClient = createSelfClient()

        let existingMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        let message = GenericMessage(
            content: Text(content: initialText, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )
        try existingMessage.setUnderlyingMessage(message)

        existingMessage.visibleInConversation = conversation
        existingMessage.sender = selfUser
        existingMessage.senderClientID = selfClient.remoteIdentifier

        // We add a quote to the link preview update
        let linkPreview = LinkPreview.with {
            $0.url = "http://www.youtube.com/watch"
            $0.permanentURL = "http://www.youtube.com/watch"
            $0.urlOffset = 0
            $0.title = "YouTube"
        }
        let messageText = Text.with {
            $0.content = initialText
            $0.mentions = []
            $0.linkPreview = [linkPreview]
            $0.quote = Quote.with {
                $0.quotedMessageID = existingMessage.nonce?.transportString() ?? ""
                $0.quotedMessageSha256 = existingMessage.hashOfContent!
            }
        }
        let modifiedMessage = GenericMessage(content: messageText, nonce: nonce)

        let modifiedMessageData = try modifiedMessage.serializedData().base64String()
        let data: NSDictionary = try [
            "sender": XCTUnwrap(selfClient.remoteIdentifier),
            "recipient": XCTUnwrap(selfClient.remoteIdentifier),
            "text": modifiedMessageData,
        ]
        let payload = payloadForMessage(
            in: conversation,
            type: EventConversationAddOTRMessage,
            data: data,
            time: Date(),
            from: selfUser
        )

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNotNil(sut)
        XCTAssertNotNil(existingMessage.firstZMLinkPreview)
        XCTAssertNil(existingMessage.linkPreview) // do not return a link preview even if it's included in the protobuf
        XCTAssertFalse(existingMessage.underlyingMessage!.textData!.hasQuote)
        XCTAssertEqual(existingMessage.textMessageData?.messageText, initialText)
    }

    func testThatItCanUpdateAnExistingLinkPreviewInTheDataSetWithoutCreatingMultipleOnes() throws {
        try syncMOC.performGroupedAndWait {
            // given
            let nonce = UUID.create()
            let message = ZMClientMessage(nonce: nonce, managedObjectContext: self.syncMOC)
            let otrKey = Data.randomEncryptionKey()
            let sha256 = Data.zmRandomSHA256Key()

            // when
            let remoteData = WireProtos.Asset.RemoteData.with {
                $0.otrKey = otrKey
                $0.sha256 = sha256
            }
            let asset = WireProtos.Asset.with {
                $0.uploaded = remoteData
            }
            let linkPreview = LinkPreview.with {
                $0.url = self.name
                $0.permanentURL = "www.example.de"
                $0.urlOffset = 0
                $0.title = "Title"
                $0.summary = "Summary"
                $0.image = asset
            }
            let text = Text.with {
                $0.content = self.name
                $0.linkPreview = [linkPreview]
            }
            let genericMessage = GenericMessage(content: text, nonce: nonce)
            try message.setUnderlyingMessage(genericMessage)

            // then
            XCTAssertEqual(message.dataSet.count, 1)
            switch message.underlyingMessage?.content {
            case let .text(data)?:
                XCTAssertNotNil(data)
            default:
                XCTFail()
            }
            XCTAssertEqual(message.underlyingMessage!.text.linkPreview.count, 1)

            // when
            var second = GenericMessage()
            try? second.merge(serializedData: message.underlyingMessage!.serializedData())
            var textSecond = second.text
            var linkPreviewSecond = second.text.linkPreview.first
            var assetSecond = linkPreviewSecond?.image
            var remoteSecond = linkPreviewSecond?.image.uploaded
            remoteSecond?.assetID = "Asset ID"
            remoteSecond?.assetToken = "Asset Token"

            assetSecond?.uploaded = remoteSecond!
            linkPreviewSecond?.image = assetSecond!
            textSecond.linkPreview = [linkPreviewSecond!]
            second.text = textSecond

            try message.setUnderlyingMessage(second)

            // then
            XCTAssertEqual(message.dataSet.count, 1)
            switch message.underlyingMessage?.content {
            case let .text(data)?:
                XCTAssertNotNil(data)
            default:
                XCTFail()
            }
            XCTAssertEqual(message.underlyingMessage!.text.linkPreview.count, 1)
            let remote = message.underlyingMessage?.text.linkPreview.first?.image.uploaded
            XCTAssertEqual(remote?.assetID, "Asset ID")
            XCTAssertEqual(remote?.assetToken, "Asset Token")
        }
    }
}

// MARK: - CreateClientMessageFromUpdateEvent

extension ClientMessageTests {
    func testThatItDoesNotCreateOTRMessageIfConversationIsForceReadonly() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        conversation.isForcedReadOnly = true

        let senderClientID: String = .randomClientIdentifier()
        let nonce = UUID.create()
        let prototype = GenericMessage(
            content: Text(content: name, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )

        let contentData = try prototype.serializedData()
        let data: NSDictionary = try [
            "sender": XCTUnwrap(senderClientID),
            "text": contentData.base64String(),
        ]
        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRMessage, data: data)
        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNil(sut)
    }

    func testThatItDoesNotCreateOTRMessageIfItsIdentifierIsInvalid() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let senderClientID: String = .randomClientIdentifier()
        let nonce = UUID.create()
        var prototype = GenericMessage(
            content: Text(content: name, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )
        prototype.messageID = "please-fail"

        let contentData = try prototype.serializedData()

        let data: NSDictionary = try [
            "sender": XCTUnwrap(senderClientID),
            "text": contentData.base64String(),
        ]
        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRMessage, data: data)

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNil(sut)
    }

    func testThatItDoesNotCreateKnockMessagesIfThereIsAlreadyOtrKnockWithTheSameNonce() throws {
        // given
        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let existingMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        let message = GenericMessage(content: WireProtos.Knock.with { $0.hotKnock = true }, nonce: UUID.create())
        try existingMessage.setUnderlyingMessage(message)
        existingMessage.visibleInConversation = conversation

        let data: NSDictionary = [
            "nonce": nonce.transportString(),
        ]
        let payload = payloadForMessage(in: conversation, type: EventConversationKnock, data: data)

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMKnockMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMKnockMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNil(sut)
        XCTAssertEqual(conversation.lastMessage as! ZMMessage, existingMessage)
    }

    func testThatItDoesNotCreateMessageFromAvailabilityMessage() throws {
        // given
        let senderClientID: String = .randomClientIdentifier()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let availability = WireProtos.Availability(.away)
        let contentData = try GenericMessage(content: availability, nonce: UUID.create()).serializedData()
        let data: NSDictionary = try [
            "sender": XCTUnwrap(senderClientID),
            "text": contentData.base64String(),
        ]
        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRMessage, data: data)

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNil(sut)
        XCTAssertEqual(conversation.allMessages.count, 0)
    }

    func testThatItIgnoresUpdates_OnAnAlreadyExistingClientMessageWithoutASenderClientID() throws {
        // given
        let initialText = "initial text"
        let modifiedText = "modified text"

        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let selfClient = createSelfClient()

        let existingMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        let message = GenericMessage(
            content: Text(content: initialText, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )
        try existingMessage.setUnderlyingMessage(message)
        existingMessage.visibleInConversation = conversation
        existingMessage.sender = selfUser

        let modifiedMessage = GenericMessage(
            content: Text(content: modifiedText, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )
        let contentData = try modifiedMessage.serializedData()
        let data: NSDictionary = try [
            "sender": XCTUnwrap(selfClient.remoteIdentifier),
            "recipient": XCTUnwrap(selfClient.remoteIdentifier),
            "text": contentData.base64String(),
        ]
        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRMessage, data: data)

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNil(sut)
        XCTAssertEqual(existingMessage.textMessageData!.messageText, initialText)
    }

    func testThatItIgnoresUpdates_OnAnAlreadyExistingClientMessageWithTheSameNonceButDifferentClient() throws {
        // given
        let initialText = "initial text"
        let modifiedText = "modified text"

        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let selfClient = createSelfClient()
        let unknownSender: String = .randomClientIdentifier()

        let existingMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        let message = GenericMessage(
            content: Text(content: initialText, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )
        try existingMessage.setUnderlyingMessage(message)
        existingMessage.visibleInConversation = conversation
        existingMessage.sender = selfUser
        existingMessage.senderClientID = selfClient.remoteIdentifier

        let modifiedMessage = GenericMessage(
            content: Text(content: modifiedText, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )

        let contentData = try modifiedMessage.serializedData()
        let data: NSDictionary = try [
            "sender": XCTUnwrap(unknownSender),
            "recipient": XCTUnwrap(selfClient.remoteIdentifier),
            "text": contentData.base64String(),
        ]
        let payload = payloadForMessage(in: conversation, type: EventConversationAddOTRMessage, data: data)

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNil(sut)
        XCTAssertEqual(existingMessage.textMessageData!.messageText, initialText)
    }

    func testThatItIgnoresUpdates_OnAnAlreadyExistingClientMessageWhichDoesntContainLinkPreviewUpdate() throws {
        // given
        let initialText = "initial text"
        let modifiedText = "modified text"

        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let selfClient = createSelfClient()

        let existingMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        let message = GenericMessage(
            content: Text(content: initialText, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: UUID.create()
        )
        try existingMessage.setUnderlyingMessage(message)
        existingMessage.visibleInConversation = conversation
        existingMessage.sender = selfUser
        existingMessage.senderClientID = selfClient.remoteIdentifier

        let modifiedMessage = GenericMessage(
            content: Text(content: modifiedText, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )

        let contentData = try modifiedMessage.serializedData()
        let data: NSDictionary = try [
            "sender": XCTUnwrap(selfClient.remoteIdentifier),
            "recipient": XCTUnwrap(selfClient.remoteIdentifier),
            "text": contentData.base64String(),
        ]
        let payload = payloadForMessage(
            in: conversation,
            type: EventConversationAddOTRMessage,
            data: data,
            time: Date(),
            from: selfUser
        )

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(existingMessage.textMessageData?.messageText, initialText)
    }

    func testThatItIgnoresUpdates_OnAnAlreadyExistingClientMessageWhichContainLinkPreviewUpdateButModifiedText() throws {
        // given
        let initialText = "initial text"
        let modifiedText = "modified text"
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: `modifiedText` is not used, is the text correct?
        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let selfClient = createSelfClient()

        let existingMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        let message = GenericMessage(
            content: Text(content: initialText, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: UUID.create()
        )
        try existingMessage.setUnderlyingMessage(message)
        existingMessage.visibleInConversation = conversation
        existingMessage.sender = selfUser
        existingMessage.senderClientID = selfClient.remoteIdentifier

        let linkPreview = LinkPreview.with {
            $0.url = "http://www.sunet.se"
            $0.permanentURL = "http://www.sunet.se"
            $0.urlOffset = 0
            $0.title = "Test"
        }
        let messageText = Text.with {
            $0.content = initialText
            $0.mentions = []
            $0.linkPreview = [linkPreview]
        }
        let modifiedMessage = GenericMessage(content: messageText, nonce: nonce)

        let contentData = try modifiedMessage.serializedData()
        let data: NSDictionary = try [
            "sender": XCTUnwrap(selfClient.remoteIdentifier),
            "recipient": XCTUnwrap(selfClient.remoteIdentifier),
            "text": contentData.base64String(),
        ]
        let payload = payloadForMessage(
            in: conversation,
            type: EventConversationAddOTRMessage,
            data: data,
            time: Date(),
            from: selfUser
        )

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNotNil(sut)
        XCTAssertEqual(existingMessage.textMessageData?.messageText, initialText)
    }

    func testThatItUpdates_AnAlreadyExistingClientMessageWhichContainLinkPreviewUpdate() throws {
        // given
        let initialText = "initial text"

        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let selfClient = createSelfClient()

        let existingMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        let message = GenericMessage(
            content: Text(content: initialText, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )
        try existingMessage.setUnderlyingMessage(message)
        existingMessage.visibleInConversation = conversation
        existingMessage.sender = selfUser
        existingMessage.senderClientID = selfClient.remoteIdentifier

        let linkPreview = LinkPreview.with {
            $0.url = "http://www.sunet.se"
            $0.permanentURL = "http://www.sunet.se"
            $0.urlOffset = 0
            $0.title = "Test"
        }
        let messageText = Text.with {
            $0.content = initialText
            $0.mentions = []
            $0.linkPreview = [linkPreview]
        }
        let modifiedMessage = GenericMessage(content: messageText, nonce: nonce)

        let contentData = try modifiedMessage.serializedData()
        let data: NSDictionary = try [
            "sender": XCTUnwrap(selfClient.remoteIdentifier),
            "recipient": XCTUnwrap(selfClient.remoteIdentifier),
            "text": contentData.base64String(),
        ]
        let payload = payloadForMessage(
            in: conversation,
            type: EventConversationAddOTRMessage,
            data: data,
            time: Date(),
            from: selfUser
        )

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNotNil(sut)
        XCTAssertNotNil(existingMessage.linkPreview)
        XCTAssertEqual(existingMessage.textMessageData?.messageText, initialText)
    }

    func testThatItUpdates_AnAlreadyExistingEphemeralClientMessageWhichContainLinkPreviewUpdate() throws {
        // given
        let initialText = "initial text"

        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let selfClient = createSelfClient()

        let existingMessage = ZMClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        let message = GenericMessage(
            content: Text(content: initialText, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce,
            expiresAfter: .oneHour
        )
        try existingMessage.setUnderlyingMessage(message)
        existingMessage.visibleInConversation = conversation
        existingMessage.sender = selfUser
        existingMessage.senderClientID = selfClient.remoteIdentifier

        let linkPreview = LinkPreview.with {
            $0.url = "http://www.sunet.se"
            $0.permanentURL = "http://www.sunet.se"
            $0.urlOffset = 0
            $0.title = "Test"
        }
        let messageText = Text.with {
            $0.content = initialText
            $0.mentions = []
            $0.linkPreview = [linkPreview]
        }
        let modifiedMessage = GenericMessage(content: messageText, nonce: nonce, expiresAfter: .oneHour)

        let contentData = try? modifiedMessage.serializedData()
        let data: NSDictionary = try [
            "sender": XCTUnwrap(selfClient.remoteIdentifier),
            "recipient": XCTUnwrap(selfClient.remoteIdentifier),
            "text": XCTUnwrap(contentData?.base64String()),
        ]
        let payload = payloadForMessage(
            in: conversation,
            type: EventConversationAddOTRMessage,
            data: data,
            time: Date(),
            from: selfUser
        )

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: nil)
        }

        // then
        XCTAssertNotNil(sut)
        XCTAssertTrue(existingMessage.isEphemeral)
        XCTAssertNotNil(existingMessage.linkPreview)
        XCTAssertEqual(existingMessage.textMessageData?.messageText, initialText)
    }

    func testThatItReturnsNilIfTheClientMessageIsZombie() throws {
        // given
        let nonce = UUID.create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let existingMessage = try! conversation.appendText(content: "Initial") as! ZMClientMessage
        existingMessage.nonce = nonce
        existingMessage.visibleInConversation = conversation
        let message = GenericMessage(
            content: Text(content: name, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )

        let contentData = try XCTUnwrap(message.serializedData())
        let data = contentData.base64String()

        let payload = payloadForMessage(in: conversation, type: EventConversationAddClientMessage, data: data)

        let event = ZMUpdateEvent.eventFromEventStreamPayload(payload, uuid: nil)
        XCTAssertNotNil(event)

        let prefetch = ZMFetchRequestBatch()
        prefetch.addNonces(toPrefetchMessages: [existingMessage.nonce!])
        let prefetchResult = prefetch.execute(in: uiMOC)
        XCTAssertEqual(prefetchResult?.messagesByNonce[existingMessage.nonce!]?.count, 1)
        XCTAssertEqual(prefetchResult?.messagesByNonce[existingMessage.nonce!]?.first, existingMessage)
        XCTAssertFalse(existingMessage.isZombieObject)

        // when
        uiMOC.delete(existingMessage)
        uiMOC.saveOrRollback()

        // then
        XCTAssertTrue(existingMessage.isZombieObject)

        // when
        var sut: ZMClientMessage?
        performPretendingUiMocIsSyncMoc {
            self.performIgnoringZMLogError {
                sut = ZMClientMessage.createOrUpdate(from: event!, in: self.uiMOC, prefetchResult: prefetchResult)
            }
        }

        // then
        XCTAssertNil(sut)
    }
}

// MARK: - ExternalMessage

extension ClientMessageTests {
    func testThatItDecryptsMessageWithExternalBlobCorrectly() {
        // given
        syncMOC.performGroupedAndWait {
            self.createSelfClient(onMOC: self.syncMOC)
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            let firstClient = self.createClient(for: otherUser, createSessionWithSelfUser: true, onMOC: self.syncMOC)

            let messageEvent = self.encryptedExternalMessageFixtureWithBlob(from: firstClient)
            let base64SHA = "kKSSlbMxXEdd+7fekxB8Qr67/mpjjboBsr2wLcW7wzE="
            let base64OTRKey = "4H1nD6bG2sCxC/tZBnIG7avLYhkCsSfv0ATNqnfug7w="
            let external = External(
                withOTRKey: Data(base64Encoded: base64OTRKey)!,
                sha256: Data(base64Encoded: base64SHA)!
            )

            // when
            let message = GenericMessage(from: messageEvent!, withExternal: external)

            // then
            XCTAssertNotNil(message)
            XCTAssertEqual(message?.text.content, self.expectedExternalMessageText())
        }
    }
}

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
import WireCryptobox
import WireDataModel
import WireProtos
import XCTest
@testable import WireDataModelSupport
@testable import WireRequestStrategy

final class EventDecoderDecryptionTests: MessagingTestBase {
    func testThatItCanDecryptOTRMessageAddEvent() async throws {
        // GIVEN
        let lastEventIDRepository = MockLastEventIDRepositoryInterface()
        let sut = EventDecoder(
            eventMOC: eventMOC,
            syncMOC: syncMOC,
            lastEventIDRepository: lastEventIDRepository
        )
        let text = "Trentatre trentini andarono a Trento tutti e trentatre trotterellando"
        let generic = GenericMessage(content: Text(content: text))

        // WHEN
        let decryptedEvent = try await decryptedUpdateEventFromOtherClient(
            message: generic,
            eventDecoder: sut
        )

        await syncMOC.performGrouped {
            // THEN
            XCTAssertEqual(decryptedEvent.senderUUID, self.otherUser.remoteIdentifier!)
            XCTAssertEqual(decryptedEvent.recipientClientID, self.selfClient.remoteIdentifier!)

            guard let decryptedMessage = ZMClientMessage.createOrUpdate(
                from: decryptedEvent,
                in: self.syncMOC,
                prefetchResult: nil
            ) else {
                return XCTFail("Failed to create client message")
            }
            XCTAssertEqual(decryptedMessage.nonce?.transportString(), generic.messageID)
            XCTAssertEqual(decryptedMessage.textMessageData?.messageText, text)
        }
    }

    func testThatItCanDecryptOTRAssetAddEvent() async throws {
        // GIVEN
        let lastEventIDRepository = MockLastEventIDRepositoryInterface()
        let sut = EventDecoder(
            eventMOC: eventMOC,
            syncMOC: syncMOC,
            lastEventIDRepository: lastEventIDRepository
        )
        let image = verySmallJPEGData()
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: image)
        let properties = ZMIImageProperties(size: imageSize, length: UInt(image.count), mimeType: "image/jpg")
        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(), sha256: image.zmSHA256Digest())
        let generic = GenericMessage(content: ImageAsset(
            mediumProperties: properties,
            processedProperties: properties,
            encryptionKeys: keys,
            format: .medium
        ))

        // WHEN
        let decryptedEvent = try await decryptedAssetUpdateEventFromOtherClient(
            message: generic,
            eventDecoder: sut
        )

        await syncMOC.perform {
            // THEN
            guard let decryptedMessage = ZMAssetClientMessage.createOrUpdate(
                from: decryptedEvent,
                in: self.syncMOC,
                prefetchResult: nil
            ) else {
                return XCTFail("Failed to create client message")
            }

            XCTAssertEqual(decryptedMessage.nonce?.transportString(), generic.messageID)
        }
    }

    func testThatItInsertsAUnableToDecryptMessageIfItCanNotEstablishASession() async throws {
        // GIVEN
        let lastEventIDRepository = MockLastEventIDRepositoryInterface()
        let sut = EventDecoder(
            eventMOC: eventMOC,
            syncMOC: syncMOC,
            lastEventIDRepository: lastEventIDRepository
        )
        var event: ZMUpdateEvent!

        await syncMOC.perform {
            let innerPayload = [
                "recipient": self.selfClient.remoteIdentifier!,
                "sender": self.otherClient.remoteIdentifier!,
                "id": UUID.create().transportString(),
                "key": Data("bah".utf8).base64String(),
            ]

            let payload = [
                "type": "conversation.otr-message-add",
                "from": self.otherUser.remoteIdentifier!.transportString(),
                "data": innerPayload,
                "conversation": self.groupConversation.remoteIdentifier!.transportString(),
                "time": Date().transportString(),
            ] as [String: Any]
            let wrapper = [
                "id": UUID.create().transportString(),
                "payload": [payload],
            ] as [String: Any]

            event = ZMUpdateEvent.eventsArray(from: wrapper as NSDictionary, source: .download)!.first!
        }

        // WHEN
        disableZMLogError(true)
        let keystore = await syncMOC.perform { self.syncMOC.zm_cryptKeyStore }
        let unwrappedKeyStore = try XCTUnwrap(keystore)
        await unwrappedKeyStore.encryptionContext.performAsync { session in
            _ = await sut.decryptProteusEventAndAddClient(event, in: self.syncMOC) { sessionID, encryptedData in
                try session.decryptData(encryptedData, for: sessionID.mapToEncryptionSessionID())
            }
        }
        disableZMLogError(false)

        await syncMOC.perform {
            // THEN
            guard let lastMessage = self.groupConversation.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(lastMessage.systemMessageType, .decryptionFailed)
        }
    }

    func testThatItInsertsAnUnableToDecryptMessageIfTheEncryptedPayloadIsLongerThan_18_000() async throws {
        // Given
        let lastEventIDRepository = MockLastEventIDRepositoryInterface()
        let sut = EventDecoder(
            eventMOC: eventMOC,
            syncMOC: syncMOC,
            lastEventIDRepository: lastEventIDRepository
        )
        let crlf = "\u{0000}\u{0001}\u{0000}\u{000D}\u{0000A}"
        let text = "https://wir\("".padding(toLength: crlf.count * 20000, withPad: crlf, startingAt: 0))e.com/"
        XCTAssertGreaterThan(text.count, 18000)
        let message = GenericMessage(content: Text(content: text))

        let wrapper = await syncMOC.perform {
            NSDictionary(dictionary: [
                "id": UUID.create().transportString(),
                "payload": [
                    [
                        "type": "conversation.otr-message-add",
                        "from": self.otherUser.remoteIdentifier!.transportString(),
                        "conversation": self.groupConversation.remoteIdentifier!.transportString(),
                        "time": Date().transportString(),
                        "data": [
                            "recipient": self.selfClient.remoteIdentifier!,
                            "sender": self.otherClient.remoteIdentifier!,
                            "text": self.encryptedMessageToSelf(message: message, from: self.otherClient)
                                .base64String(),
                        ],
                    ],
                ],
            ])
        }

        let event = try XCTUnwrap(ZMUpdateEvent.eventsArray(from: wrapper, source: .download)?.first)

        // When
        disableZMLogError(true)
        let keystore = await syncMOC.perform { self.syncMOC.zm_cryptKeyStore }
        let unwrappedKeyStore = try XCTUnwrap(keystore)
        await unwrappedKeyStore.encryptionContext.performAsync { session in
            _ = await sut.decryptProteusEventAndAddClient(event, in: self.syncMOC) { sessionID, encryptedData in
                try session.decryptData(encryptedData, for: sessionID.mapToEncryptionSessionID())
            }
        }
        disableZMLogError(false)

        // Then
        await syncMOC.perform {
            guard let lastMessage = self.groupConversation.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(lastMessage.systemMessageType, .decryptionFailed)
        }
    }

    func testThatItInsertsAnUnableToDecryptMessageIfTheEncryptedPayloadIsLongerThan_18_000_External_Message(
    ) async throws {
        // Given
        let lastEventIDRepository = MockLastEventIDRepositoryInterface()
        let sut = EventDecoder(
            eventMOC: eventMOC,
            syncMOC: syncMOC,
            lastEventIDRepository: lastEventIDRepository
        )
        let crlf = "\u{0000}\u{0001}\u{0000}\u{000D}\u{0000A}"
        let text = "https://wir\("".padding(toLength: crlf.count * 20000, withPad: crlf, startingAt: 0))e.com/"
        XCTAssertGreaterThan(text.count, 18000)

        let wrapper = await syncMOC.perform {
            NSDictionary(dictionary: [
                "id": UUID.create().transportString(),
                "payload": [
                    [
                        "type": "conversation.otr-message-add",
                        "from": self.otherUser.remoteIdentifier!.transportString(),
                        "conversation": self.groupConversation.remoteIdentifier!.transportString(),
                        "time": Date().transportString(),
                        "data": [
                            "data": text,
                            "recipient": self.selfClient.remoteIdentifier!,
                            "sender": self.otherClient.remoteIdentifier!,
                            "text": Data("something with less than 18000 characters count".utf8).base64String(),
                        ],
                    ],
                ],
            ])
        }

        let event = try XCTUnwrap(ZMUpdateEvent.eventsArray(from: wrapper, source: .download)?.first)

        // When
        disableZMLogError(true)
        let keystore = await syncMOC.perform { self.syncMOC.zm_cryptKeyStore }
        let unwrappedKeyStore = try XCTUnwrap(keystore)
        await unwrappedKeyStore.encryptionContext.performAsync { session in
            _ = await sut.decryptProteusEventAndAddClient(event, in: self.syncMOC) { sessionID, encryptedData in
                try session.decryptData(encryptedData, for: sessionID.mapToEncryptionSessionID())
            }
        }
        disableZMLogError(false)

        // Then
        await syncMOC.perform {
            guard let lastMessage = self.groupConversation.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(lastMessage.systemMessageType, .decryptionFailed)
        }
    }
}

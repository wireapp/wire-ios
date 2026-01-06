//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import GenericMessageProtocol
import WireCoreCrypto
import WireDataModel
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
            lastEventIDRepository: lastEventIDRepository,
            isFederationEnabled: false
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
            lastEventIDRepository: lastEventIDRepository,
            isFederationEnabled: false
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
            lastEventIDRepository: lastEventIDRepository,
            isFederationEnabled: false
        )
        var event: ZMUpdateEvent!

        await syncMOC.perform {
            let innerPayload = [
                "recipient": self.selfClient.remoteIdentifier!,
                "sender": self.otherClient.remoteIdentifier!,
                "id": UUID.create().transportString(),
                "text": Data("bah".utf8).base64String()
            ]

            let payload = [
                "type": "conversation.otr-message-add",
                "from": self.otherUser.remoteIdentifier!.transportString(),
                "data": innerPayload,
                "conversation": self.groupConversation.remoteIdentifier!.transportString(),
                "time": Date().transportString()
            ] as [String: Any]
            let wrapper = [
                "id": UUID.create().transportString(),
                "payload": [payload]
            ] as [String: Any]

            event = ZMUpdateEvent.eventsArray(from: wrapper as NSDictionary, source: .download)!.first!
        }

        // WHEN
        _ = await sut.decryptProteusEventAndAddClient(event, in: syncMOC) { _, _ in
            throw ProteusService.DecryptionError.failedToEstablishSessionFromMessage(.SessionNotFound)
        }

        await syncMOC.perform {
            // THEN
            guard let lastMessage = self.groupConversation.lastMessage as? ZMSystemMessage else {
                return XCTFail("Last conversation message is not a system message")
            }
            XCTAssertEqual(lastMessage.systemMessageType, .decryptionFailed)
        }
    }

}

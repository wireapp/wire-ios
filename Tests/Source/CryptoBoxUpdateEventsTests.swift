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

import Foundation
import XCTest
import ZMCDataModel
import ZMProtos
import Cryptobox

class CryptoboxUpdateEventsTests: MessagingTestBase {

    func testThatItCanDecryptOTRMessageAddEvent() {
        
        // GIVEN
        let text = "Trentatre trentini andarono a Trento tutti e trentatre trotterellando"
        let generic = ZMGenericMessage.message(text: text, nonce: UUID.create().transportString())
        
        // WHEN
        let decryptedEvent = self.decryptedUpdateEventFromOtherClient(message: generic)
        
        // THEN
        XCTAssertEqual(decryptedEvent.senderUUID(), self.otherUser.remoteIdentifier!)
        XCTAssertEqual(decryptedEvent.recipientClientID(), self.selfClient.remoteIdentifier!)
        guard let decryptedMessage = ZMClientMessage.messageUpdateResult(from: decryptedEvent, in: self.syncMOC, prefetchResult: nil) else {
            return XCTFail()
        }
        XCTAssertEqual(decryptedMessage.message?.nonce.transportString(), generic.messageId)
        XCTAssertEqual(decryptedMessage.message?.textMessageData?.messageText, text)
    }
    
    func testThatItCanDecryptOTRAssetAddEvent() {
        
        // GIVEN
        let image = self.verySmallJPEGData()
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: image)
        let properties = ZMIImageProperties(size: imageSize, length: UInt(image.count), mimeType: "image/jpg")
        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(), sha256: image.zmSHA256Digest())
        let generic = ZMGenericMessage.genericMessage(mediumImageProperties: properties,
                                                      processedImageProperties: properties,
                                                      encryptionKeys: keys,
                                                      nonce: UUID.create().transportString(),
                                                      format: .medium)
        
        // WHEN
        let decryptedEvent = self.decryptedAssetUpdateEventFromOtherClient(message: generic)
        
        // THEN
        guard let decryptedMessage = ZMAssetClientMessage.messageUpdateResult(from: decryptedEvent, in: self.syncMOC, prefetchResult: nil) else {
            return XCTFail()
        }
        XCTAssertEqual(decryptedMessage.message?.nonce.transportString(), generic.messageId)
    }
    
    func testThatItInsertsAUnableToDecryptMessageIfItCanNotEstablishASession() {
        
        // GIVEN
        let innerPayload = ["recipient": self.selfClient.remoteIdentifier!,
                            "sender": self.otherClient.remoteIdentifier!,
                            "id": UUID.create().transportString(),
                            "key": "bah".data(using: .utf8)!.base64String()
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
        
        let event = ZMUpdateEvent.eventsArray(from: wrapper as NSDictionary, source: .download)!.first!
        
        // WHEN
        self.performIgnoringZMLogError {
            self.selfClient.keysStore.encryptionContext.perform { session in
                _ = session.decryptAndAddClient(event, in: self.syncMOC)
            }
        }
        
        // THEN
        guard let lastMessage = self.groupConversation.messages.lastObject as? ZMSystemMessage else {
            return XCTFail()
        }
        XCTAssertEqual(lastMessage.systemMessageType, .decryptionFailed)
    }
}


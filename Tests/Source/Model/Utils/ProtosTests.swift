//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireProtos

class ProtosTests: XCTestCase {
    
    func testTextMessageEncodingPerformance() {
        measure { () -> Void in
            for _ in 0..<1000 {
                let messageBuilder = ZMGenericMessage.builder()!
                messageBuilder.setMessageId(NSUUID().uuidString)
                let textBuilder = ZMText.builder()!
                textBuilder.setContent("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                messageBuilder.setText(textBuilder.build())
                _ = messageBuilder.build().data()
            }
        }
    }
    
    func testTextMessageDecodingPerformance() {
        let messageBuilder = ZMGenericMessage.builder()!
        messageBuilder.setMessageId(NSUUID().uuidString)
        let textBuilder = ZMText.builder()!
        textBuilder.setContent("Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
        messageBuilder.setText(textBuilder.build())
        let data = messageBuilder.build().data()
        messageBuilder.clear()
        
        measure { () -> Void in
            for _ in 0..<1000 {
                let _ = messageBuilder.merge(from: data).build()
            }
        }
    }
    
    func testThatItCreatesGenericMessageForUnencryptedImage() {
        //given
        let nonce = UUID()
        let format = ZMImageFormat.preview
        
        let mediumProperties = ZMIImageProperties(size: CGSize(width: 10000, height: 20000), length: 200000, mimeType: "fancy image")!
        let processedProperties = ZMIImageProperties(size: CGSize(width: 640, height: 480), length: 200, mimeType: "downsized image")!
        
        // when
        let message = ZMGenericMessage.message(content: ZMImageAsset(mediumProperties: mediumProperties, processedProperties: processedProperties, encryptionKeys: nil, format: format), nonce: nonce)
        
        //then
        XCTAssertEqual(message.image.width, Int32(processedProperties.size.width))
        XCTAssertEqual(message.image.height, Int32(processedProperties.size.height))
        XCTAssertEqual(message.image.originalWidth, Int32(mediumProperties.size.width))
        XCTAssertEqual(message.image.originalHeight, Int32(mediumProperties.size.height))
        XCTAssertEqual(message.image.size, Int32(processedProperties.length))
        XCTAssertEqual(message.image.mimeType, processedProperties.mimeType)
        XCTAssertEqual(message.image.tag, StringFromImageFormat(format))
        XCTAssertNil(message.image.otrKey)
        XCTAssertNil(message.image.sha256)
        XCTAssertEqual(message.image.mac, NSData() as Data)
        XCTAssertEqual(message.image.macKey, NSData() as Data)
    }

    func testThatItCreatesGenericMessageForEncryptedImage() {
        //given
        let nonce = UUID();
        let otrKey = "OTR KEY".data(using: String.Encoding.utf8, allowLossyConversion: true)!
        let macKey = "MAC KEY".data(using: String.Encoding.utf8, allowLossyConversion: true)!
        let mac = "MAC".data(using: String.Encoding.utf8, allowLossyConversion: true)!

        let mediumProperties = ZMIImageProperties(size: CGSize(width: 10000, height: 20000), length: 200000, mimeType: "fancy image")!
        let processedProperties = ZMIImageProperties(size: CGSize(width: 640, height: 480), length: 200, mimeType: "downsized image")!
        _ = ZMImageAssetEncryptionKeys(otrKey: otrKey, macKey: macKey, mac: mac)
        let format = ZMImageFormat.preview
        let keys = ZMImageAssetEncryptionKeys(otrKey: otrKey, macKey: macKey, mac: mac)
        
        // when
        let message = ZMGenericMessage.message(content: ZMImageAsset(mediumProperties: mediumProperties, processedProperties: processedProperties, encryptionKeys: keys, format: format), nonce: nonce)
        
        //then
        XCTAssertEqual(message.image.width, Int32(processedProperties.size.width))
        XCTAssertEqual(message.image.height, Int32(processedProperties.size.height))
        XCTAssertEqual(message.image.originalWidth, Int32(mediumProperties.size.width))
        XCTAssertEqual(message.image.originalHeight, Int32(mediumProperties.size.height))
        XCTAssertEqual(message.image.size, Int32(processedProperties.length))
        XCTAssertEqual(message.image.mimeType, processedProperties.mimeType)
        XCTAssertEqual(message.image.tag, StringFromImageFormat(format))
        XCTAssertEqual(message.image.otrKey, otrKey)
        XCTAssertNil(message.image.sha256)
        XCTAssertEqual(message.image.mac, Data())
        XCTAssertEqual(message.image.macKey, Data())
    }
    
    func testThatItCreatesGenericMessageFromImageData() {
        
        // given
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "medium", withExtension: "jpg")!
        let data = NSData(contentsOf: url)!
        let nonce = UUID.create()
        
        // when
        let message = ZMGenericMessage.message(content: ZMImageAsset(data: data as Data, format: .medium)!, nonce: nonce)
        
        // then
        XCTAssertEqual(message.image.width, 0)
        XCTAssertEqual(message.image.height, 0)
        XCTAssertGreaterThan(message.image.originalWidth, 0)
        XCTAssertGreaterThan(message.image.originalHeight, 0)
        XCTAssertEqual(message.image.size, 0)
        XCTAssertEqual(message.image.mimeType, "image/jpeg")
        XCTAssertEqual(message.image.tag, StringFromImageFormat(.medium))
        XCTAssertEqual(message.image.otrKey.count, 0)
        XCTAssertEqual(message.image.mac.count, 0)
        XCTAssertEqual(message.image.macKey.count, 0)
    }
    
    func testThatItCanCreateKnock() {
        let nonce = UUID()
        let message = ZMGenericMessage.message(content: ZMKnock.knock(), nonce: nonce)
        
        XCTAssertNotNil(message)
        XCTAssertTrue(message.hasKnock())
        XCTAssertFalse(message.knock.hotKnock())
        XCTAssertEqual(message.messageId, nonce.uuidString.lowercased())
    }
    
    
    func testThatItCanCreateLastRead() {
        let conversationID = UUID.create()
        let timeStamp = NSDate(timeIntervalSince1970: 5000)
        let nonce = UUID.create()
        let message = ZMGenericMessage.message(content: ZMLastRead(timestamp: timeStamp as Date, conversationRemoteID: conversationID), nonce: nonce)
        
        XCTAssertNotNil(message)
        XCTAssertTrue(message.hasLastRead())
        XCTAssertEqual(message.messageId, nonce.transportString())
        XCTAssertEqual(message.lastRead.conversationId, conversationID.transportString())
        XCTAssertEqual(message.lastRead.lastReadTimestamp, Int64(timeStamp.timeIntervalSince1970 * 1000))
        let storedDate = NSDate(timeIntervalSince1970: Double(message.lastRead.lastReadTimestamp/1000))
        XCTAssertEqual(storedDate, timeStamp)
    }
    
    
    func testThatItCanCreateCleared() {
        let conversationID = UUID.create()
        let timeStamp = NSDate(timeIntervalSince1970: 5000)
        let nonce = UUID.create()
        let message = ZMGenericMessage.message(content: ZMCleared(timestamp: timeStamp as Date, conversationRemoteID: conversationID), nonce: nonce)
        
        XCTAssertNotNil(message)
        XCTAssertTrue(message.hasCleared())
        XCTAssertEqual(message.messageId, nonce.transportString())
        XCTAssertEqual(message.cleared.conversationId, conversationID.transportString())
        XCTAssertEqual(message.cleared.clearedTimestamp, Int64(timeStamp.timeIntervalSince1970 * 1000))
        let storedDate = NSDate(timeIntervalSince1970: Double(message.cleared.clearedTimestamp/1000))
        XCTAssertEqual(storedDate, timeStamp)
    }
    
    func testThatItCanCreateSessionReset() {
        let nonce = UUID.create()
        let message = ZMGenericMessage.clientAction(.RESETSESSION, nonce: nonce)
        
        XCTAssertNotNil(message)
        XCTAssertTrue(message.hasClientAction())
        XCTAssertEqual(message.clientAction, ZMClientAction.RESETSESSION)
        XCTAssertEqual(message.messageId, nonce.transportString())
    
    }
    
    func testThatItCanBuildAnEphemeralMessage() {
        let nonce = UUID.create()
        let message = ZMGenericMessage.message(content: ZMKnock.knock(), nonce: nonce, expiresAfter: 1)
        
        XCTAssertNotNil(message)
        XCTAssertEqual(message.messageId, nonce.transportString())
        XCTAssertTrue(message.hasEphemeral())
        guard let ephemeral = message.ephemeral else {
            return XCTFail()
        }
        XCTAssertTrue(ephemeral.hasKnock())
        XCTAssertEqual(ephemeral.expireAfterMillis, 1000);
    }
    
}


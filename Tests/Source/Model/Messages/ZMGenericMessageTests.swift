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

import Foundation

@testable import WireDataModel

class GenericMessageTests: ZMTBaseTest {
    func testThatItChecksTheCommonMessageTypesAsKnownMessage() {
        let generators: [()->(ZMGenericMessage)] = [
            {
                return ZMGenericMessage.message(text: "hello", nonce: NSUUID().transportString())
            },
            {
                return ZMGenericMessage.genericMessage(imageData: self.verySmallJPEGData(), format: .medium, nonce: NSUUID().transportString())
            },
            {
                return ZMGenericMessage.knock(nonce: NSUUID().transportString())
            },
            {
                return ZMGenericMessage(lastRead: Date(), ofConversationWithID: NSUUID().transportString(), nonce: NSUUID().transportString())
            },
            {
                return ZMGenericMessage(clearedTimestamp: Date(), ofConversationWithID: NSUUID().transportString(), nonce: NSUUID().transportString())
            },
            {
                var externalBuilder = ZMExternal.builder()!
                let base64SHA = "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU="
                let base64OTRKey = "4H1nD6bG2sCxC/tZBnIG7avLYhkCsSfv0ATNqnfug7w="
                externalBuilder = externalBuilder.setOtrKey(Data(base64Encoded: base64OTRKey))
                externalBuilder = externalBuilder.setSha256(Data(base64Encoded: base64SHA))
                
                let messageBuilder = ZMGenericMessageBuilder()
                messageBuilder.setExternal(externalBuilder.build()!)
                messageBuilder.setMessageId("MESSAGE ID")
                return messageBuilder.build()!
            },
            {
                return ZMGenericMessage.sessionReset(withNonce: NSUUID().transportString())
            },
            {
                return ZMGenericMessage(callingContent: "Calling", nonce: NSUUID().transportString())
            },
            {
                return ZMGenericMessage.genericMessage(withAssetSize: 0, mimeType: "image/jpeg", name: "test", messageID: NSUUID().transportString())
            },
            {
                return ZMGenericMessage(hideMessage: "test", inConversation: NSUUID().transportString(), nonce: NSUUID().transportString())
            },
            {
                return ZMGenericMessage.genericMessage(location: ZMLocation.location(withLatitude: 0, longitude: 0, name: "name", zoomLevel: 1), messageID: NSUUID().transportString())
            },
            {
                return ZMGenericMessage(deleteMessage: "Delete", nonce: NSUUID().transportString())
            },
            {
                return ZMGenericMessage(editMessage: "Test", newText: "Test", nonce: NSUUID().transportString())
            },
            {
                return ZMGenericMessage(emojiString: "test", messageID: NSUUID().transportString(), nonce: NSUUID().transportString())
            },
            {
                return ZMGenericMessage.knock(nonce: NSUUID().transportString(), expiresAfter: 10)
            },
            {
                return ZMGenericMessage.genericMessage(withAvailability: .away)
            }
        ]
        
        generators.forEach { generator in
            // GIVEN
            let message = generator()
            // WHEN & THEN
            XCTAssertTrue(message.knownMessage())
        }
    }
    
    func testThatGenericMessageHasImage_WhenHandlingImages() {
        // given
        let image = ZMImageAsset(data: verySmallJPEGData(), format: .medium)!
        let imageMessage = ZMGenericMessage.genericMessage(pbMessage: image, messageID: "foo")
        
        // when & then
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(imageMessage.hasImage())
    }
    
    func testThatGenericMessageHasImage_WhenHandlingEphemeralImages() {
        // given
        let image = ZMImageAsset(data: verySmallJPEGData(), format: .medium)!
        let genericMessage = ZMGenericMessage.genericMessage(pbMessage: image,
                                                             messageID: "foo",
                                                             expiresAfter: NSNumber(value: 3.0))
        
        // when & then
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(genericMessage.ephemeral.hasImage())
    }
    
    func testThatGenericMessageDoesNotHaveImage_WhenHandlingSvgAssets() {
        // given
        let svgMessage = ZMGenericMessage.genericMessage(withAssetSize: 100,
                                                         mimeType: "image/svg+xml",
                                                         name: "test",
                                                         messageID: NSUUID().transportString())
        
        //when & then
        XCTAssertTrue(!svgMessage.hasImage())
    }
    
    func testThatGenericMessageDoesNotHaveImage_WhenHandlingEphemeralSvgAssets() {
        // given
        let svgMessage = ZMGenericMessage.genericMessage(withAssetSize: 100,
                                                         mimeType: "image/svg+xml",
                                                         name: "test",
                                                         messageID: NSUUID().transportString(),
                                                         expiresAfter: NSNumber(value: 3.0))
        
        // when & then
        XCTAssertTrue(!svgMessage.ephemeral.hasImage())
    }
}


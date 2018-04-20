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
                return ZMGenericMessage.message(text: "hello", nonce: UUID())
            },
            {
                return ZMGenericMessage.genericMessage(imageData: self.verySmallJPEGData(), format: .medium, nonce: UUID.create())
            },
            {
                return ZMGenericMessage.knock(nonce: UUID.create())
            },
            {
                return ZMGenericMessage(lastRead: Date(), ofConversationWith: UUID.create(), nonce: UUID.create())
            },
            {
                return ZMGenericMessage(clearedTimestamp: Date(), ofConversationWith: UUID.create(), nonce: UUID.create())
            },
            {
                var externalBuilder = ZMExternal.builder()!
                let base64SHA = "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU="
                let base64OTRKey = "4H1nD6bG2sCxC/tZBnIG7avLYhkCsSfv0ATNqnfug7w="
                externalBuilder = externalBuilder.setOtrKey(Data(base64Encoded: base64OTRKey))
                externalBuilder = externalBuilder.setSha256(Data(base64Encoded: base64SHA))
                
                let messageBuilder = ZMGenericMessageBuilder()
                messageBuilder.setExternal(externalBuilder.build()!)
                messageBuilder.setMessageId(UUID.create().transportString())
                return messageBuilder.build()!
            },
            {
                return ZMGenericMessage.sessionReset(withNonce: UUID.create())
            },
            {
                return ZMGenericMessage(callingContent: "Calling", nonce: UUID.create())
            },
            {
                return ZMGenericMessage.genericMessage(withAssetSize: 0, mimeType: "image/jpeg", name: "test", messageID: UUID.create())
            },
            {
                return ZMGenericMessage(hideMessage: UUID.create(), inConversation: UUID.create(), nonce: UUID.create())
            },
            {
                return ZMGenericMessage.genericMessage(location: ZMLocation.location(withLatitude: 0, longitude: 0, name: "name", zoomLevel: 1), messageID: UUID.create())
            },
            {
                return ZMGenericMessage(deleteMessage: UUID.create(), nonce: UUID.create())
            },
            {
                return ZMGenericMessage(editMessage: UUID.create(), newText: "Test", nonce: UUID.create())
            },
            {
                return ZMGenericMessage(emojiString: "test", messageID: UUID.create(), nonce: UUID.create())
            },
            {
                return ZMGenericMessage.knock(nonce: UUID.create(), expiresAfter: 10)
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
        let imageMessage = ZMGenericMessage.genericMessage(pbMessage: image, messageID: UUID.create())
        
        // when & then
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(imageMessage.hasImage())
    }
    
    func testThatGenericMessageHasImage_WhenHandlingEphemeralImages() {
        // given
        let image = ZMImageAsset(data: verySmallJPEGData(), format: .medium)!
        let genericMessage = ZMGenericMessage.genericMessage(pbMessage: image,
                                                             messageID: UUID.create(),
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
                                                         messageID: UUID.create())
        
        //when & then
        XCTAssertTrue(!svgMessage.hasImage())
    }
    
    func testThatGenericMessageDoesNotHaveImage_WhenHandlingEphemeralSvgAssets() {
        // given
        let svgMessage = ZMGenericMessage.genericMessage(withAssetSize: 100,
                                                         mimeType: "image/svg+xml",
                                                         name: "test",
                                                         messageID: UUID.create(),
                                                         expiresAfter: NSNumber(value: 3.0))
        
        // when & then
        XCTAssertTrue(!svgMessage.ephemeral.hasImage())
    }
}


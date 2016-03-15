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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import XCTest
import zmessaging
import ZMProtos

class ClientMessageRequestFactoryTests: MessagingTest {

    func assertRequest(request: ZMTransportRequest?, forTextMessage message: ZMClientMessage, conversationId: NSUUID, encrypted: Bool) {
        let expectedPath: String
        let expectedPayload: [String: NSObject]!
        
        if encrypted {
            expectedPath = "/conversations/\(conversationId.transportString())/otr/messages"
            expectedPayload = nil
        }
        else {
            expectedPath = "/conversations/\(conversationId.transportString())/client-messages"
            expectedPayload = ["content": message.genericMessage.data().base64String] as [String: NSObject]
        }

        AssertOptionalNotNil(request, "ClientRequestFactory should create requet to post " + (encrypted ? "plain" : "ecnrypted") + " text message") { request in
            XCTAssertEqual(request.method, ZMTransportRequestMethod.MethodPOST)
            XCTAssertEqual(request.path, expectedPath)
            if let expectedPayload = expectedPayload {
                XCTAssertEqual(request.payload.asDictionary() as! [String: NSObject], expectedPayload)
            }
        }
    }
    
    func testThatItCreatesRequestToPostTextMessage() {
        //given
        let message = createClientTextMessage(false)
        let conversationId = NSUUID.createUUID()
        
        //when
        let request = ClientMessageRequestFactory().upstreamRequestForMessage(message, forConversationWithId: conversationId)
        
        //then
        assertRequest(request, forTextMessage: message, conversationId: conversationId, encrypted: false)
    }
    
    func testThatItCreatesRequestToPostOTRTextMessage() {
        //given
        createSelfClient()
        let message = createClientTextMessage(true)
        let conversationId = NSUUID.createUUID()
        
        //when
        let request = ClientMessageRequestFactory().upstreamRequestForMessage(message, forConversationWithId: conversationId)
        
        //then
        assertRequest(request, forTextMessage: message, conversationId: conversationId, encrypted: true)
        
        AssertOptionalNotNil(request?.binaryData) { binaryData in
            let expected = message.encryptedMessagePayloadData()
            XCTAssertEqual(binaryData, expected)
        }
    }
    
    func assertRequest(request: ZMTransportRequest?, forImageMessage message: ZMAssetClientMessage, conversationId: NSUUID, encrypted: Bool, expectedPath: String, expectedPayload: [String: NSObject]?, format: ZMImageFormat)
    {
        let imageData = message.imageDataForFormat(format, encrypted: encrypted)!
        
        AssertOptionalNotNil(request, "ClientRequestFactory should create requet to post medium asset message") { request in
            XCTAssertEqual(request.method, ZMTransportRequestMethod.MethodPOST)
            XCTAssertEqual(request.path, expectedPath)
            
            AssertOptionalNotNil(request.multipartBodyItems(), "Request should be multipart data request") { multipartItems in
                XCTAssertEqual(multipartItems.count, 2)
                AssertOptionalNotNil(multipartItems.last, "Request should contain image multipart data") { imageDataItem in
                    XCTAssertEqual(imageDataItem.data, imageData)
                }
                AssertOptionalNotNil(multipartItems.first, "Request should contain metadata multipart data") { metaDataItem in
                    let metaData : [String: NSObject]
                    do {
                        metaData = try NSJSONSerialization.JSONObjectWithData(metaDataItem.data, options: NSJSONReadingOptions()) as! [String : NSObject]
                    }
                    catch {
                        metaData = [:]
                    }
                    if let expectedPayload = expectedPayload {
                        XCTAssertEqual(metaData, expectedPayload)
                    }
                }
            }
        }
    }
    
    func testThatItCreatesRequestToPostImageMessage() {
        
        for format in [ZMImageFormat.Medium, ZMImageFormat.Preview] {
            
            //given
            let imageData = self.verySmallJPEGData()
            let conversationId = NSUUID.createUUID()
            let message = self.createImageMessageWithImageData(imageData, format: format, processed: true, stored: true, encrypted: false, moc: self.syncMOC)

            //when
            let request = ClientMessageRequestFactory().upstreamRequestForAssetMessage(format, message: message, forConversationWithId: conversationId)
            
            //then
            let expectedPath = "/conversations/\(conversationId.transportString())/assets"
            let expectedPayload = ZMAssetMetaDataEncoder.contentDispositionForImageOwner(
                message.genericMessageForFormat(format),
                format: format,
                conversationID: conversationId,
                correlationID: message.nonce) as! [String: NSObject]

            assertRequest(request, forImageMessage: message, conversationId: conversationId, encrypted: false, expectedPath: expectedPath, expectedPayload: expectedPayload, format: format)
        }
    }
    
    func testThatItCreatesRequestToPostOTRImageMessage() {
        createSelfClient()
        for _ in [ZMImageFormat.Medium, ZMImageFormat.Preview] {
            //given
            let imageData = self.verySmallJPEGData()
            let format = ZMImageFormat.Medium
            let conversationId = NSUUID.createUUID()
            let message = self.createImageMessageWithImageData(imageData, format: format, processed: true, stored: false, encrypted: true, moc: self.syncMOC)
            
            //when
            let request = ClientMessageRequestFactory().upstreamRequestForAssetMessage(format, message: message, forConversationWithId: conversationId)
            
            //then
            let expectedPath = "/conversations/\(conversationId.transportString())/otr/assets"

            assertRequest(request, forImageMessage: message, conversationId: conversationId, encrypted: true, expectedPath: expectedPath, expectedPayload: nil, format: format)
            
            AssertOptionalNotNil(request?.binaryData) { requestData in
                let bodyItems = request!.multipartBodyItems()
                XCTAssertEqual(bodyItems.count, 2)
            }
        }
    }
    
    func testThatItCreatesRequestToReuploadOTRImageMessage() {
        createSelfClient()
        
        for _ in [ZMImageFormat.Medium, ZMImageFormat.Preview] {

            // given
            let imageData = self.verySmallJPEGData()
            let format = ZMImageFormat.Medium
            let conversationId = NSUUID.createUUID()
            let message = self.createImageMessageWithImageData(imageData, format: format, processed: false, stored: false, encrypted: true, moc: self.syncMOC)
            message.assetId = NSUUID.createUUID()
            
            //when
            let request = ClientMessageRequestFactory().upstreamRequestForAssetMessage(format, message: message, forConversationWithId: conversationId)
            
            //then
            let expectedPath = "/conversations/\(conversationId.transportString())/otr/assets/\(message.assetId.transportString())"

            AssertOptionalNotNil(request, "ClientRequestFactory should create requet to post medium asset message") { request in
                XCTAssertEqual(request.method, ZMTransportRequestMethod.MethodPOST)
                XCTAssertEqual(request.path, expectedPath)
                XCTAssertNotNil(request.binaryData)
            }
        }
    }
}

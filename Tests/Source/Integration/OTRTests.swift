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
import zmessaging
import ZMCMockTransport

class OTRTests : IntegrationTestBase
{
    override func setUp() {
        super.setUp()
    }
    
    func hasMockTransportRequest(count: Int = 1, filter: ZMTransportRequest -> Bool) -> Bool {
        return (self.mockTransportSession.receivedRequests() as! [ZMTransportRequest]).filter(filter).count >= count
    }
    
    func hasMockTransportRequest(method : ZMTransportRequestMethod, path : String, count : Int = 1) -> Bool  {
        return self.hasMockTransportRequest(count, filter: {
            $0.method == method && $0.path == path
        })
    }
        
    func testThatItSendsEncryptedTextMessage()
    {
        // given
        XCTAssert(logInAndWaitForSyncToBeComplete())
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        let conversation = self.conversationForMockConversation(self.selfToUser1Conversation)
        let text = "Foo bar, but encrypted"
        self.mockTransportSession.resetReceivedRequests()
        
        // when
        var message: ZMConversationMessage?
        userSession.performChanges {
            message = conversation.appendMessageWithText(text)
        }
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertNotNil(message)
        XCTAssertTrue(self.hasMockTransportRequest(.MethodPOST, path: "/conversations/\(conversation.remoteIdentifier.transportString())/otr/messages"))
    }
    
    func testThatItSendsEncryptedImageMessage()
    {
        // given
        XCTAssert(self.logInAndWaitForSyncToBeComplete())
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))

        let conversation = self.conversationForMockConversation(self.selfToUser1Conversation)
        self.mockTransportSession.resetReceivedRequests()
        let imageData = self.verySmallJPEGData()
        
        // when
        let message = conversation.appendMessageWithImageData(imageData)
        self.uiMOC.saveOrRollback()
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertNotNil(message)
        XCTAssertTrue(self.hasMockTransportRequest(.MethodPOST, path: "/conversations/\(conversation.remoteIdentifier.transportString())/otr/assets", count: 2))
    }
    
    func testThatItSendsARequestToUpdateSignalingKeys(){
        
        // given
        XCTAssert(self.logInAndWaitForSyncToBeComplete())
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        self.mockTransportSession.resetReceivedRequests()

        var didReregister = false
        self.mockTransportSession.responseGeneratorBlock = { response in
            if response.path.containsString("/clients/") && response.payload.asDictionary()["sigkeys"] != nil {
                didReregister = true
                return ZMTransportResponse(payload: [], HTTPstatus: 200, transportSessionError: nil)
            }
            return nil
        }
        
        // when
        self.userSession.performChanges {
            UserClient.resetSignalingKeysInContext(self.uiMOC)
        }
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))

        // then
        XCTAssertTrue(didReregister)
    }

    func testThatItCreatesNewKeysIfReqeustToSyncSignalingKeysFailedWithBadRequest() {
        
        // given
        XCTAssert(self.logInAndWaitForSyncToBeComplete())
        XCTAssert(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        self.mockTransportSession.resetReceivedRequests()

        var tryCount = 0
        var firstSigKeys = [String : String]()
        self.mockTransportSession.responseGeneratorBlock = { response in
            if response.path.containsString("/clients/") && response.payload.asDictionary()["sigkeys"] != nil {
                if tryCount == 0 {
                    tryCount += 1
                    firstSigKeys = response.payload.asDictionary()["sigkeys"] as! [String : String]
                    return ZMTransportResponse(payload: ["label" : "bad-request"], HTTPstatus: 400, transportSessionError: nil)
                }
                tryCount += 1
                XCTAssertNotEqual(response.payload.asDictionary()["sigkeys"] as! [String : String], firstSigKeys)
                return ZMTransportResponse(payload: [], HTTPstatus: 200, transportSessionError: nil)
            }
            return nil
        }
        
        // when
        self.userSession.performChanges {
            UserClient.resetSignalingKeysInContext(self.uiMOC)
        }
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(tryCount, 2)
    }
}


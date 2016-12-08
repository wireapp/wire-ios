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
import XCTest

@testable import WireMessageStrategy


class MockOTREntity : OTREntity {
    
    var isMissingClients = false
    var didCallHandleClientUpdates = false
    
    var dependentObjectNeedingUpdateBeforeProcessing: AnyObject?
    var conversation: ZMConversation
    
    init(conversation: ZMConversation) {
        self.conversation = conversation
    }
    
}

class OTREntityTranscoderTests : MessagingTest {
    
    let mockClientRegistrationStatus = MockClientRegistrationStatus()
    var mockEntity : MockOTREntity!
    var conversation : ZMConversation!
    var selfClient : UserClient!
    var sut : OTREntityTranscoder<MockOTREntity>!
    
    override func setUp() {
        super.setUp()
        
        conversation = ZMConversation.insertNewObject(in: syncMOC)
        mockEntity = MockOTREntity(conversation: conversation)
        sut = OTREntityTranscoder(context: syncMOC, clientRegistrationDelegate: mockClientRegistrationStatus)
        
        selfClient = createSelfClient()
        
    }
    
    func testThatItHandlesDeletionOfSelfClient() {
        
        // given
        let payload = [
            "label" : "unknown-client"
        ]
        
        let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 403, transportSessionError: nil)
        
        // when
        XCTAssertFalse(sut.shouldTryToResend(entity: mockEntity, afterFailureWithResponse: response))
        
        // then
        XCTAssertEqual(mockClientRegistrationStatus.deletionCalls, 1)
    }
    
    func testThatItHandlesDeletionOfClient() {
        
        // given
        let user = ZMUser.insertNewObject(in: syncMOC)
        user.remoteIdentifier = UUID.create()
        let client = createClient(for: user, createSessionWithSelfUser: true)
        
        let payload = [
            "deleted" : ["\(user.remoteIdentifier!)" : [client.remoteIdentifier!] ]
        ]
        let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil)
        
        // when
        sut.request(forEntity: mockEntity, didCompleteWithResponse: response)
        
        // then
        XCTAssertTrue(client.isDeleted)
    }
    
    func testThatItHandlesMissingClient_addsClientToListOfMissingClients() {
        
        // given
        let user = ZMUser.insertNewObject(in: syncMOC)
        user.remoteIdentifier = UUID.create()
        let clientId = "ajsd9898u13a"
        
        let payload = [
            "missing" : ["\(user.remoteIdentifier!)" : [clientId] ]
        ]
        let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil)
        
        // when
        sut.request(forEntity: mockEntity, didCompleteWithResponse: response)
        
        // then
        XCTAssertEqual(selfClient.missingClients!.count, 1)
        XCTAssertEqual(selfClient.missingClients!.first!.remoteIdentifier, clientId)
    }
    
    func testThatItHandlesMissingClient_addUserToConversationIfNotAlreadyThere() {
        
        // given
        conversation.conversationType = .oneOnOne
        let user = ZMUser.insertNewObject(in: syncMOC)
        user.remoteIdentifier = UUID.create()
        let clientId = "ajsd9898u13a"
        
        let payload = [
            "missing" : ["\(user.remoteIdentifier!)" : [clientId] ]
        ]
        let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil)
        
        // when
        sut.request(forEntity: mockEntity, didCompleteWithResponse: response)
        
        // then
        XCTAssertTrue(conversation.activeParticipants.contains(user))
    }
    
}

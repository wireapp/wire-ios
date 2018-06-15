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

import WireDataModel
@testable import WireRequestStrategy
import XCTest


@objcMembers class MockOTREntity: OTREntity, Hashable {
    
    var context: NSManagedObjectContext
    public var isExpired: Bool = false
    public func expire() {
        isExpired = true
    }
    
    public func missesRecipients(_ recipients: Set<UserClient>!) {
        // no-op
    }
    public var conversation: ZMConversation?
    
    var isMissingClients = false
    var didCallHandleClientUpdates = false
    
    var dependentObjectNeedingUpdateBeforeProcessing: AnyHashable?
    
    init(conversation: ZMConversation, context: NSManagedObjectContext) {
        self.conversation = conversation
        self.context = context
    }
    
    var hashValue: Int {
        return self.conversation!.hashValue
    }
    
    func detectedRedundantClients() {
        conversation?.needsToBeUpdatedFromBackend = true
    }
    
    func detectedMissingClient(for user: ZMUser) {
        conversation?.checkIfMissingActiveParticipant(user)
    }
    
}

func ==(lhs: MockOTREntity, rhs: MockOTREntity) -> Bool {
    return lhs === rhs
}

class OTREntityTranscoderTests : MessagingTestBase {
    
    let mockClientRegistrationStatus = MockClientRegistrationStatus()
    var mockEntity : MockOTREntity!
    var sut : OTREntityTranscoder<MockOTREntity>!
    
    override func setUp() {
        super.setUp()
        
        self.mockEntity = MockOTREntity(conversation: self.groupConversation, context: syncMOC)
        self.sut = OTREntityTranscoder(context: syncMOC, clientRegistrationDelegate: mockClientRegistrationStatus)
    }
    
    override func tearDown() {
        self.mockEntity = nil
        self.sut = nil
        super.tearDown()
    }
    
    func testThatItHandlesDeletionOfSelfClient() {
        
        // GIVEN
        let payload = [
            "label" : "unknown-client"
        ]
        
        let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 403, transportSessionError: nil)
        
        // WHEN
        XCTAssertFalse(sut.shouldTryToResend(entity: mockEntity, afterFailureWithResponse: response))
        
        // THEN
        XCTAssertEqual(mockClientRegistrationStatus.deletionCalls, 1)
    }
    
    func testThatItHandlesDeletionOfClient() {
        
        // GIVEN
        let payload = [
            "deleted" : ["\(self.otherUser.remoteIdentifier!)" : [self.otherClient.remoteIdentifier!] ]
        ]
        let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil)
        
        // WHEN
        sut.request(forEntity: mockEntity, didCompleteWithResponse: response)
        
        // THEN
        XCTAssertTrue(self.otherClient.isDeleted)
    }
    
    func testThatItHandlesMissingClient_addsClientToListOfMissingClients() {
        
        // GIVEN
        let user = ZMUser.insertNewObject(in: syncMOC)
        user.remoteIdentifier = UUID.create()
        let clientId = "ajsd9898u13a"
        
        let payload = [
            "missing" : ["\(user.remoteIdentifier!)" : [clientId] ]
        ]
        let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil)
        
        // WHEN
        sut.request(forEntity: mockEntity, didCompleteWithResponse: response)
        
        // THEN
        XCTAssertEqual(selfClient.missingClients!.count, 1)
        XCTAssertEqual(selfClient.missingClients!.first!.remoteIdentifier, clientId)
    }
    
    func testThatItHandlesMissingClient_MarkAsNeedsToDownloadNotAlreadyThere() {
        
        // GIVEN
        let user = self.createUser()
        let clientId = "ajsd9898u13a"
        
        let payload = [
            "missing" : ["\(user.remoteIdentifier!)" : [clientId] ]
        ]
        let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil)
        
        // WHEN
        sut.request(forEntity: mockEntity, didCompleteWithResponse: response)
        
        // THEN
        XCTAssertTrue(self.groupConversation.needsToBeUpdatedFromBackend)
    }
    
}

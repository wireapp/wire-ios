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
        conversation?.addParticipantIfMissing(user)
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

        self.syncMOC.performGroupedAndWait { moc in
            self.mockEntity = MockOTREntity(conversation: self.groupConversation, context: moc)
            self.sut = OTREntityTranscoder(context: moc, clientRegistrationDelegate: self.mockClientRegistrationStatus)
        }
    }
    
    override func tearDown() {
        self.mockEntity = nil
        self.sut = nil
        super.tearDown()
    }
    
    func testThatItHandlesDeletionOfSelfClient() {
        self.syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let payload = [
                "label" : "unknown-client"
            ]

            let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 403, transportSessionError: nil)

            // WHEN
            XCTAssertFalse(self.sut.shouldTryToResend(entity: self.mockEntity, afterFailureWithResponse: response))

            // THEN
            XCTAssertEqual(self.mockClientRegistrationStatus.deletionCalls, 1)
        }
    }
    
    func testThatItHandlesDeletionOfClient() {
        self.syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let payload = [
                "deleted" : ["\(self.otherUser.remoteIdentifier!)" : [self.otherClient.remoteIdentifier!] ]
            ]
            let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil)

            // WHEN
            self.sut.request(forEntity: self.mockEntity, didCompleteWithResponse: response)

            // THEN
            XCTAssertTrue(self.otherClient.isDeleted)
        }
    }
    
    func testThatItHandlesMissingClient_addsClientToListOfMissingClients() {
        self.syncMOC.performGroupedAndWait { moc in
            // GIVEN
            let user = ZMUser.insertNewObject(in: moc)
            user.remoteIdentifier = UUID.create()
            let clientId = "ajsd9898u13a"

            let payload = [
                "missing" : ["\(user.remoteIdentifier!)" : [clientId] ]
            ]
            let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil)

            // WHEN
            self.sut.request(forEntity: self.mockEntity, didCompleteWithResponse: response)

            // THEN
            XCTAssertEqual(self.selfClient.missingClients!.count, 1)
            XCTAssertEqual(self.selfClient.missingClients!.first!.remoteIdentifier, clientId)
        }
    }
    
    func testThatItHandlesMissingClient_MarkAsNeedsToDownloadNotAlreadyThere() {
        self.syncMOC.performGroupedAndWait { _ in
            // GIVEN
            let user = self.createUser()
            let clientId = "ajsd9898u13a"

            let payload = [
                "missing" : ["\(user.remoteIdentifier!)" : [clientId] ]
            ]
            let response = ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil)

            // WHEN
            self.sut.request(forEntity: self.mockEntity, didCompleteWithResponse: response)

            // THEN
            XCTAssertTrue(self.groupConversation.needsToBeUpdatedFromBackend)
        }
    }
    
}

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


import XCTest
import WireMessageStrategy

class AvailabilityRequestStrategyTests: MessagingTestBase {
    
    var applicationStatus: MockApplicationStatus!
    var sut : AvailabilityRequestStrategy!
    
    override func setUp() {
        super.setUp()
        
        applicationStatus = MockApplicationStatus()
        applicationStatus.mockSynchronizationState = .eventProcessing
        sut = AvailabilityRequestStrategy(withManagedObjectContext: syncMOC, applicationStatus: applicationStatus)

    }
    
    override func tearDown() {
        sut = nil
        applicationStatus = nil
        
        super.tearDown()
    }
    
    func testThatItGeneratesARequestWhenAvailabilityIsModified() {
        
        // given
        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.needsToBeUpdatedFromBackend = false
        selfUser.setLocallyModifiedKeys(Set(arrayLiteral: AvailabilityKey))
        sut.contextChangeTrackers.forEach({ $0.addTrackedObjects(Set<NSManagedObject>(arrayLiteral: selfUser)) })
        
        // when
        let request = sut.nextRequest()
        
        
        // then
        XCTAssertNotNil(request)
    }
    
    func testThatItDoesntGenerateARequestWhenAvailabilityIsModifiedForOtherUsers() {
        
        // given
        otherUser.needsToBeUpdatedFromBackend = false
        otherUser.modifiedKeys = Set(arrayLiteral: AvailabilityKey)
        sut.contextChangeTrackers.forEach({ $0.addTrackedObjects(Set<NSManagedObject>(arrayLiteral: otherUser)) })
        
        // when
        let request = sut.nextRequest()
        
        // then
        XCTAssertNil(request)
    }
    
    func testThatItUpdatesAvailabilityFromUpdateEvent() {
        
        // given
        let selfUser = ZMUser.selfUser(in: syncMOC)
        _ = ZMConversation(remoteID: selfUser.remoteIdentifier!, createIfNeeded: true, in: syncMOC) // create self conversation
        
        let message = ZMGenericMessage.genericMessage(withAvailability: .away)
        let dict = ["recipient": self.selfClient.remoteIdentifier!,
                    "sender": self.selfClient.remoteIdentifier!,
                    "text": message.data().base64String()] as NSDictionary
        
        let updateEvent = ZMUpdateEvent(fromEventStreamPayload: ([
            "type": "conversation.otr-message-add",
            "data":dict,
            "from" : selfUser.remoteIdentifier!,
            "conversation":ZMConversation.selfConversation(in: syncMOC).remoteIdentifier!.transportString(),
            "time":Date(timeIntervalSince1970: 555555).transportString()] as NSDictionary), uuid: nil)!
        
        // when
        sut.processEvents([updateEvent], liveEvents: true, prefetchResult: nil)
        
        // then
        XCTAssertEqual(selfUser.availability, .away)
    }
    
    func testThatItRequestSlowSyncIfWeAreSendingToRedudantClients() {
        
        // given when
        sut.detectedRedundantClients()
        
        // then
        XCTAssertTrue(applicationStatus.slowSyncWasRequested)
    }
    
    func testThatItRequestSlowSyncIfWeAreMissingAUser() {
        
        // given
        let missingUser = ZMUser(remoteID: UUID(), createIfNeeded: true, in: syncMOC)!
        
        // when
        sut.detectedMissingClient(for: missingUser)
        
        // then
        XCTAssertTrue(applicationStatus.slowSyncWasRequested)
    }
    
    func testThatItDoesNotRequestSlowSyncIfWeAreNotMissingAUser() {
        
        // given
        let connectedUser = otherUser!
        
        // when
        sut.detectedMissingClient(for: connectedUser)
        
        // then
        XCTAssertFalse(applicationStatus.slowSyncWasRequested)
    }
    
}

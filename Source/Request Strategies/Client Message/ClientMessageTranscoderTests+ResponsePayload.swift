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
import WireMessageStrategy
import WireDataModel

// MARK: - Missing/deleted/redundant clients
extension ClientMessageTranscoderTests {
    
    func testThatItAddsMissingRecipientInMessageRelationship() {
        
        var message: ZMClientMessage! = nil
        let userID = UUID.create()
        let clientID = "abababab"
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            message = self.groupConversation.appendMessage(withText: "bao") as! ZMClientMessage
            self.syncMOC.saveOrRollback()
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let payload = ["missing": [userID.transportString() : [clientID]]] as NSDictionary
            let response = ZMTransportResponse(payload: payload, httpStatus: 412, transportSessionError: nil)
            
            // WHEN
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(message.missingRecipients.map { ($0 as! UserClient).remoteIdentifier! }, [clientID])
        }
    }
    
    func testThatItDeletesTheCurrentClientIfWeGetA403ResponseWithCorrectLabel() {
        var message: ZMClientMessage! = nil
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            message = self.groupConversation.appendMessage(withText: "bao") as! ZMClientMessage
            self.syncMOC.saveOrRollback()
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let response = ZMTransportResponse(payload: ["label": "unknown-client"] as NSDictionary, httpStatus: 403, transportSessionError: nil)
            
            // WHEN
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertEqual(mockApplicationStatus.deletionCalls, 1)
    }
    
    func testThatItDoesNotDeletesTheCurrentClientIfWeGetA403ResponseWithoutTheCorrectLabel() {
        var message: ZMClientMessage! = nil
        
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            message = self.groupConversation.appendMessage(withText: "bao") as! ZMClientMessage
            self.syncMOC.saveOrRollback()
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let response = ZMTransportResponse(payload: ["foo": "bar"] as NSDictionary, httpStatus: 403, transportSessionError: nil)
            
            // WHEN
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        XCTAssertEqual(mockApplicationStatus.deletionCalls, 0)
    }
    
    func testThatItSetsNeedsToBeUpdatedFromBackendOnConversationIfMissingMapIncludesUsersThatAreNoActiveUsers() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.groupConversation.appendMessage(withText: "bao") as! ZMClientMessage
            self.syncMOC.saveOrRollback()
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let payload = ["missing": [UUID.create().transportString() : ["abababab"]]] as NSDictionary
            let response = ZMTransportResponse(payload: payload, httpStatus: 412, transportSessionError: nil)
            
            // WHEN
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(self.groupConversation.needsToBeUpdatedFromBackend)
        }
    }
    
    func testThatItSetsNeedsToBeUpdatedFromBackendOnConnectionIfMissingMapIncludesUsersThatIsNoActiveUser_OneOnOne() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.oneToOneConversation.appendMessage(withText: "bao") as! ZMClientMessage
            self.syncMOC.saveOrRollback()
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let payload = ["missing": [UUID.create().transportString() : ["abababab"]]] as NSDictionary
            let response = ZMTransportResponse(payload: payload, httpStatus: 412, transportSessionError: nil)
            
            // WHEN
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertTrue(self.oneToOneConversation.connection!.needsToBeUpdatedFromBackend)
        }
    }
    
    func testThatItDeletesDeletedRecipientsWhenGetting412() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.groupConversation.appendMessage(withText: "bao") as! ZMClientMessage
            self.syncMOC.saveOrRollback()
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let payload = [
                "missing": [
                    UUID.create().transportString() : [
                        "abababab"
                    ]
                ],
                "deleted": [
                    self.otherUser.remoteIdentifier!.transportString() : [
                        self.otherClient.remoteIdentifier!
                    ]
                ]
                ] as NSDictionary
            let response = ZMTransportResponse(payload: payload, httpStatus: 412, transportSessionError: nil)
            
            // WHEN
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.otherUser.clients.count, 0)
        }
    }
    
    func testThatItDeletesDeletedRecipientsWhenGetting200() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let message = self.groupConversation.appendMessage(withText: "bao") as! ZMClientMessage
            self.syncMOC.saveOrRollback()
            self.sut.contextChangeTrackers.forEach { $0.objectsDidChange(Set([message])) }
            guard let request = self.sut.nextRequest() else { return XCTFail() }
            let payload = [
                "deleted": [
                    self.otherUser.remoteIdentifier!.transportString() : [
                        self.otherClient.remoteIdentifier!
                    ]
                ]
                ] as NSDictionary
            let response = ZMTransportResponse(payload: payload, httpStatus: 412, transportSessionError: nil)
            
            // WHEN
            request.complete(with: response)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // THEN
        self.syncMOC.performGroupedBlockAndWait {
            XCTAssertEqual(self.otherUser.clients.count, 0)
        }
    }
}

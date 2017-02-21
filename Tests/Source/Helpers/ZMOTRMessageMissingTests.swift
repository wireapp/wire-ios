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
@testable import WireMessageStrategy
import ZMTesting

class ZMOTRMessageMissingTests: MessagingTest {
    
    var user: ZMUser!
    var conversation: ZMConversation!
    var message: ZMOTRMessage!
    
    override func setUp() {
        
        super.setUp()
        
        self.createSelfClient()
        self.uiMOC.saveOrRollback()
        
        self.syncMOC.performGroupedBlockAndWait {
            self.user = ZMUser.insertNewObject(in: self.syncMOC)
            self.user.remoteIdentifier = UUID.create()
            self.conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            self.message = ZMClientMessage.insertNewObject(in: self.syncMOC)
            self.message.visibleInConversation = self.conversation
            self.syncMOC.saveOrRollback()
        }
    }
    
    func testThatItInsertsMissingClientsFromUploadResponse() {
        
        self.syncMOC.performGroupedBlockAndWait {

            // GIVEN
            let missingClientIdentifiers = ["aabbccdd", "ddeeff22"]
            let payload = [
                "missing" : [
                    self.user.remoteIdentifier!.transportString() : missingClientIdentifiers
                ],
                "deleted" : [:],
                "redundant" : [:]
            ]
            
            // WHEN
            _ = self.message.parseUploadResponse(ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil), clientDeletionDelegate: MockClientRegistrationStatus())
            self.syncMOC.saveOrRollback()
            
            // THEN
            let allExistingClients = Set(self.user.clients.map { $0.remoteIdentifier! })
            missingClientIdentifiers.forEach {
                XCTAssert(allExistingClients.contains($0))
            }
        }
    }
    
    func testThatItDeletesClientsFromUploadResponse() {
        self.syncMOC.performGroupedBlockAndWait {
            
            // GIVEN
            let client1 = UserClient.insertNewObject(in: self.syncMOC)
            client1.remoteIdentifier = "aabbccdd"
            client1.user = self.user
            let client2 = UserClient.insertNewObject(in: self.syncMOC)
            client2.remoteIdentifier = "11223344"
            client2.user = self.user
            let client3 = UserClient.insertNewObject(in: self.syncMOC)
            client3.remoteIdentifier = "abccdeef"
            client3.user = self.user
            self.syncMOC.saveOrRollback()
            XCTAssertEqual(self.user.clients.count, 3)
            
            let deletedClientsIdentifier = [client1.remoteIdentifier!, client2.remoteIdentifier!]
            let payload = [
                "missing" : [:],
                "deleted" : [
                    self.user.remoteIdentifier!.transportString() : deletedClientsIdentifier
                ],
                "redundant" : [:]
            ]
            
            // WHEN
            _ = self.message.parseUploadResponse(ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil), clientDeletionDelegate: MockClientRegistrationStatus())
            self.syncMOC.saveOrRollback()
            
            // THEN
            let allExistingClients = Set(self.user.clients.map { $0.remoteIdentifier! })
            deletedClientsIdentifier.forEach {
                XCTAssertFalse(allExistingClients.contains($0))
            }
            XCTAssertTrue(allExistingClients.contains(client3.remoteIdentifier!))
        }
    }
    
    func testThatItMarksConversationToDownloadFromRedundantUploadResponse() {
        // GIVEN
        XCTAssertFalse(self.conversation.needsToBeUpdatedFromBackend)
        let payload = [
            "missing" : [:],
            "deleted" : [:],
            "redundant" : [
                self.user.remoteIdentifier!.transportString() : "aabbccdd"
            ]
        ]
        
        // WHEN
        _ = self.message.parseUploadResponse(ZMTransportResponse(payload: payload as NSDictionary, httpStatus: 200, transportSessionError: nil), clientDeletionDelegate: MockClientRegistrationStatus())
        self.syncMOC.saveOrRollback()
        
        // THEN
        XCTAssertTrue(self.conversation.needsToBeUpdatedFromBackend)
    }
    
}

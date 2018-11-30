////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class ZMHotFixTests_Integration: MessagingTest {

    func testThatAllConversationsAreUpdated_198_0_0() {
        var g1: ZMConversation!
        var g2: ZMConversation!
        var g3: ZMConversation!
        
        syncMOC.performGroupedAndWait { _ in
            // given
            g1 = ZMConversation.insertNewObject(in: self.syncMOC)
            g1.conversationType = .group
            XCTAssertFalse(g1.needsToBeUpdatedFromBackend)
            
            g2 = ZMConversation.insertNewObject(in: self.syncMOC)
            g2.conversationType = .connection
            g2.team = Team.insertNewObject(in: self.syncMOC)
            XCTAssertFalse(g2.needsToBeUpdatedFromBackend)
            
            g3 = ZMConversation.insertNewObject(in: self.syncMOC)
            g3.conversationType = .connection
            XCTAssertFalse(g3.needsToBeUpdatedFromBackend)
            
            self.syncMOC.setPersistentStoreMetadata("147.0", key: "lastSavedVersion")
            let sut = ZMHotFix(syncMOC: self.syncMOC)
            
            // when
            self.performIgnoringZMLogError {
                sut?.applyPatches(forCurrentVersion: "198.0")
            }
        }
        
        syncMOC.performGroupedAndWait { _ in
            // then
            XCTAssertTrue(g1.needsToBeUpdatedFromBackend)
            XCTAssertTrue(g2.needsToBeUpdatedFromBackend)
            XCTAssertTrue(g3.needsToBeUpdatedFromBackend)
        }
    }
    
    func testThatItRemovesPendingConfirmationsForDeletedMessages_54_0_1() {
        var confirmation: ZMClientMessage! = nil
        syncMOC.performGroupedBlock {
            // GIVEN
            self.syncMOC.setPersistentStoreMetadata("0.1", key: "lastSavedVersion")
            self.syncMOC.setPersistentStoreMetadata(NSNumber(booleanLiteral: true), key: "HasHistory")
            
            let oneOnOneConversation = ZMConversation(context: self.syncMOC)
            oneOnOneConversation.conversationType = .oneOnOne
            oneOnOneConversation.remoteIdentifier = UUID()
            
            let otherUser = ZMUser(context: self.syncMOC)
            otherUser.remoteIdentifier = UUID()
            
            let incomingMessage = oneOnOneConversation.append(text: "Test") as! ZMClientMessage
            confirmation = incomingMessage.confirmDelivery()
            
            self.syncMOC.saveOrRollback()
            
            XCTAssertNotNil(confirmation)
            XCTAssertFalse(confirmation.isDeleted)
            
            incomingMessage.visibleInConversation = nil
            incomingMessage.hiddenInConversation = oneOnOneConversation
            
            // WHEN
            let sut = ZMHotFix(syncMOC: self.syncMOC)
            self.performIgnoringZMLogError {
                sut!.applyPatches(forCurrentVersion: "54.0.1")
            }
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        syncMOC.performGroupedBlock {
            self.syncMOC.saveOrRollback()
        }
        syncMOC.performGroupedBlock {
            XCTAssertNil(confirmation.managedObjectContext)
        }
    }

}

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

import XCTest
import ZMUtilities
import ZMCDataModel
import ZMCLinkPreview


class ZMOTRMessage_SecurityDegradationTests : ZMBaseManagedObjectTest {
    
    func testThatAtCreationAMessageIsNotCausingDegradation_UIMoc() {
        
        // GIVEN
        let convo = createConversation(moc: self.uiMOC)
        
        // WHEN
        let message = convo.appendMessage(withText: "Foo")!
        
        // THEN
        XCTAssertFalse(message.causedSecurityLevelDegradation)
    }
    
    func testThatAtCreationAMessageIsNotCausingDegradation_SyncMoc() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            
            // WHEN
            let message = convo.appendMessage(withText: "Foo")!
            
            // THEN
            XCTAssertFalse(message.causedSecurityLevelDegradation)
        }
    }
    
    func testThatItSetsMessageAsCausingDegradation_SyncMoc() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message = convo.appendMessage(withText: "Foo")! as! ZMOTRMessage
            
            // WHEN
            message.causedSecurityLevelDegradation = true
            
            // THEN
            XCTAssertTrue(message.causedSecurityLevelDegradation)
        }
    }
    
    func testThatItResetsMessageAsCausingDegradation_SyncMoc() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message = convo.appendMessage(withText: "Foo")! as! ZMOTRMessage
            message.causedSecurityLevelDegradation = true
            
            // WHEN
            message.causedSecurityLevelDegradation = false
            
            // THEN
            XCTAssertFalse(message.causedSecurityLevelDegradation)
        }
    }
}

// MARK: - Propagation across contexes
extension ZMOTRMessage_SecurityDegradationTests {
    
    func testThatMessageIsNotMarkedOnUIMOCBeforeMerge() {
        // GIVEN
        let convo = createConversation(moc: self.uiMOC)
        let message = convo.appendMessage(withText: "Foo")! as! ZMOTRMessage
        self.uiMOC.saveOrRollback()
        
        // WHEN
        self.syncMOC.performGroupedBlockAndWait { 
            let syncMessage = try! self.syncMOC.existingObject(with: message.objectID) as! ZMOTRMessage
            syncMessage.causedSecurityLevelDegradation = true
            self.syncMOC.saveOrRollback()
        }
        
        // THEN
        XCTAssertFalse(message.causedSecurityLevelDegradation)
    }
    
    func testThatMessageIsMarkedOnUIMOCAfterMerge() {
        // GIVEN
        let convo = createConversation(moc: self.uiMOC)
        let message = convo.appendMessage(withText: "Foo")! as! ZMOTRMessage
        self.uiMOC.saveOrRollback()
        var userInfo : [String: Any] = [:]
        self.syncMOC.performGroupedBlockAndWait {
            let syncMessage = try! self.syncMOC.existingObject(with: message.objectID) as! ZMOTRMessage
            syncMessage.causedSecurityLevelDegradation = true
            self.syncMOC.saveOrRollback()
            userInfo = self.syncMOC.userInfo.asDictionary() as! [String: Any]
        }
        
        // WHEN
        self.uiMOC.mergeUserInfo(fromUserInfo: userInfo)
        
        // THEN
        XCTAssertTrue(message.causedSecurityLevelDegradation)
    }
    
    func testThatItPreservesMessgesMargedOnSyncMOCAfterMerge() {
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let convo = self.createConversation(moc: self.syncMOC)
            let message = convo.appendMessage(withText: "Foo")! as! ZMOTRMessage
            message.causedSecurityLevelDegradation = true
            
            // WHEN
            self.syncMOC.mergeUserInfo(fromUserInfo: [:])
            
            // THEN
            XCTAssertTrue(message.causedSecurityLevelDegradation)
        }
    }
}

// MARK: - Helper
extension ZMOTRMessage_SecurityDegradationTests {
    
    /// Creates a group conversation with two users
    func createConversation(moc: NSManagedObjectContext) -> ZMConversation {
        let user1 = ZMUser.insertNewObject(in: moc)
        user1.remoteIdentifier = UUID.create()
        let user2 = ZMUser.insertNewObject(in: moc)
        user2.remoteIdentifier = UUID.create()
        let convo = ZMConversation.insertGroupConversation(into: moc, withParticipants: [user1, user2])!
        return convo
    }
    
}

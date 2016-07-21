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
import ZMCDataModel


// MARK: VideoCalling
class ZMCallStateTests : MessagingTest {
    
    func testThatItMergesChangesOnIsVideoCallFromMainIntoSync() {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .OneOnOne
        self.uiMOC.saveOrRollback()
        
        // when
        try! conversation.voiceChannel.joinVideoCall()
        let callState = self.uiMOC.zm_callState.createCopyAndResetHasChanges()
        self.syncMOC.mergeCallStateChanges(callState)
        
        // then
        XCTAssertTrue(conversation.isVideoCall)
        XCTAssertFalse(conversation.hasLocalModificationsForIsVideoCall)
        
        let syncConversation = self.syncMOC.objectWithID(conversation.objectID) as? ZMConversation
        XCTAssertNotNil(syncConversation)
        if let syncConversation = syncConversation {
            XCTAssertTrue(syncConversation.isVideoCall)
            XCTAssertFalse(syncConversation.hasLocalModificationsForIsVideoCall)
        } else {
            XCTFail()
        }
    }
    
    func testThatItMergesChangesOnIsVideoCallFromSyncIntoMain() {
        // given
        var conversation : ZMConversation!
        self.syncMOC.performGroupedBlockAndWait{
            conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.conversationType = .OneOnOne
            self.syncMOC.saveOrRollback()
            
            // when
            conversation.isVideoCall = true
        }
        let callState = self.syncMOC.zm_callState.createCopyAndResetHasChanges()
        self.uiMOC.mergeCallStateChanges(callState)
        
        // then
        XCTAssertTrue(conversation.isVideoCall)
        XCTAssertFalse(conversation.hasLocalModificationsForIsVideoCall)
        
        let uiConversation = self.uiMOC.objectWithID(conversation.objectID) as? ZMConversation
        XCTAssertNotNil(uiConversation)
        if let uiConversation = uiConversation {
            XCTAssertTrue(uiConversation.isVideoCall)
            XCTAssertFalse(uiConversation.hasLocalModificationsForIsVideoCall)
            
        } else {
            XCTFail()
        }
    }
    
    
    func testThatItMergesChangesOnIsSendingVideoFromMainIntoSync() {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .OneOnOne
        self.uiMOC.saveOrRollback()
        
        // when
        conversation.isSendingVideo = true
        let callState = self.uiMOC.zm_callState.createCopyAndResetHasChanges()
        self.syncMOC.mergeCallStateChanges(callState)
        
        // then
        XCTAssertTrue(conversation.isSendingVideo)
        XCTAssertFalse(conversation.hasLocalModificationsForIsSendingVideo)
        
        let syncConversation = self.syncMOC.objectWithID(conversation.objectID) as? ZMConversation
        XCTAssertNotNil(syncConversation)
        if let syncConversation = syncConversation {
            XCTAssertTrue(syncConversation.isSendingVideo)
            // we want to send out a call.state event to sync changed state
            XCTAssertTrue(syncConversation.hasLocalModificationsForIsSendingVideo)
        } else {
            XCTFail()
        }
    }
    
    func testThatItMergesChangesOnIsSendingVideoFromSyncIntoMain() {
        // given
        var conversation : ZMConversation!
        self.syncMOC.performGroupedBlockAndWait{
            conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.conversationType = .OneOnOne
            self.syncMOC.saveOrRollback()
            
            // when we force to sync changes made on the syncMOC
            conversation.isSendingVideo = true
            conversation.syncLocalModificationsOfIsSendingVideo()
            
            XCTAssertTrue(conversation.isSendingVideo)
            XCTAssertTrue(conversation.hasLocalModificationsForIsSendingVideo)
        }
        let callState = self.syncMOC.zm_callState.createCopyAndResetHasChanges()
        self.uiMOC.mergeCallStateChanges(callState)
        
        // then hasLocalModifications on the SyncMoc are preserved
        XCTAssertTrue(conversation.isSendingVideo)
        XCTAssertTrue(conversation.hasLocalModificationsForIsSendingVideo)
        
        let uiConversation = self.uiMOC.objectWithID(conversation.objectID) as? ZMConversation
        XCTAssertNotNil(uiConversation)
        if let uiConversation = uiConversation {
            XCTAssertTrue(uiConversation.isSendingVideo)
            XCTAssertFalse(uiConversation.hasLocalModificationsForIsSendingVideo)
            
        } else {
            XCTFail()
        }
        
        self.syncMOC.performGroupedBlockAndWait{
            // when resetting haslocalModifications
            conversation.resetHasLocalModificationsForIsSendingVideo()
            XCTAssertFalse(conversation.hasLocalModificationsForIsSendingVideo)
        }
        let callState2 = self.syncMOC.zm_callState.createCopyAndResetHasChanges()
        self.uiMOC.mergeCallStateChanges(callState2)
        
        // then hasLocalModfications on syncMOC are reset
        XCTAssertTrue(conversation.isSendingVideo)
        XCTAssertFalse(conversation.hasLocalModificationsForIsSendingVideo)
        
        if let uiConversation = uiConversation {
            XCTAssertTrue(uiConversation.isSendingVideo)
            XCTAssertFalse(uiConversation.hasLocalModificationsForIsSendingVideo)
            
        } else {
            XCTFail()
        }
    }
    
    
    func testThatItMergesChangesOnIsSendingVideoFromSyncIntoMain_UIMakesChanges() {
        // given
        var conversation : ZMConversation!
        self.syncMOC.performGroupedBlockAndWait{
            conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.conversationType = .OneOnOne
            self.syncMOC.saveOrRollback()
            
            // when we force to sync changes made on the syncMOC
            conversation.isSendingVideo = true
            conversation.syncLocalModificationsOfIsSendingVideo()
            
            XCTAssertTrue(conversation.isSendingVideo)
            XCTAssertTrue(conversation.hasLocalModificationsForIsSendingVideo)
        }
        let callState = self.syncMOC.zm_callState.createCopyAndResetHasChanges()
        self.uiMOC.mergeCallStateChanges(callState)
        
        // then hasLocalModifications on the SyncMoc are preserved
        XCTAssertTrue(conversation.isSendingVideo)
        XCTAssertTrue(conversation.hasLocalModificationsForIsSendingVideo)
        
        let uiConversation = self.uiMOC.objectWithID(conversation.objectID) as? ZMConversation
        XCTAssertNotNil(uiConversation)
        if let uiConversation = uiConversation {
            XCTAssertTrue(uiConversation.isSendingVideo)
            XCTAssertFalse(uiConversation.hasLocalModificationsForIsSendingVideo)
            
            // and when the UI stops sending video before changes where performed
            uiConversation.isSendingVideo = false
            
            XCTAssertFalse(uiConversation.isSendingVideo)
            XCTAssertTrue(uiConversation.hasLocalModificationsForIsSendingVideo)
        } else {
            XCTFail()
        }
        
        let callState2 = self.uiMOC.zm_callState.createCopyAndResetHasChanges()
        self.syncMOC.mergeCallStateChanges(callState2)
        
        // then hasLocalModfications on syncMOC not reset
        XCTAssertFalse(conversation.isSendingVideo)
        XCTAssertTrue(conversation.hasLocalModificationsForIsSendingVideo)
        
        if let uiConversation = uiConversation {
            XCTAssertFalse(uiConversation.isSendingVideo)
            XCTAssertFalse(uiConversation.hasLocalModificationsForIsSendingVideo)
            
        } else {
            XCTFail()
        }
    }
    
    func testThatItMergesActiveVideoCallParticipantsSyncIntoMain() {
        // given
        var conversation : ZMConversation!
        self.syncMOC.performGroupedBlockAndWait{
            conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.conversationType = .OneOnOne
            let user = ZMUser.insertNewObjectInManagedObjectContext(self.syncMOC)
            self.syncMOC.saveOrRollback()
            
            // when
            conversation.isFlowActive = true
            conversation.addActiveVideoCallParticipant(user)
        }
        let callState = self.syncMOC.zm_callState.createCopyAndResetHasChanges()
        self.uiMOC.mergeCallStateChanges(callState)
        
        // then
        XCTAssertEqual(conversation.otherActiveVideoCallParticipants.count, 1)
        
        let uiConversation = self.uiMOC.objectWithID(conversation.objectID) as? ZMConversation
        XCTAssertNotNil(uiConversation)
        if let uiConversation = uiConversation {
            XCTAssertEqual(uiConversation.otherActiveVideoCallParticipants.count, 1)
        } else {
            XCTFail()
        }
    }
    
    
}

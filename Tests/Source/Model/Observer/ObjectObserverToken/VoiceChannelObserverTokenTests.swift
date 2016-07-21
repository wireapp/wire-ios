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

private extension ZMConversation {
    var mutableCallParticipants : NSMutableOrderedSet {
        return mutableOrderedSetValueForKey(ZMConversationCallParticipantsKey)
    }
}

class VoiceChannelObserverTokenTests : ZMBaseManagedObjectTest{
    
    class TestVoiceChannelObserver : NSObject, ZMVoiceChannelStateObserver {
        
        var receivedChangeInfo : [VoiceChannelStateChangeInfo] = []
        
        func voiceChannelStateDidChange(changes: VoiceChannelStateChangeInfo) {
            receivedChangeInfo.append(changes)
            if(NSOperationQueue.currentQueue() != NSOperationQueue.mainQueue()) {
                XCTFail("Wrong thread")
            }
        }
        func clearNotifications() {
            receivedChangeInfo = []
        }
    }
    
    class TestVoiceChannelParticipantStateObserver : NSObject, ZMVoiceChannelParticipantsObserver {
        
        var receivedChangeInfo : [VoiceChannelParticipantsChangeInfo] = []
        
        func voiceChannelParticipantsDidChange(changes: VoiceChannelParticipantsChangeInfo) {
            receivedChangeInfo.append(changes)
        }
        func clearNotifications() {
            receivedChangeInfo = []
        }
        
    }

    override func setUp() {
        super.setUp()
        NSNotificationCenter.defaultCenter().postNotificationName("ZMApplicationDidEnterEventProcessingStateNotification", object: nil)
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    private func addConversationParticipant(conversation: ZMConversation) -> ZMUser {
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.mutableOtherActiveParticipants.addObject(user)
        return user
    }
    
    
    
    func testThatItNotifiesTheObserverOfStateChange()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .OneOnOne
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.addVoiceChannelStateObserver(observer)
        
        // when
        conversation.callDeviceIsActive = true
        
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.NoActiveUsers)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.OutgoingCall)
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        conversation.voiceChannel.removeVoiceChannelStateObserverForToken(token)
    }
    
    func testThatItSendsAChannelStateChangeNotificationsWhenSomeoneIsCalling()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .OneOnOne
        
        let otherParticipant = self.addConversationParticipant(conversation)
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addVoiceChannelStateObserver(observer)
        
        // when
        conversation.mutableCallParticipants.addObject(otherParticipant)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.NoActiveUsers)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.IncomingCall)
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        conversation.voiceChannel.removeVoiceChannelStateObserverForToken(token)
    }
    
    func testThatItSendsAChannelStateChangeNotificationsWhenSomeoneLeavesTheConversation()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .OneOnOne
        
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.mutableCallParticipants.addObject(otherParticipant)
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addVoiceChannelStateObserver(observer)
        
        // when
        conversation.mutableCallParticipants.removeObject(otherParticipant)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.IncomingCall)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.NoActiveUsers)
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        conversation.voiceChannel.removeVoiceChannelStateObserverForToken(token)

    }
    
    func testThatItSendsAChannelStateChangeNotificationsWhenTheUserGetsConnectedToTheChannel()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        let selfParticipant = ZMUser.selfUserInContext(self.uiMOC)
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.conversationType = .OneOnOne
        
        conversation.mutableCallParticipants.addObject(otherParticipant)
        conversation.mutableCallParticipants.addObject(selfParticipant)
        
        conversation.isFlowActive = false
        conversation.callDeviceIsActive = true
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.addVoiceChannelStateObserver(observer)
        
        // when
        conversation.isFlowActive = true
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.SelfIsJoiningActiveChannel)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.SelfConnectedToActiveChannel)
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        conversation.voiceChannel.removeVoiceChannelStateObserverForToken(token)

    }
    
    func testThatItSendsAChannelStateChangeNotificationsWhenTheUserGetsDisconnectedToTheChannel()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        let selfParticipant = ZMUser.selfUserInContext(self.uiMOC)
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.conversationType = .OneOnOne
        
        conversation.mutableCallParticipants.addObject(otherParticipant)
        conversation.mutableCallParticipants.addObject(selfParticipant)
        
        conversation.callDeviceIsActive = true
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addVoiceChannelStateObserver(observer)
        
        // when
        conversation.isFlowActive = false
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.SelfConnectedToActiveChannel)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.SelfIsJoiningActiveChannel)
        }

        conversation.voiceChannel.removeVoiceChannelStateObserverForToken(token)

    }
    
    func testThatItSendsAChannelStateChangeNotificationsWhenTransferBecomesReady()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        let selfParticipant = ZMUser.selfUserInContext(self.uiMOC)
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.conversationType = .OneOnOne
        
        conversation.mutableCallParticipants.addObject(otherParticipant)
        conversation.mutableCallParticipants.addObject(selfParticipant)
        
        conversation.activeFlowParticipants = NSOrderedSet(objects: otherParticipant, selfParticipant)
        conversation.isFlowActive = true
        conversation.callDeviceIsActive = true
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addVoiceChannelStateObserver(observer)
        
        // when
        conversation.isFlowActive = false
        conversation.callDeviceIsActive = false
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation),notifyDirectly: true)
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.SelfConnectedToActiveChannel)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.DeviceTransferReady)
        }
        conversation.voiceChannel.removeVoiceChannelStateObserverForToken(token)
    }
    
    func testThatItSendsAChannelStateChangeNotificationsWhenCallIsBeingTransfered()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        let selfParticipant = ZMUser.selfUserInContext(self.uiMOC)
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.conversationType = .OneOnOne
        
        conversation.mutableCallParticipants.addObject(otherParticipant)
        conversation.mutableCallParticipants.addObject(selfParticipant)
        
        conversation.activeFlowParticipants = NSOrderedSet(objects: otherParticipant, selfParticipant)
        
        conversation.isFlowActive = false
        conversation.callDeviceIsActive = false
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))

        let observer = TestVoiceChannelObserver()
        let token = conversation.voiceChannel.addVoiceChannelStateObserver(observer)
        
        // when
        conversation.isFlowActive = true
        conversation.callDeviceIsActive = true
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral:conversation),notifyDirectly: true)
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.DeviceTransferReady)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.SelfConnectedToActiveChannel)
        }
        conversation.voiceChannel.removeVoiceChannelStateObserverForToken(token)
    }
    
    func testThatItSendsACallStateChangeNotificationWhenIgnoringACall()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.conversationType = .OneOnOne
        
        conversation.mutableCallParticipants.addObject(otherParticipant)
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addVoiceChannelStateObserver(observer)
        
        // when
        conversation.isIgnoringCall = true
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral:conversation),notifyDirectly: true)
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.IncomingCall)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.NoActiveUsers)
        }
        conversation.voiceChannel.removeVoiceChannelStateObserverForToken(token)
    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .OneOnOne
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.addVoiceChannelStateObserver(observer)
        conversation.voiceChannel.removeVoiceChannelStateObserverForToken(token)
        
        // when
        conversation.callDeviceIsActive = true
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 0)
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }
}




extension VoiceChannelObserverTokenTests {
    
    func testThatItSendsAParticipantsChangeNotificationWhenTheParticipantJoinsTheOneToOneCall()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        let selfParticipant = ZMUser.selfUserInContext(self.uiMOC)
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.conversationType = .OneOnOne
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.addCallParticipantsObserver(observer)
        
        /// when
        conversation.mutableCallParticipants.addObject(otherParticipant)
        conversation.mutableCallParticipants.addObject(selfParticipant)
        conversation.activeFlowParticipants = NSOrderedSet(objects: otherParticipant, selfParticipant)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation),notifyDirectly: true)
        
        
        // then
        // We want to get voiceChannelState change notification when flow in established and later on
        //we want to get notifications on changing activeFlowParticipants array (when someone joins or leaves)
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.insertedIndexes, NSIndexSet(indexesInRange: NSMakeRange(0, conversation.voiceChannel.participants().count)))
            XCTAssertEqual(note.deletedIndexes, NSIndexSet())
            XCTAssertEqual(note.updatedIndexes, NSIndexSet())
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserverForToken(token as ZMVoiceChannelParticipantsObserverOpaqueToken)

    }
    
    func testThatItSendsAParticipantsChangeNotificationWhenTheParticipantJoinsTheGroupCall()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        let selfParticipant = ZMUser.selfUserInContext(self.uiMOC)
        let otherParticipant1 = self.addConversationParticipant(conversation)
        let otherParticipant2 = self.addConversationParticipant(conversation)
        conversation.conversationType = .Group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addCallParticipantsObserver(observer)
        
        // when
        conversation.mutableCallParticipants.addObject(otherParticipant1)
        conversation.mutableCallParticipants.addObject(otherParticipant2)
        conversation.mutableCallParticipants.addObject(selfParticipant)
        conversation.activeFlowParticipants = NSOrderedSet(objects: otherParticipant1, otherParticipant2, selfParticipant)
        
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation),notifyDirectly: true)
        
        // then
        // We want to get voiceChannelState change notification when flow in established and later on
        //we want to get notifications on changing activeFlowParticipants array (when someone joins or leaves)
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.insertedIndexes, NSIndexSet(indexesInRange: NSMakeRange(0, conversation.voiceChannel.participants().count)))
            XCTAssertEqual(note.deletedIndexes, NSIndexSet())
            XCTAssertEqual(note.updatedIndexes, NSIndexSet())
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserverForToken(token as ZMVoiceChannelParticipantsObserverOpaqueToken)

    }
    
    func testThatItSendsAParticipantsUpdateNotificationWhenTheParticipantBecameActive()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        let selfParticipant = ZMUser.selfUserInContext(self.uiMOC)
        let otherParticipant1 = self.addConversationParticipant(conversation)
        let otherParticipant2 = self.addConversationParticipant(conversation)
        conversation.conversationType = .Group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()
        
        conversation.mutableCallParticipants.addObject(otherParticipant1)
        conversation.mutableCallParticipants.addObject(selfParticipant)
        conversation.mutableCallParticipants.addObject(otherParticipant2)
    
        let token = conversation.voiceChannel.addCallParticipantsObserver(observer)
        
        // when
        conversation.activeFlowParticipants = NSOrderedSet(objects: selfParticipant, otherParticipant1)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation),notifyDirectly: true)
        
        // then
        // We want to get voiceChannelState change notification when flow in established and later on
        //we want to get notifications on changing activeFlowParticipants array (when someone joins or leaves)
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.insertedIndexes, NSIndexSet())
            XCTAssertEqual(note.deletedIndexes, NSIndexSet())
            XCTAssertEqual(note.updatedIndexes, NSIndexSet(indexesInRange: NSMakeRange(0, conversation.voiceChannel.participants().count - 1)))
        }
        else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserverForToken(token as ZMVoiceChannelParticipantsObserverOpaqueToken)

    }
    
    func testThatItSendsAParticipantsChangeNotificationWhenTheParticipantLeavesTheGroupCall()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        let selfParticipant = ZMUser.selfUserInContext(self.uiMOC)
        let otherParticipant1 = self.addConversationParticipant(conversation)
        let otherParticipant2 = self.addConversationParticipant(conversation)
        conversation.conversationType = .Group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()
        
        conversation.mutableCallParticipants.addObjectsFromArray([otherParticipant1, selfParticipant, otherParticipant2])
        conversation.activeFlowParticipants = NSOrderedSet(array: [otherParticipant1, selfParticipant, otherParticipant2])

        let token = conversation.voiceChannel.addCallParticipantsObserver(observer)
        
        // when
        conversation.mutableCallParticipants.removeObject(otherParticipant2)
        conversation.mutableCallParticipants.moveObjectsAtIndexes(NSIndexSet(index: 1), toIndex: 0) // this is done by the comparator
        conversation.activeFlowParticipants = NSOrderedSet(array: [selfParticipant, otherParticipant1])
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        // We want to get voiceChannelState change notification when flow in established and later on
        //we want to get notifications on changing activeFlowParticipants array (when someone joins or leaves)
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.deletedIndexes, NSIndexSet(index: 1))
            XCTAssertEqual(note.insertedIndexes, NSIndexSet())
            XCTAssertEqual(note.updatedIndexes, NSIndexSet())
            XCTAssertEqual(note.movedIndexPairs, [])
            
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserverForToken(token as ZMVoiceChannelParticipantsObserverOpaqueToken)

    }
    
    func testThatItSendsTheUpdateForParticipantsWhoLeaveTheVoiceChannel()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        let selfParticipant = ZMUser.selfUserInContext(self.uiMOC)
        let otherParticipant1 = self.addConversationParticipant(conversation)
        let otherParticipant2 = self.addConversationParticipant(conversation)
        conversation.conversationType = .Group
        conversation.isFlowActive = true
        
        conversation.mutableCallParticipants.addObjectsFromArray([otherParticipant1, selfParticipant, otherParticipant2])
        conversation.activeFlowParticipants = NSOrderedSet(array: [otherParticipant1, selfParticipant, otherParticipant2])
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addCallParticipantsObserver(observer)
        
        // when
        conversation.activeFlowParticipants = NSOrderedSet(array: [otherParticipant1, selfParticipant])
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.deletedIndexes, NSIndexSet())
            XCTAssertEqual(note.insertedIndexes, NSIndexSet())
            XCTAssertEqual(note.updatedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(note.movedIndexPairs, [])
            
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserverForToken(token as ZMVoiceChannelParticipantsObserverOpaqueToken)

    }
    
    func testThatItSendsTheUpdateForParticipantsWhoJoinTheVoiceChannel()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)

        let otherParticipant1 = self.addConversationParticipant(conversation)
        let otherParticipant2 = self.addConversationParticipant(conversation)
        conversation.conversationType = .Group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()
        
        conversation.mutableCallParticipants.addObject(otherParticipant1)
        conversation.mutableCallParticipants.addObject(otherParticipant2)
        conversation.activeFlowParticipants = NSOrderedSet(objects: otherParticipant1)
        
        let token = conversation.voiceChannel.addCallParticipantsObserver(observer)
        
        // when
        conversation.activeFlowParticipants = NSOrderedSet(array: [otherParticipant1, otherParticipant2])
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.deletedIndexes, NSIndexSet())
            XCTAssertEqual(note.insertedIndexes, NSIndexSet())
            XCTAssertEqual(note.updatedIndexes, NSIndexSet(index: conversation.callParticipants.indexOfObject(otherParticipant2)))
            XCTAssertEqual(note.movedIndexPairs, [])
            
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserverForToken(token as ZMVoiceChannelParticipantsObserverOpaqueToken)

    }
}



// MARK: Video Calling

extension VoiceChannelObserverTokenTests {
    
    func testThatItSendsTheUpdateForParticipantsWhoActivatesVideoStream()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        
        let otherParticipant1 = self.addConversationParticipant(conversation)
        conversation.conversationType = .Group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.addCallParticipantsObserver(observer)
        
        // when
        conversation.addActiveVideoCallParticipant(otherParticipant1)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertTrue(note.otherActiveVideoCallParticipantsChanged)
            
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserverForToken(token)
    }
    
    func testThatItDoesNotSendTheUpdateForParticipantsWhoActivatesVideoStreamWhenFLowIsNotActive()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        
        let otherParticipant1 = self.addConversationParticipant(conversation)
        conversation.conversationType = .Group
        conversation.isFlowActive = false
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.addCallParticipantsObserver(observer)
        
        // when
        conversation.addActiveVideoCallParticipant(otherParticipant1)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 0)
        conversation.voiceChannel.removeCallParticipantsObserverForToken(token)
    }
    
    func testThatItSendsTheUpdateForSecondParticipantsWhoActivatesVideoStream()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        
        let otherParticipant1 = self.addConversationParticipant(conversation)
        let otherParticipant2 = self.addConversationParticipant(conversation)
        
        conversation.conversationType = .Group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()
        conversation.addActiveVideoCallParticipant(otherParticipant1)
        
        let token = conversation.voiceChannel.addCallParticipantsObserver(observer)
        
        // when
        conversation.addActiveVideoCallParticipant(otherParticipant2)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertTrue(note.otherActiveVideoCallParticipantsChanged)
            
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserverForToken(token)
    }
    
    func testThatItSendsTheUpdateForParticipantWhenFlowIsEstablished()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        
        let otherParticipant1 = self.addConversationParticipant(conversation)
        conversation.conversationType = .Group
        conversation.isFlowActive = false
        conversation.addActiveVideoCallParticipant(otherParticipant1)
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.addCallParticipantsObserver(observer)
        
        // when
        conversation.isFlowActive = true
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertTrue(note.otherActiveVideoCallParticipantsChanged)
            
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserverForToken(token)
    }
    
    
    func testThatItSendsTheUpdateForParticipantsWhoDeactivatesVideoStream()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        
        let otherParticipant1 = self.addConversationParticipant(conversation)
        conversation.conversationType = .Group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()

        conversation.addActiveVideoCallParticipant(otherParticipant1)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        XCTAssertEqual(conversation.otherActiveVideoCallParticipants.count, 1)
        
        let token = conversation.voiceChannel.addCallParticipantsObserver(observer)
        
        // when
        conversation.removeActiveVideoCallParticipant(otherParticipant1)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        XCTAssertEqual(conversation.otherActiveVideoCallParticipants.count, 0)

        // then
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertTrue(note.otherActiveVideoCallParticipantsChanged)
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserverForToken(token)
    }
    
}

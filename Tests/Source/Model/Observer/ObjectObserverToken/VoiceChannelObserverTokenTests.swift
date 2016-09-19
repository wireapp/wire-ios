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
        return mutableOrderedSetValue(forKey: ZMConversationCallParticipantsKey)
    }
}

class VoiceChannelObserverTokenTests : ZMBaseManagedObjectTest{
    
    class TestVoiceChannelObserver : NSObject, ZMVoiceChannelStateObserver {
        
        var receivedChangeInfo : [VoiceChannelStateChangeInfo] = []
        
        func voiceChannelStateDidChange(_ changes: VoiceChannelStateChangeInfo) {
            receivedChangeInfo.append(changes)
            if(OperationQueue.current != OperationQueue.main) {
                XCTFail("Wrong thread")
            }
        }
        func clearNotifications() {
            receivedChangeInfo = []
        }
    }
    
    class TestVoiceChannelParticipantStateObserver : NSObject, ZMVoiceChannelParticipantsObserver {
        
        var receivedChangeInfo : [VoiceChannelParticipantsChangeInfo] = []
        
        func voiceChannelParticipantsDidChange(_ changes: VoiceChannelParticipantsChangeInfo) {
            receivedChangeInfo.append(changes)
        }
        func clearNotifications() {
            receivedChangeInfo = []
        }
        
    }

    override func setUp() {
        super.setUp()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ZMApplicationDidEnterEventProcessingStateNotification"), object: nil)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    fileprivate func addConversationParticipant(_ conversation: ZMConversation) -> ZMUser {
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        conversation.mutableOtherActiveParticipants.add(user)
        return user
    }
    
    
    
    func testThatItNotifiesTheObserverOfStateChange()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .oneOnOne
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.add(observer)
        
        // when
        conversation.callDeviceIsActive = true
        
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.noActiveUsers)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.outgoingCall)
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        conversation.voiceChannel.removeStateObserver(for: token!)
    }
    
    func testThatItSendsAChannelStateChangeNotificationsWhenSomeoneIsCalling()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .oneOnOne
        
        let otherParticipant = self.addConversationParticipant(conversation)
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.add(observer)
        
        // when
        conversation.mutableCallParticipants.add(otherParticipant)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.noActiveUsers)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.incomingCall)
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        conversation.voiceChannel.removeStateObserver(for: token!)
    }
    
    func testThatItSendsAChannelStateChangeNotificationsWhenSomeoneLeavesTheConversation()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .oneOnOne
        
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.mutableCallParticipants.add(otherParticipant)
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.add(observer)
        
        // when
        conversation.mutableCallParticipants.remove(otherParticipant)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.incomingCall)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.noActiveUsers)
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        conversation.voiceChannel.removeStateObserver(for: token!)

    }
    
    func testThatItSendsAChannelStateChangeNotificationsWhenTheUserGetsConnectedToTheChannel()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let selfParticipant = ZMUser.selfUser(in: self.uiMOC)
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.conversationType = .oneOnOne
        
        conversation.mutableCallParticipants.add(otherParticipant)
        conversation.mutableCallParticipants.add(selfParticipant)
        
        conversation.isFlowActive = false
        conversation.callDeviceIsActive = true
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.add(observer)
        
        // when
        conversation.isFlowActive = true
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.selfIsJoiningActiveChannel)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.selfConnectedToActiveChannel)
        }
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        conversation.voiceChannel.removeStateObserver(for: token!)

    }
    
    func testThatItSendsAChannelStateChangeNotificationsWhenTheUserGetsDisconnectedToTheChannel()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let selfParticipant = ZMUser.selfUser(in: self.uiMOC)
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.conversationType = .oneOnOne
        
        conversation.mutableCallParticipants.add(otherParticipant)
        conversation.mutableCallParticipants.add(selfParticipant)
        
        conversation.callDeviceIsActive = true
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.add(observer)
        
        // when
        conversation.isFlowActive = false
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.selfConnectedToActiveChannel)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.selfIsJoiningActiveChannel)
        }

        conversation.voiceChannel.removeStateObserver(for: token!)

    }
    
    func testThatItSendsAChannelStateChangeNotificationsWhenTransferBecomesReady()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let selfParticipant = ZMUser.selfUser(in: self.uiMOC)
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.conversationType = .oneOnOne
        
        conversation.mutableCallParticipants.add(otherParticipant)
        conversation.mutableCallParticipants.add(selfParticipant)
        
        conversation.activeFlowParticipants = NSOrderedSet(objects: otherParticipant, selfParticipant)
        conversation.isFlowActive = true
        conversation.callDeviceIsActive = true
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.add(observer)
        
        // when
        conversation.isFlowActive = false
        conversation.callDeviceIsActive = false
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation),notifyDirectly: true)
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.selfConnectedToActiveChannel)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.deviceTransferReady)
        }
        conversation.voiceChannel.removeStateObserver(for: token!)
    }
    
    func testThatItSendsAChannelStateChangeNotificationsWhenCallIsBeingTransfered()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let selfParticipant = ZMUser.selfUser(in: self.uiMOC)
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.conversationType = .oneOnOne
        
        conversation.mutableCallParticipants.add(otherParticipant)
        conversation.mutableCallParticipants.add(selfParticipant)
        
        conversation.activeFlowParticipants = NSOrderedSet(objects: otherParticipant, selfParticipant)
        
        conversation.isFlowActive = false
        conversation.callDeviceIsActive = false
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let observer = TestVoiceChannelObserver()
        let token = conversation.voiceChannel.add(observer)
        
        // when
        conversation.isFlowActive = true
        conversation.callDeviceIsActive = true
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral:conversation),notifyDirectly: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.deviceTransferReady)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.selfConnectedToActiveChannel)
        }
        conversation.voiceChannel.removeStateObserver(for: token!)
    }
    
    func testThatItSendsACallStateChangeNotificationWhenIgnoringACall()
    {
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.conversationType = .oneOnOne
        
        conversation.mutableCallParticipants.add(otherParticipant)
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.add(observer)
        
        // when
        conversation.isIgnoringCall = true
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral:conversation),notifyDirectly: true)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.previousState, ZMVoiceChannelState.incomingCall)
            XCTAssertEqual(note.currentState, ZMVoiceChannelState.noActiveUsers)
        }
        conversation.voiceChannel.removeStateObserver(for: token!)
    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let observer = TestVoiceChannelObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .oneOnOne
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.add(observer)
        conversation.voiceChannel.removeStateObserver(for: token!)
        
        // when
        conversation.callDeviceIsActive = true
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 0)
        
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}




extension VoiceChannelObserverTokenTests {
    
    func testThatItSendsAParticipantsChangeNotificationWhenTheParticipantJoinsTheOneToOneCall()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let selfParticipant = ZMUser.selfUser(in: self.uiMOC)
        let otherParticipant = self.addConversationParticipant(conversation)
        conversation.conversationType = .oneOnOne
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.addCall(observer)
        
        /// when
        conversation.mutableCallParticipants.add(otherParticipant)
        conversation.mutableCallParticipants.add(selfParticipant)
        conversation.activeFlowParticipants = NSOrderedSet(objects: otherParticipant, selfParticipant)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation),notifyDirectly: true)
        
        
        // then
        // We want to get voiceChannelState change notification when flow in established and later on
        //we want to get notifications on changing activeFlowParticipants array (when someone joins or leaves)
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.insertedIndexes, IndexSet(integersIn: 0..<conversation.voiceChannel.participants().count))
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet())
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserver(for: token as ZMVoiceChannelParticipantsObserverOpaqueToken)

    }
    
    func testThatItSendsAParticipantsChangeNotificationWhenTheParticipantJoinsTheGroupCall()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let selfParticipant = ZMUser.selfUser(in: self.uiMOC)
        let otherParticipant1 = self.addConversationParticipant(conversation)
        let otherParticipant2 = self.addConversationParticipant(conversation)
        conversation.conversationType = .group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addCall(observer)
        
        // when
        conversation.mutableCallParticipants.add(otherParticipant1)
        conversation.mutableCallParticipants.add(otherParticipant2)
        conversation.mutableCallParticipants.add(selfParticipant)
        conversation.activeFlowParticipants = NSOrderedSet(objects: otherParticipant1, otherParticipant2, selfParticipant)
        
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation),notifyDirectly: true)
        
        // then
        // We want to get voiceChannelState change notification when flow in established and later on
        //we want to get notifications on changing activeFlowParticipants array (when someone joins or leaves)
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.insertedIndexes, IndexSet(integersIn: 0..<conversation.voiceChannel.participants().count))
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet())
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserver(for: token as ZMVoiceChannelParticipantsObserverOpaqueToken)

    }
    
    func testThatItSendsAParticipantsUpdateNotificationWhenTheParticipantBecameActive()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let selfParticipant = ZMUser.selfUser(in: self.uiMOC)
        let otherParticipant1 = self.addConversationParticipant(conversation)
        let otherParticipant2 = self.addConversationParticipant(conversation)
        conversation.conversationType = .group
        conversation.isFlowActive = true
        
        conversation.mutableCallParticipants.add(otherParticipant1)
        conversation.mutableCallParticipants.add(selfParticipant)
        conversation.mutableCallParticipants.add(otherParticipant2)
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addCall(observer)
        
        // when
        conversation.activeFlowParticipants = NSOrderedSet(objects: selfParticipant, otherParticipant1)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation),notifyDirectly: true)
        
        // then
        // We want to get voiceChannelState change notification when flow in established and later on
        //we want to get notifications on changing activeFlowParticipants array (when someone joins or leaves)
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.insertedIndexes, IndexSet())
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet(integersIn: 0..<conversation.voiceChannel.participants().count - 1))
        }
        else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserver(for: token as ZMVoiceChannelParticipantsObserverOpaqueToken)

    }
    
    func testThatItSendsAParticipantsChangeNotificationWhenTheParticipantLeavesTheGroupCall()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let selfParticipant = ZMUser.selfUser(in: self.uiMOC)
        let otherParticipant1 = self.addConversationParticipant(conversation)
        let otherParticipant2 = self.addConversationParticipant(conversation)
        conversation.conversationType = .group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()
        
        conversation.mutableCallParticipants.addObjects(from: [otherParticipant1, selfParticipant, otherParticipant2])
        conversation.activeFlowParticipants = NSOrderedSet(array: [otherParticipant1, selfParticipant, otherParticipant2])
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addCall(observer)
        
        // when
        conversation.mutableCallParticipants.remove(otherParticipant2)
        conversation.mutableCallParticipants.moveObjects(at: IndexSet(integer: 1), to: 0) // this is done by the comparator
        conversation.activeFlowParticipants = NSOrderedSet(array: [selfParticipant, otherParticipant1])
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        // We want to get voiceChannelState change notification when flow in established and later on
        //we want to get notifications on changing activeFlowParticipants array (when someone joins or leaves)
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.deletedIndexes, IndexSet(integer: 1))
            XCTAssertEqual(note.insertedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet())
            XCTAssertEqual(note.movedIndexPairs, [])
            
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserver(for: token as ZMVoiceChannelParticipantsObserverOpaqueToken)

    }
    
    func testThatItSendsTheUpdateForParticipantsWhoLeaveTheVoiceChannel()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let selfParticipant = ZMUser.selfUser(in: self.uiMOC)
        let otherParticipant1 = self.addConversationParticipant(conversation)
        let otherParticipant2 = self.addConversationParticipant(conversation)
        conversation.conversationType = .group
        conversation.isFlowActive = true
        
        conversation.mutableCallParticipants.addObjects(from: [otherParticipant1, selfParticipant, otherParticipant2])
        conversation.activeFlowParticipants = NSOrderedSet(array: [otherParticipant1, selfParticipant, otherParticipant2])
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addCall(observer)
        
        // when
        conversation.activeFlowParticipants = NSOrderedSet(array: [otherParticipant1, selfParticipant])
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.insertedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(note.movedIndexPairs, [])
            
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserver(for: token as ZMVoiceChannelParticipantsObserverOpaqueToken)

    }
    
    func testThatItSendsTheUpdateForParticipantsWhoJoinTheVoiceChannel()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)

        let otherParticipant1 = self.addConversationParticipant(conversation)
        let otherParticipant2 = self.addConversationParticipant(conversation)
        conversation.conversationType = .group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()

        conversation.mutableCallParticipants.add(otherParticipant1)
        conversation.mutableCallParticipants.add(otherParticipant2)
        conversation.activeFlowParticipants = NSOrderedSet(objects: otherParticipant1)
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addCall(observer)
        
        // when
        conversation.activeFlowParticipants = NSOrderedSet(array: [otherParticipant2, otherParticipant1])
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        if let note = observer.receivedChangeInfo.first {
            XCTAssertEqual(note.voiceChannel, conversation.voiceChannel)
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.insertedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet(integer: conversation.callParticipants.index(of: otherParticipant2)))
            XCTAssertEqual(note.movedIndexPairs, [])
            
        } else {
            XCTFail("did not send notification")
        }
        conversation.voiceChannel.removeCallParticipantsObserver(for: token as ZMVoiceChannelParticipantsObserverOpaqueToken)

    }
}



// MARK: Video Calling

extension VoiceChannelObserverTokenTests {
    
    func testThatItSendsTheUpdateForParticipantsWhoActivatesVideoStream()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        
        let otherParticipant1 = self.addConversationParticipant(conversation)
        conversation.conversationType = .group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.addCall(observer)
        
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
        conversation.voiceChannel.removeCallParticipantsObserver(for: token)
    }
    
    func testThatItDoesNotSendTheUpdateForParticipantsWhoActivatesVideoStreamWhenFLowIsNotActive()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        
        let otherParticipant1 = self.addConversationParticipant(conversation)
        conversation.conversationType = .group
        conversation.isFlowActive = false
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.addCall(observer)
        
        // when
        conversation.addActiveVideoCallParticipant(otherParticipant1)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        
        XCTAssertEqual(observer.receivedChangeInfo.count, 0)
        conversation.voiceChannel.removeCallParticipantsObserver(for: token)
    }
    
    func testThatItSendsTheUpdateForSecondParticipantsWhoActivatesVideoStream()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        
        let otherParticipant1 = self.addConversationParticipant(conversation)
        let otherParticipant2 = self.addConversationParticipant(conversation)
        conversation.conversationType = .group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()
        
        conversation.addActiveVideoCallParticipant(otherParticipant1)
        self.uiMOC.saveOrRollback()

        let token = conversation.voiceChannel.addCall(observer)
        
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
        conversation.voiceChannel.removeCallParticipantsObserver(for: token)
    }
    
    func testThatItSendsTheUpdateForParticipantWhenFlowIsEstablished()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        
        let otherParticipant1 = self.addConversationParticipant(conversation)
        conversation.conversationType = .group
        conversation.isFlowActive = false
        self.uiMOC.saveOrRollback()

        conversation.addActiveVideoCallParticipant(otherParticipant1)
        self.uiMOC.saveOrRollback()
        
        let token = conversation.voiceChannel.addCall(observer)
        
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
        conversation.voiceChannel.removeCallParticipantsObserver(for: token)
    }
    
    
    func testThatItSendsTheUpdateForParticipantsWhoDeactivatesVideoStream()
    {
        // given
        let observer = TestVoiceChannelParticipantStateObserver()
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        
        let otherParticipant1 = self.addConversationParticipant(conversation)
        conversation.conversationType = .group
        conversation.isFlowActive = true
        self.uiMOC.saveOrRollback()

        conversation.addActiveVideoCallParticipant(otherParticipant1)
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        XCTAssertEqual(conversation.otherActiveVideoCallParticipants.count, 1)
        
        let token = conversation.voiceChannel.addCall(observer)
        
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
        conversation.voiceChannel.removeCallParticipantsObserver(for: token)
    }
    
}

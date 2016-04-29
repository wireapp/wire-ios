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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation
import ZMCDataModel

class ConversationObserverTokenTests : ZMBaseManagedObjectTest {
    
    override func setUp() {
        super.setUp()
        XCTAssertNotNil(self.syncMOC.globalManagedObjectContextObserver)
        NSNotificationCenter.defaultCenter().postNotificationName("ZMApplicationDidEnterEventProcessingStateNotification", object: nil)
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidBecomeActiveNotification, object: nil)
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }
    
    class TestConversationObserver : NSObject, ZMConversationObserver {
        
        var receivedChangeInfo : [ConversationChangeInfo] = []
        
        func conversationDidChange(changes: ConversationChangeInfo) {
            receivedChangeInfo.append(changes)
        }
        func clearNotifications() {
            receivedChangeInfo = []
        }
    }
    
    func checkThatItNotifiesTheObserverOfAChange(conversation : ZMConversation,
        modifier: (ZMConversation, TestConversationObserver) -> Void,
        expectedChangedField : String?,
        expectedChangedKeys: KeySet) {
            
            self.checkThatItNotifiesTheObserverOfAChange(conversation,
                modifier: modifier,
                expectedChangedFields: expectedChangedField != nil ? KeySet(key: expectedChangedField!) : KeySet(),
                expectedChangedKeys: expectedChangedKeys)
    }
    
    func checkThatItNotifiesTheObserverOfAChange(conversation : ZMConversation,
        modifier: (ZMConversation, TestConversationObserver) -> Void,
        expectedChangedFields : KeySet,
        expectedChangedKeys: KeySet) {
            
        // given
        let observer = TestConversationObserver()
        let token = conversation.addConversationObserver(observer)

        // when
        modifier(conversation, observer)
        conversation.managedObjectContext!.saveOrRollback()
            
        // then
        let changeCount = observer.receivedChangeInfo.count
        if !expectedChangedFields.isEmpty {
            XCTAssertEqual(changeCount, 1, "Observer expected 1 notification, but received \(changeCount).")
        } else {
            XCTAssertEqual(changeCount, 0, "Observer was notified, but DID NOT expect a notification")
        }
        
        // and when
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, changeCount, "Should have changed only once")
        
        let conversationInfoKeys = [
            "messagesChanged",
            "participantsChanged",
            "nameChanged",
            "lastModifiedDateChanged",
            "unreadCountChanged",
            "connectionStateChanged",
            "isArchivedChanged",
            "isSilencedChanged",
            "conversationListIndicatorChanged"
        ]
        
        if expectedChangedFields.isEmpty {
            return
        }
        
        if let changes = observer.receivedChangeInfo.first {
            for key in conversationInfoKeys {
                if expectedChangedFields.contains(key) {
                    continue
                }
                if let value = changes.valueForKey(key) as? NSNumber {
                    XCTAssertFalse(value.boolValue, "\(key) was supposed to be false")
                }
                else {
                    XCTFail("Can't find key or key is not boolean for '\(key)'")
                }
            }
            XCTAssertEqual(KeySet(Array(changes.changedKeysAndOldValues.keys)), expectedChangedKeys)
        }
        
        ZMConversation.removeConversationObserverForToken(token)
    }
    
    
    func testThatItNotifiesTheObserverOfANameChange()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        conversation.userDefinedName = "George"
        
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, _ in conversation.userDefinedName = "Phil"},
            expectedChangedField: "nameChanged",
            expectedChangedKeys: KeySet(["displayName"])
        )
        
    }
    
    func notifyNameChange(user: ZMUser, name: String) {
        user.name = name
        self.uiMOC.saveOrRollback()
    }

    func testThatItNotifiesTheObserverIfTheVoiceChannelStateChanges()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        let otherUser = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        otherUser.name = "Foo"
        conversation.mutableOtherActiveParticipants.addObject(otherUser)
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { _ in
                conversation.callDeviceIsActive = true

                self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral:conversation), notifyDirectly:true)
            },
            expectedChangedFields: KeySet(["voiceChannelStateChanged", "conversationListIndicatorChanged"]),
            expectedChangedKeys: KeySet(["voiceChannelState", "conversationListIndicator"])
        )
        
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }
    
    func testThatItNotifiesTheObserverOfANameChangeBecauseOfActiveParticipants()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        let otherUser = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        otherUser.name = "Foo"
        conversation.mutableOtherActiveParticipants.addObject(otherUser)
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { _ in
                self.notifyNameChange(otherUser, name: "Phil")
            },
            expectedChangedField: "nameChanged",
            expectedChangedKeys: KeySet(["displayName"])
        )
        
    }
    
    func testThatItNotifiesTheObserverOfANameChangeBecauseAnActiveParticipantWasAdded()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { _ in
                
                let otherUser = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
                otherUser.name = "Foo"
                conversation.mutableOtherActiveParticipants.addObject(otherUser)
                self.updateDisplayNameGeneratorWithUsers([otherUser])
            },
            expectedChangedFields: KeySet(["nameChanged", "participantsChanged"]),
            expectedChangedKeys: KeySet(["displayName", "otherActiveParticipants"])
        )
        
    }
    
    func testThatItNotifiesTheObserverOfANameChangeBecauseOfActiveParticipantsMultipleTimes()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.mutableOtherActiveParticipants.addObject(user)
        let observer = TestConversationObserver()
        let token = conversation.addConversationObserver(observer)
        self.uiMOC.saveOrRollback()
        
        // when
        user.name = "Boo"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 1)
        
        // and when
        user.name = "Bar"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 2)
        
        // and when
        self.uiMOC.saveOrRollback()
        ZMConversation.removeConversationObserverForToken(token)
    }
    
    
    func testThatItDoesNotNotifyTheObserverBecauseAUsersAccentColorChanged()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        let otherUser = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        otherUser.accentColorValue = .BrightOrange
        conversation.mutableOtherActiveParticipants.addObject(otherUser)
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { _ in
                otherUser.accentColorValue = ZMAccentColor.SoftPink
            },
            expectedChangedField: nil,
            expectedChangedKeys: KeySet()
        )
    }
    
    func testThatItNotifiesTheObserverOfANameChangeBecauseOfOtherUserNameChange()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .OneOnOne
        
        let otherUser = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        otherUser.name = "Foo"
        
        let connection = ZMConnection.insertNewObjectInManagedObjectContext(self.uiMOC)
        connection.to = otherUser
        connection.status = .Accepted
        conversation.connection = connection
        
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { _ in
                self.notifyNameChange(otherUser, name: "Phil")
            },
            expectedChangedField: "nameChanged",
            expectedChangedKeys: KeySet(["displayName"])
        )
        
    }
    
    func testThatItNotifiesTheObserverOfANameChangeBecauseAUserWasAdded()
    {
        // given
        let user1 = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        user1.name = "Foo A"
        
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        conversation.mutableOtherActiveParticipants.addObject(user1)
        
        self.uiMOC.saveOrRollback()
        
        XCTAssertTrue(user1.displayName == "Foo")
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { _ in
                let user2 = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
                user2.name = "Foo B"
                self.uiMOC.saveOrRollback()
                XCTAssertEqual(user1.displayName, "Foo A")
            },
            expectedChangedField: "nameChanged",
            expectedChangedKeys: KeySet(["displayName"])
        )
    }
    
    func testThatItNotifiesTheObserverOfANameChangeBecauseAUserWasAddedAndLaterItsNameChanged()
    {
        // given
        let user1 = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        user1.name = "Foo A"
        
        let user2 = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        user2.name = "Bar"
        
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        conversation.mutableOtherActiveParticipants.addObject(user1)
        
        self.updateDisplayNameGeneratorWithUsers([user1, user2])
        
        XCTAssertEqual(user1.displayName, "Foo")
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { _ in
                user2.name = "Foo B"
                self.updateDisplayNameGeneratorWithUsers([user2])
                XCTAssertEqual(user1.displayName, "Foo A")
            },
            expectedChangedField: "nameChanged",
            expectedChangedKeys: KeySet(["displayName"])
        )
    }
    
    func testThatItDoesNotNotifyTheObserverOfANameChangeBecauseAUserWasRemovedAndLaterItsNameChanged()
    {
        // given
        let user1 = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        user1.name = "Foo A"
        
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        conversation.mutableOtherActiveParticipants.addObject(user1)
        
        self.updateDisplayNameGeneratorWithUsers([user1])
        
        XCTAssertTrue(user1.displayName == "Foo")
        XCTAssertTrue(conversation.otherActiveParticipants.containsObject(user1))
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, observer in
                conversation.mutableOtherActiveParticipants.removeObject(user1)
                self.uiMOC.saveOrRollback()
                observer.clearNotifications()
                user1.name = "Bar"
                self.updateDisplayNameGeneratorWithUsers([user1])
            },
            expectedChangedField: nil,
            expectedChangedKeys: KeySet()
        )
    }
    
    func testThatItNotifysTheObserverOfANameChangeBecauseAUserWasAddedLaterAndHisNameChanged()
    {
        // given
        let user1 = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        user1.name = "Foo A"
        
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        self.uiMOC.saveOrRollback()
        
        XCTAssertTrue(user1.displayName == "Foo")

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, observer in
                conversation.mutableOtherActiveParticipants.addObject(user1)
                self.uiMOC.saveOrRollback()
                observer.clearNotifications()
                self.notifyNameChange(user1, name: "Bar")
            },
            expectedChangedField: "nameChanged",
            expectedChangedKeys: KeySet(["displayName"])
        )
    }
    
    func testThatItNotifiesTheObserverOfAnInsertedMessage()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.lastReadServerTimeStamp = NSDate()
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, _ in conversation.appendMessageWithText("foo"); return },
            expectedChangedField: "messagesChanged",
            expectedChangedKeys: KeySet(key: "messages"))
    }
    
    func testThatItNotifiesTheObserverOfAnAddedParticipant()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, _ in conversation.mutableOtherActiveParticipants.addObject(user) },
            expectedChangedField: "participantsChanged",
            expectedChangedKeys: KeySet(key: "otherActiveParticipants"))
        
    }
    
    func testThatItNotifiesTheObserverOfAnRemovedParticipant()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.mutableOtherActiveParticipants.addObject(user)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: {conversation, _ in conversation.mutableOtherActiveParticipants.removeObject(user) },
            expectedChangedField: "participantsChanged",
            expectedChangedKeys: KeySet(key: "otherActiveParticipants"))
    }
    
    func testThatItNotifiesTheObserverIfTheSelfUserIsAdded()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        conversation.isSelfAnActiveMember = false
        self.uiMOC.saveOrRollback()
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: {conversation, _ in conversation.isSelfAnActiveMember = true },
            expectedChangedField: "participantsChanged",
            expectedChangedKeys: KeySet(key: "isSelfAnActiveMember"))
        
    }
    
    func testThatItNotifiesTheObserverWhenTheUserLeavesTheConversation()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        _ = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.isSelfAnActiveMember = true
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: {conversation, _ in conversation.isSelfAnActiveMember = false },
            expectedChangedField: "participantsChanged",
            expectedChangedKeys: KeySet(key: "isSelfAnActiveMember"))
        
    }
    
    func testThatItNotifiesTheObserverOfChangedLastModifiedDate()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, _ in conversation.lastModifiedDate = NSDate() },
            expectedChangedField: "lastModifiedDateChanged",
            expectedChangedKeys: KeySet(key: "lastModifiedDate"))
        
    }
    
    func testThatItNotifiesTheObserverOfChangedUnreadCount()
    {
        // given
        self.syncMOC.performGroupedBlockAndWait{
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.lastReadServerTimeStamp = NSDate()
            let message = ZMMessage.insertNewObjectInManagedObjectContext(self.syncMOC)
            message.visibleInConversation = conversation
            message.serverTimestamp = conversation.lastReadServerTimeStamp.dateByAddingTimeInterval(10)
            self.syncMOC.saveOrRollback()
            
            conversation.fetchUnreadMessages()
            self.syncMOC.saveOrRollback()
            XCTAssertEqual(conversation.estimatedUnreadCount, 1)
            
            // when
            self.checkThatItNotifiesTheObserverOfAChange(conversation,
                modifier: { conversation, _ in
                    conversation.lastReadServerTimeStamp = message.serverTimestamp
                    conversation.updateUnread()
                    XCTAssertEqual(conversation.estimatedUnreadCount, 0)
                },
                expectedChangedFields: KeySet(["unreadCountChanged", "conversationListIndicatorChanged"]),
                expectedChangedKeys: KeySet(["estimatedUnreadCount", "conversationListIndicator"]))
        }
    }
    
    func testThatItNotifiesTheObserverOfChangedDisplayName()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.Group
        
        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, _ in conversation.userDefinedName = "Cacao" },
            expectedChangedField: "nameChanged" ,
            expectedChangedKeys: KeySet(["displayName"]))
        
    }
    
    func testThatItNotifiesTheObserverOfChangedConnectionStatusWhenInsertingAConnection()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.OneOnOne
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, _ in
                conversation.connection = ZMConnection.insertNewObjectInManagedObjectContext(self.uiMOC)
                conversation.connection.status = ZMConnectionStatus.Pending
            },
            expectedChangedField: "connectionStateChanged" ,
            expectedChangedKeys: KeySet(key: "relatedConnectionState"))
    }
    
    func testThatItNotifiesTheObserverOfChangedConnectionStatusWhenUpdatingAConnection()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = ZMConversationType.OneOnOne
        conversation.connection = ZMConnection.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.connection.status = ZMConnectionStatus.Pending
        conversation.connection.to = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, _ in conversation.connection.status = ZMConnectionStatus.Accepted },
            expectedChangedField: "connectionStateChanged" ,
            expectedChangedKeys: KeySet(key: "relatedConnectionState"))
        
    }
    
    
    func testThatItNotifiesTheObserverOfChangedArchivedStatus()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, _ in conversation.isArchived = true },
            expectedChangedField: "isArchivedChanged" ,
            expectedChangedKeys: KeySet(key: "isArchived"))
        
    }
    
    func testThatItNotifiesTheObserverOfChangedSilencedStatus()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, _ in conversation.isSilenced = true },
            expectedChangedField: "isSilencedChanged" ,
            expectedChangedKeys: KeySet(key: "isSilenced"))
        
    }
    
    func addUnreadMissedCall(conversation: ZMConversation) {
        let systemMessage = ZMSystemMessage.insertNewObjectInManagedObjectContext(conversation.managedObjectContext)
        systemMessage.systemMessageType = .MissedCall;
        systemMessage.serverTimestamp = NSDate(timeIntervalSince1970:1231234)
        systemMessage.visibleInConversation = conversation
        conversation.updateUnreadMessagesWithMessage(systemMessage)
    }
    
    
    func testThatItNotifiesTheObserverOfAChangedListIndicatorBecauseOfAnUnreadMissedCall()
    {
        // given
        self.syncMOC.performGroupedBlockAndWait{
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            self.syncMOC.saveOrRollback()
            
            // when
            self.checkThatItNotifiesTheObserverOfAChange(conversation,
                modifier: { conversation, _ in
                    self.addUnreadMissedCall(conversation)
                },
                expectedChangedFields: KeySet(["conversationListIndicatorChanged", "messagesChanged"]),
                expectedChangedKeys: KeySet(["messages", "conversationListIndicator"]))
        }
    }
    
    func testThatItNotifiesTheObserverOfAChangedClearedTimeStamp()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, _ in
                conversation.clearedTimeStamp = NSDate()
            },
            expectedChangedField: "clearedChanged" ,
            expectedChangedKeys: KeySet(key: "clearedTimeStamp"))
    }
    
    func testThatItNotifiesTheObserverOfASecurityLevelChange() {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(conversation,
            modifier: { conversation, _ in
                conversation.securityLevel = .Secure
            },
            expectedChangedField: "securityLevelChanged" ,
            expectedChangedKeys: KeySet(key: "securityLevel"))
    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        let observer = TestConversationObserver()
        let token = conversation.addConversationObserver(observer)
        ZMConversation.removeConversationObserverForToken(token)
        
        
        // when
        conversation.userDefinedName = "Mario!"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.receivedChangeInfo.count, 0)
    }
    
    func testPerformanceOfCalculatingChangeNotificationsWhenANewMessageArrives()
    {
        let count = 50
        
        self.measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: false) {
            
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
            self.uiMOC.saveOrRollback()
            
            let observer = TestConversationObserver()
            let token = conversation.addConversationObserver(observer)
            
            self.startMeasuring()
            for _ in 1...count {
                conversation.appendMessageWithText("hello")
                self.uiMOC.processPendingChanges()
            }
            XCTAssertEqual(observer.receivedChangeInfo.count, count)
            self.stopMeasuring()
            ZMConversation.removeConversationObserverForToken(token)
        }
    }
}

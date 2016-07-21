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



class ConversationStatusStrategyTests: MessagingTest {
    var sut : ConversationStatusStrategy!
    var selfConversation : ZMConversation!
    
    override func setUp() {
        super.setUp()

        let syncSelfUser =  ZMUser.selfUserInContext(self.syncMOC)
        syncSelfUser.remoteIdentifier = NSUUID.createUUID()
        selfConversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
        selfConversation.remoteIdentifier = syncSelfUser.remoteIdentifier
        
        sut = ConversationStatusStrategy(managedObjectContext: self.syncMOC)
    }
    
    override func tearDown(){
        sut.tearDown()
        sut = nil
        super.tearDown()
    }

    func testThatItProcessesConversationsWithLocalModifications_LastRead() {
    
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.lastReadServerTimeStamp = NSDate()
            conversation.remoteIdentifier = NSUUID.createUUID()
            conversation.setLocallyModifiedKeys(Set(arrayLiteral: "lastReadServerTimeStamp"))
            
            XCTAssertEqual(self.selfConversation.messages.count, 0)

            // when
            self.sut.objectsDidChange(Set(arrayLiteral: conversation))
            
            // then
            XCTAssertEqual(self.selfConversation.messages.count, 1)
            guard let message = self.selfConversation.messages.array.first as? ZMClientMessage else {
                XCTFail("should insert message into self conversation")
                return
            }
            XCTAssertTrue(message.genericMessage.hasLastRead())
        }
    }
    
    func testThatItResetsUnread_LastRead() {
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.lastReadServerTimeStamp = NSDate()
            conversation.remoteIdentifier = NSUUID.createUUID()
            conversation.setLocallyModifiedKeys(Set(arrayLiteral: "lastReadServerTimeStamp"))
            conversation.appendMessageWithText("hey")

            conversation.didUpdateConversationWhileFetchingUnreadMessages()
            conversation.lastUnreadMissedCallDate = conversation.lastReadServerTimeStamp.dateByAddingTimeInterval(-10)
            conversation.lastUnreadKnockDate = conversation.lastReadServerTimeStamp.dateByAddingTimeInterval(-15)
            
            XCTAssertTrue(conversation.hasUnreadMissedCall)
            XCTAssertTrue(conversation.hasUnreadKnock)

            // when
            self.sut.objectsDidChange(Set(arrayLiteral: conversation))
            
            // then
            XCTAssertFalse(conversation.hasUnreadMissedCall)
            XCTAssertFalse(conversation.hasUnreadKnock)
        }
    }
    
    func testThatItProcessesConversationsWithLocalModifications_Cleared() {
        
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.clearedTimeStamp = NSDate()
            conversation.remoteIdentifier = NSUUID.createUUID()
            conversation.setLocallyModifiedKeys(Set(arrayLiteral: "clearedTimeStamp"))
            
            XCTAssertEqual(self.selfConversation.messages.count, 0)

            // when
            self.sut.objectsDidChange(Set(arrayLiteral: conversation))
            
            // then
            XCTAssertEqual(self.selfConversation.messages.count, 1)
            guard let message = self.selfConversation.messages.array.first as? ZMClientMessage else {
                XCTFail("should insert message into self conversation")
                return
            }
            XCTAssertTrue(message.genericMessage.hasCleared())
        }
    }
    
    func testThatItDeletesOlderMessages_Cleared() {
        
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.clearedTimeStamp = NSDate()
            conversation.remoteIdentifier = NSUUID.createUUID()
            conversation.setLocallyModifiedKeys(Set(arrayLiteral: "clearedTimeStamp"))
            
            let message = ZMMessage.insertNewObjectInManagedObjectContext(self.syncMOC)
            message.serverTimestamp = conversation.clearedTimeStamp
            message.visibleInConversation = conversation
            
            XCTAssertFalse((conversation.messages.array.first as! NSManagedObject).deleted)

            // when
            self.sut.objectsDidChange(Set(arrayLiteral: conversation))
            
            // then
            XCTAssertTrue((conversation.messages.array.first as! NSManagedObject).deleted)
        }
    }
    
    func testThatItAddsUnsyncedConversationsToTrackedObjects() {
        self.syncMOC.performGroupedBlockAndWait{
            // given
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.lastReadServerTimeStamp = NSDate()
            conversation.remoteIdentifier = NSUUID.createUUID()
            conversation.setLocallyModifiedKeys(Set(arrayLiteral: "lastReadServerTimeStamp"))
            
            XCTAssertEqual(self.selfConversation.messages.count, 0)
            
            // when
            let request = self.sut.fetchRequestForTrackedObjects()
            let result = self.syncMOC.executeFetchRequestOrAssert(request) as! [NSManagedObject]
            if (result.count > 0) {
                self.sut.addTrackedObjects(Set<NSManagedObject>(result))
            } else {
                XCTFail("should fetch insertedConversation")
            }
            
            // then
            XCTAssertEqual(self.selfConversation.messages.count, 1)
            guard let message = self.selfConversation.messages.array.first as? ZMClientMessage else {
                XCTFail("should insert message into self conversation")
                return
            }
            XCTAssertTrue(message.genericMessage.hasLastRead())
        }

    }
}


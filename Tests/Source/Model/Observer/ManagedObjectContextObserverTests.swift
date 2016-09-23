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


class ManagedObjectContextObserverTests : ZMBaseManagedObjectTest {
    
    override func setUp(){
        super.setUp()
        self.setUpCaches()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ZMApplicationDidEnterEventProcessingStateNotification"), object: nil)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

    }
    
    class TestObserver : NSObject, ZMConversationObserver, ZMUserObserver, ZMVoiceChannelStateObserver, ZMMessageObserver {
    
        var conversationNotes: [ConversationChangeInfo] = []
        var userNotes: [UserChangeInfo] = []
        var voiceChannelNotes: [VoiceChannelStateChangeInfo] = []
        var messageChangeNotes: [MessageChangeInfo] = []

        func conversationDidChange(_ note: ConversationChangeInfo!) {
            conversationNotes.append(note)
        }
        func userDidChange(_ note: UserChangeInfo!) {
            userNotes.append(note)
        }
        
        func voiceChannelStateDidChange(_ note: VoiceChannelStateChangeInfo) {
            voiceChannelNotes.append(note)
        }
        
        func messageDidChange(_ note: MessageChangeInfo!) {
            messageChangeNotes.append(note)
        }
    }
    
    func testThatItDoesNotPropagateChangesWhenAppIsInTheBackground() {
        
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        self.uiMOC.saveOrRollback()
        
        let observer = TestObserver()
        let token = conversation.add(observer)
        
        // when
        // app goes into the background
        self.uiMOC.globalManagedObjectContextObserver.propagateChanges = false

        conversation.userDefinedName = "Hans"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.conversationNotes.count, 0)
        ZMConversation.removeObserver(for: token)
    }
    
    func testThatItNotifiesAllObserversWhenTheAppGoesBackInTheForeground() {
        
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        user.name = "Hans"

        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.connection = ZMConnection.insertNewObject(in: self.uiMOC)
        conversation.connection!.to =  user
        conversation.connection!.status = .accepted
        self.uiMOC.saveOrRollback()
        
        let observer = TestObserver()
        let conversationToken = conversation.add(observer)
        let userToken = ZMUser.add(observer, forUsers: [user], managedObjectContext: self.uiMOC)
        
        // when
        self.uiMOC.globalManagedObjectContextObserver.propagateChanges = false

        user.name = "Horst"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.conversationNotes.count, 0)
        XCTAssertEqual(observer.userNotes.count, 0)
        
        // and when
        self.uiMOC.globalManagedObjectContextObserver.propagateChanges = true
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(observer.conversationNotes.count, 1)
        XCTAssertEqual(observer.userNotes.count, 1)

        ZMConversation.removeObserver(for: conversationToken)
        ZMUser.removeObserver(for: userToken)
    }
    
    
    func testThatItAddsCallStateChangesAndProcessThemLater() {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        self.uiMOC.saveOrRollback()
        
        let observer = TestObserver()
        let voiceChannelToken = conversation.voiceChannel.add(observer)
        
        // when
        conversation.callDeviceIsActive = true;
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral:conversation), notifyDirectly: false)
        
        // then
        XCTAssertEqual(observer.voiceChannelNotes.count, 0)
        
        // and when
        NotificationCenter.default.post(name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: self.uiMOC)
        
        // then
        XCTAssertEqual(observer.voiceChannelNotes.count, 1)
        
        conversation.voiceChannel.removeStateObserver(for: voiceChannelToken!)
    }
    
    func testThatItAddsCallStateChangesAndProcessesThemDirectly() {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        self.uiMOC.saveOrRollback()
        
        let observer = TestObserver()
        let voiceChannelToken = conversation.voiceChannel.add(observer)
        
        // when
        conversation.callDeviceIsActive = true;
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral:conversation), notifyDirectly: true)
        
        // then
        XCTAssertEqual(observer.voiceChannelNotes.count, 1)
        observer.voiceChannelNotes = []
        
        // and when
        NotificationCenter.default.post(name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: self.uiMOC)
        
        // then
        XCTAssertEqual(observer.voiceChannelNotes.count, 0)
        
        conversation.voiceChannel.removeStateObserver(for: voiceChannelToken!)
    }
    
    func testThatItFiltersZombieObjectsFromManagedObjectChangesInsertedAndUpdated() {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let zombieConversation = ZMConversation.insertNewObject(in:self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        let nonManagedObject = NSArray()
        let arrayContainingZombies = [nonManagedObject, conversation, zombieConversation]
        
        // when
        self.uiMOC.delete(zombieConversation)
        self.uiMOC.saveOrRollback()
        XCTAssertTrue(zombieConversation.isZombieObject)
        
        let changes = ManagedObjectChanges(
            inserted: arrayContainingZombies,
            deleted: arrayContainingZombies,
            updated: arrayContainingZombies
        )
        
        let filteredChanges = changes.changesWithoutZombies
        
        // then
        for changeType in [filteredChanges.inserted, filteredChanges.updated] {
            XCTAssertEqual(changeType.count, 2)
            XCTAssertTrue(changeType.contains(nonManagedObject))
            XCTAssertTrue(changeType.contains(conversation))
            for object in changeType where object is ZMManagedObject {
                XCTAssertFalse((object as! ZMManagedObject).isZombieObject)
            }
        }
        
        // deleted objects are zombies but we still want to be notified
        XCTAssertTrue(filteredChanges.deleted.contains(zombieConversation))
        XCTAssertEqual(filteredChanges.deleted.count, 3)
    }
    
    func testThatItAddsTheGlobalConversationObserverToItsObserversWhenEnteringTheForeground()  {
    
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        self.uiMOC.saveOrRollback()
        
        let observer = TestObserver()
        let conversationToken = conversation.add(observer)
        
        // when
        self.uiMOC.globalManagedObjectContextObserver.propagateChanges = false
        conversation.userDefinedName = "New name"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.conversationNotes.count, 0)
        
        // when
        self.uiMOC.globalManagedObjectContextObserver.propagateChanges = true
        conversation.userDefinedName = "Newer name"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.conversationNotes.count, 1)
        
        ZMConversation.removeObserver(for: conversationToken)
    }
    
    
    func testThatItAddsTheGlobalUserObserverToItsObserversWhenEnteringTheForeground()  {
        
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        user.name = "Hans"
        
        let observer = TestObserver()
        let userToken = ZMUser.add(observer, forUsers: [user], managedObjectContext: self.uiMOC)
        
        // when
        self.uiMOC.globalManagedObjectContextObserver.propagateChanges = false
        user.name = "New name"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.userNotes.count, 0)
        
        // when
        self.uiMOC.globalManagedObjectContextObserver.propagateChanges = true
        user.name = "Newer name"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.userNotes.count, 1)
        
        ZMUser.removeObserver(for: userToken)
    }
    
    func testThatItPropagatesChangesOfComputedProperties_Images() {
        
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let imageMessage = conversation.appendOTRMessage(withImageData: self.verySmallJPEGData(), nonce: UUID.create())
        self.uiMOC.zm_imageAssetCache.deleteAssetData(imageMessage.nonce, format: .original, encrypted: false)
        XCTAssertFalse(imageMessage.hasDownloadedImage)
        self.uiMOC.saveOrRollback()
        
        let observer = TestObserver()
        let messageObserver = ZMMessageNotification.add(observer, for: imageMessage)
        
        // when
        self.uiMOC.zm_imageAssetCache.storeAssetData(imageMessage.nonce, format: .medium, encrypted: false, data: self.verySmallJPEGData())
        XCTAssertTrue(imageMessage.hasDownloadedImage)
        self.uiMOC.globalManagedObjectContextObserver.notifyNonCoreDataChangeInManagedObject(imageMessage)
        
        // then
        if let note = observer.messageChangeNotes.first {
            XCTAssertTrue(note.imageChanged)
        } else {
            XCTFail("No note")
        }
        
        // after
        ZMMessageNotification.removeMessageObserver(for: messageObserver)
        
    }
    
    func testThatItPropagatesChangesOfComputedProperties_Files() {
        
        // given
        let filename = "video.mp4"
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentsURL = URL(fileURLWithPath: documents)
        let fileURL =  documentsURL.appendingPathComponent(filename)
        try? verySmallJPEGData().write(to: fileURL, options: Data.WritingOptions.atomic)
        defer { try! FileManager.default.removeItem(at: fileURL) }
        
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let fileMetadata = ZMVideoMetadata(fileURL: fileURL,
                                           duration: 0,
                                           dimensions: CGSize(width: 0, height: 0))
        let fileMessage = conversation.appendOTRMessage(with: fileMetadata, nonce: UUID.create())
        
        self.uiMOC.zm_fileAssetCache.deleteAssetData(fileMessage.nonce, fileName: filename, encrypted: false)
        XCTAssertFalse(fileMessage.hasDownloadedFile)
        self.uiMOC.saveOrRollback()
        
        let observer = TestObserver()
        let messageObserver = ZMMessageNotification.add(observer, for: fileMessage)
        
        // when
        self.uiMOC.zm_fileAssetCache.storeAssetData(fileMessage.nonce, fileName: filename, encrypted: false, data: self.verySmallJPEGData())
        XCTAssertTrue(fileMessage.hasDownloadedFile)
        self.uiMOC.globalManagedObjectContextObserver.notifyNonCoreDataChangeInManagedObject(fileMessage)
        
        // then
        if let note = observer.messageChangeNotes.first {
            XCTAssertTrue(note.fileAvailabilityChanged)
        } else {
            XCTFail("No note")
        }
        
        // after
        ZMMessageNotification.removeMessageObserver(for: messageObserver)
        
    }
    
}

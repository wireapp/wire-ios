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
@testable import WireDataModel

class ZMAssetClientMessageTests_Ephemeral : BaseZMAssetClientMessageTests {
    
    override func setUp() {
        super.setUp()
        deletionTimer.isTesting = true
        syncMOC.performGroupedBlockAndWait {
            self.obfuscationTimer.isTesting = true
        }
    }
    
    override func tearDown() {
        syncMOC.performGroupedBlockAndWait {
            self.syncMOC.zm_teardownMessageObfuscationTimer()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        uiMOC.performGroupedBlockAndWait {
            self.uiMOC.zm_teardownMessageDeletionTimer()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        super.tearDown()
    }
    
    var obfuscationTimer : ZMMessageDestructionTimer {
        return syncMOC.zm_messageObfuscationTimer
    }
    
    var deletionTimer : ZMMessageDestructionTimer {
        return uiMOC.zm_messageDeletionTimer
    }
}

// MARK: Sending
extension ZMAssetClientMessageTests_Ephemeral {
    
    func testThatItInsertsAnEphemeralMessageForAssets(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        let fileMetadata = addFile()
        
        // when
        let message = conversation.appendMessage(with: fileMetadata) as! ZMAssetClientMessage
        
        // then
        XCTAssertTrue(message.genericAssetMessage!.hasEphemeral())
        XCTAssertTrue(message.genericAssetMessage!.ephemeral.hasAsset())
        XCTAssertEqual(message.genericAssetMessage!.ephemeral.expireAfterMillis, Int64(10*1000))
    }
    
    func assetWithImage() -> ZMAsset {
        let original = ZMAssetOriginal.original(withSize: 1000, mimeType: "image", name: "foo")
        let remoteData = ZMAssetRemoteData.remoteData(withOTRKey: Data(), sha256: Data(), assetId: "id", assetToken: "token")
        let imageMetaData = ZMAssetImageMetaData.imageMetaData(withWidth: 30, height: 40)
        let imageMetaDataBuilder = imageMetaData.toBuilder()!
        imageMetaDataBuilder.setTag("bar")
        
        let preview = ZMAssetPreview.preview(withSize: 2000, mimeType: "video", remoteData: remoteData, imageMetaData: imageMetaDataBuilder.build())
        let asset  = ZMAsset.asset(withOriginal: original, preview: preview)
        return asset
    }
    
    func thumbnailEvent(for message: ZMAssetClientMessage) -> ZMUpdateEvent {
        let payload : [String : Any] = [
            "id": UUID.create(),
            "conversation": conversation.remoteIdentifier!.transportString(),
            "from": selfUser.remoteIdentifier!.transportString(),
            "time": Date().transportString(),
            "data": [
                "id": "fooooo"
            ],
            "type": "conversation.otr-message-add"
        ]
        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID())!
    }
    
    func testThatWhenUpdatingTheThumbnailAssetIDWeReplaceAnEphemeralMessageWithAnEphemeral(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        let fileMetadata = addFile()
        
        // when
        let message = conversation.appendMessage(with: fileMetadata) as! ZMAssetClientMessage
        
        let remoteMessage = ZMGenericMessage.genericMessage(pbMessage: assetWithImage(), messageID: message.nonce!)
        
        let event = thumbnailEvent(for: message)
        message.update(with: remoteMessage, updateEvent: event, initialUpdate: true)
    
        // then
        XCTAssertTrue(message.genericAssetMessage!.hasEphemeral())
        XCTAssertTrue(message.genericAssetMessage!.ephemeral.hasAsset())
        XCTAssertEqual(message.genericAssetMessage!.ephemeral.expireAfterMillis, Int64(10*1000))
    
    }
    
    func testThatItStartsTheTimerForMultipartMessagesWhenTheAssetIsUploaded(){
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
            let fileMetadata = self.addFile()
            let message = self.syncConversation.appendMessage(with: fileMetadata) as! ZMAssetClientMessage
            message.uploadState = .uploadingFullAsset
            
            // when
            message.update(withPostPayload: [:], updatedKeys: Set([#keyPath(ZMAssetClientMessage.uploadState)]))
            
            // then
            XCTAssertEqual(message.uploadState, AssetUploadState.uploadingFullAsset)
            XCTAssertEqual(self.obfuscationTimer.runningTimersCount, 1)
            XCTAssertTrue(self.obfuscationTimer.isTimerRunning(for: message))
        }
    }
    
    func testThatItStartsTheTimerForImageAssetMessageWhenTheAssetIsUploaded(){
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
            let message = self.syncConversation.appendMessage(withImageData: self.verySmallJPEGData()) as! ZMAssetClientMessage
            message.uploadState = .uploadingFullAsset
            
            // when
            let emptyDict = [String: String]()
            let time = Date().transportString()
            let payload: [AnyHashable: Any] = ["deleted": emptyDict, "missing": emptyDict, "redundant": emptyDict, "time": time]

            message.update(
                withPostPayload: payload,
                updatedKeys: [#keyPath(ZMAssetClientMessage.uploadState)]
            )
            
            // then
            XCTAssertEqual(message.uploadState, AssetUploadState.uploadingFullAsset)
            XCTAssertEqual(self.obfuscationTimer.runningTimersCount, 1)
            XCTAssertTrue(self.obfuscationTimer.isTimerRunning(for: message))
        }
    }
    
    func testThatItDoesNotStartTheTimerForMultipartMessagesWhenTheAssetWasNotUploaded(){
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
            let fileMetadata = self.addFile()
            let message = self.syncConversation.appendMessage(with: fileMetadata) as! ZMAssetClientMessage
            
            // when
            message.update(withPostPayload: [:], updatedKeys: Set())
            
            // then
            XCTAssertEqual(message.uploadState, AssetUploadState.uploadingPlaceholder)
            XCTAssertEqual(self.obfuscationTimer.runningTimersCount, 0)
        }
    }
    
    func testThatItDoesNotStartTheTimerForImageAssetMessageWhenTheAssetWasNotUploaded(){
        self.syncMOC.performGroupedBlockAndWait {
            // given
            self.syncConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
            let message = self.syncConversation.appendMessage(withImageData: self.verySmallJPEGData()) as! ZMAssetClientMessage
            
            // when
            message.update(withPostPayload: [:], updatedKeys: Set())
            
            // then
            XCTAssertEqual(message.uploadState, .uploadingFullAsset)
            XCTAssertEqual(self.obfuscationTimer.runningTimersCount, 0)
        }
    }
    
    func testThatTheEphemeralMessageHasImageProperties() {
        
        self.syncMOC.performGroupedBlockAndWait {
            // GIVEN
            self.conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
            let data = self.verySmallJPEGData()
            let message = self.conversation.appendMessage(withImageData: data) as! ZMAssetClientMessage
            
            self.syncMOC.saveOrRollback()
            
            // WHEN
            let size = CGSize(width: 368, height: 520)
            let properties = ZMIImageProperties(size: size, length: 1024, mimeType: "image/jpg")
            message.imageAssetStorage.setImageData(data, for: .medium, properties: properties)
            self.syncMOC.saveOrRollback()
            
            // THEN
            XCTAssertEqual(message.mimeType, "image/jpg")
            XCTAssertEqual(message.size, 1024)
            XCTAssertEqual(message.imageMessageData?.originalSize, size)
        }
    }
    
    func testThatItExtendsTheObfuscationTimer() {
        var oldTimer: ZMTimer?
        var message: ZMAssetClientMessage!
        
        // given
        self.syncMOC.performGroupedBlockAndWait {
            // set timeout
            self.syncConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
            
            // send file
            let fileMetadata = self.addFile()
            message = self.syncConversation.appendMessage(with: fileMetadata) as? ZMAssetClientMessage
            message.uploadState = .uploadingFullAsset
            message.update(withPostPayload: [:], updatedKeys: Set([#keyPath(ZMAssetClientMessage.uploadState)]))
            
            // check a timer was started
            oldTimer = self.obfuscationTimer.timer(for: message)
            XCTAssertNotNil(oldTimer)
        }
        
        // when timer extended by 5 seconds
        self.syncMOC.performGroupedBlockAndWait {
            message.extendDestructionTimer(to: Date(timeIntervalSinceNow: 15))
        }
        
        // then a new timer was created
        self.syncMOC.performGroupedBlockAndWait {
            let newTimer = self.obfuscationTimer.timer(for: message)
            XCTAssertNotEqual(oldTimer, newTimer)
        }
    }
    
    func testThatItDoesNotExtendTheObfuscationTimerWhenNewDateIsEarlier() {
        var oldTimer: ZMTimer?
        var message: ZMAssetClientMessage!
        
        // given
        self.syncMOC.performGroupedBlockAndWait {
            // set timeout
            self.syncConversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
            
            // send file
            let fileMetadata = self.addFile()
            message = self.syncConversation.appendMessage(with: fileMetadata) as? ZMAssetClientMessage
            message.uploadState = .uploadingFullAsset
            message.update(withPostPayload: [:], updatedKeys: Set([#keyPath(ZMAssetClientMessage.uploadState)]))
            
            // check a timer was started
            oldTimer = self.obfuscationTimer.timer(for: message)
            XCTAssertNotNil(oldTimer)
        }
        
        // when timer "extended" 5 seconds earlier
        self.syncMOC.performGroupedBlockAndWait {
            message.extendDestructionTimer(to: Date(timeIntervalSinceNow: 5))
        }
        
        // then no new timer created
        self.syncMOC.performGroupedBlockAndWait {
            let newTimer = self.obfuscationTimer.timer(for: message)
            XCTAssertEqual(oldTimer, newTimer)
        }
    }
}


// MARK: Receiving

extension ZMAssetClientMessageTests_Ephemeral {
    
    
    func testThatItStartsATimerForImageAssetMessagesIfTheMessageIsAMessageOfTheOtherUser(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()
        
        let fileMetadata = self.addFile()
        let message = conversation.appendMessage(with: fileMetadata) as! ZMAssetClientMessage
        message.sender = sender
        message.add(ZMGenericMessage.genericMessage(withUploadedOTRKey: Data(), sha256: Data(), messageID: message.nonce!))
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded())
        
        // when
        XCTAssertTrue(message.startSelfDestructionIfNeeded())
        
        // then
        XCTAssertEqual(self.deletionTimer.runningTimersCount, 1)
        XCTAssertTrue(self.deletionTimer.isTimerRunning(for: message))
    }
    
    func testThatItStartsATimerIfTheMessageIsAMessageOfTheOtherUser(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()
        
        let nonce = UUID()
        let message = ZMAssetClientMessage(nonce: nonce, managedObjectContext: uiMOC)
        message.sender = sender
        message.visibleInConversation = conversation
        
        let imageData = verySmallJPEGData()
        let assetMessage = ZMGenericMessage.genericMessage(withImageSize: CGSize.zero, mimeType: "", size: UInt64(imageData.count), nonce: nonce, expiresAfter: 10)
        message.add(assetMessage)
        
        let uploaded = ZMGenericMessage.genericMessage(withUploadedOTRKey: .randomEncryptionKey(), sha256: .zmRandomSHA256Key(), messageID: message.nonce!, expiresAfter: NSNumber(value: conversation.messageDestructionTimeoutValue))
        message.add(uploaded)
        message.setImageData(imageData, for: .medium, properties: nil)
        
        // when
        XCTAssertTrue(message.startSelfDestructionIfNeeded())
        
        // then
        XCTAssertEqual(self.deletionTimer.runningTimersCount, 1)
        XCTAssertTrue(self.deletionTimer.isTimerRunning(for: message))
    }
    
    func appendPreviewImageMessage() -> ZMAssetClientMessage {
        let imageData = verySmallJPEGData()
        let message = ZMAssetClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        conversation.sortedAppendMessage(message)
        
        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
        let properties = ZMIImageProperties(size:imageSize, length:UInt(imageData.count), mimeType:"image/jpeg")
        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(),
                                              macKey: Data.zmRandomSHA256Key(),
                                              mac: Data.zmRandomSHA256Key())
        
        let imageMessage = ZMGenericMessage.genericMessage(mediumImageProperties: properties,
                                                           processedImageProperties: properties,
                                                           encryptionKeys: keys,
                                                           nonce: UUID.create(),
                                                           format: .preview)
        message.add(imageMessage)
        return message
    }
    
    func testThatItDoesNotStartsATimerIfTheMessageIsAMessageOfTheOtherUser_NoMediumImage(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()
        
        let message = appendPreviewImageMessage()
        message.sender = sender
        XCTAssertNil(message.imageAssetStorage.mediumGenericMessage)
        XCTAssertNotNil(message.imageAssetStorage.previewGenericMessage)

        // when
        XCTAssertFalse(message.startSelfDestructionIfNeeded())
        
        // then
        XCTAssertEqual(self.deletionTimer.runningTimersCount, 0)
        XCTAssertFalse(self.deletionTimer.isTimerRunning(for: message))
    }
    
    func testThatItDoesNotStartATimerIfTheMessageIsAMessageOfTheOtherUser_NotUploadedYet(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()
        
        let fileMetadata = self.addFile()
        let message = conversation.appendMessage(with: fileMetadata) as! ZMAssetClientMessage
        message.sender = sender
        XCTAssertFalse(message.genericAssetMessage!.assetData!.hasUploaded())
        
        // when
        XCTAssertFalse(message.startSelfDestructionIfNeeded())
        
        // then
        XCTAssertEqual(self.deletionTimer.runningTimersCount, 0)
        XCTAssertFalse(self.deletionTimer.isTimerRunning(for: message))
    }
    
    func testThatItStartsATimerIfTheMessageIsAMessageOfTheOtherUser_UploadCancelled(){
        // given
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        conversation.lastReadServerTimeStamp = Date()
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()
        
        let fileMetadata = self.addFile()
        let message = conversation.appendMessage(with: fileMetadata) as! ZMAssetClientMessage
        message.sender = sender
        message.add(ZMGenericMessage.genericMessage(notUploaded: ZMAssetNotUploaded.CANCELLED, messageID: message.nonce!))
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasNotUploaded())
        
        // when
        XCTAssertTrue(message.startSelfDestructionIfNeeded())
        
        // then
        XCTAssertEqual(self.deletionTimer.runningTimersCount, 1)
        XCTAssertTrue(self.deletionTimer.isTimerRunning(for: message))
    }
    
    func testThatItDoesNotStartATimerForAMessageOfTheSelfuser(){
        // given
        let timeout : TimeInterval = 0.1
        conversation.messageDestructionTimeout =  .local(MessageDestructionTimeoutValue(rawValue: timeout))
        let fileMetadata = self.addFile()
        let message = conversation.appendMessage(with: fileMetadata) as! ZMAssetClientMessage
        message.add(ZMGenericMessage.genericMessage(withUploadedOTRKey: Data(), sha256: Data(), messageID: message.nonce!))
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded())
        
        // when
        XCTAssertFalse(message.startDestructionIfNeeded())
        
        // then
        XCTAssertEqual(self.deletionTimer.runningTimersCount, 0)
    }
    
    func testThatItCreatesADeleteForAllMessageWhenTheTimerFires(){
        // given
        let timeout : TimeInterval = 0.1
        conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: timeout))
        
        let fileMetadata = self.addFile()
        let message = conversation.appendMessage(with: fileMetadata) as! ZMAssetClientMessage
        conversation.conversationType = .oneOnOne
        message.sender = ZMUser.insertNewObject(in: uiMOC)
        message.sender?.remoteIdentifier = UUID.create()
        message.add(ZMGenericMessage.genericMessage(withUploadedOTRKey: Data(), sha256: Data(), messageID: message.nonce!))
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded())
        
        // when
        XCTAssertTrue(message.startDestructionIfNeeded())
        XCTAssertEqual(self.deletionTimer.runningTimersCount, 1)
        
        spinMainQueue(withTimeout: 0.5)
        
        // then
        guard let deleteMessage = conversation.hiddenMessages.firstObject as? ZMClientMessage
            else { return XCTFail()}
        
        guard let genericMessage = deleteMessage.genericMessage, genericMessage.hasDeleted()
            else {return XCTFail()}
        
        XCTAssertNotEqual(deleteMessage, message)
        XCTAssertNotNil(message.sender)
        XCTAssertNil(message.genericAssetMessage)
        XCTAssertEqual(message.dataSet.count, 0)
        XCTAssertNil(message.destructionDate)
    }
    
    func testThatItExtendsTheDeletionTimer() {
        var oldTimer: ZMTimer?
        var message: ZMAssetClientMessage!
        
        // given
        self.conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        
        // send file
        let fileMetadata = self.addFile()
        message = self.conversation.appendMessage(with: fileMetadata) as? ZMAssetClientMessage
        message.sender = ZMUser.insertNewObject(in: self.uiMOC)
        message.sender?.remoteIdentifier = UUID.create()
        
        message.add(ZMGenericMessage.genericMessage(withUploadedOTRKey: Data(), sha256: Data(), messageID: message.nonce!))
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded())
        
        // check a timer was started
        XCTAssertTrue(message.startDestructionIfNeeded())
        oldTimer = self.deletionTimer.timer(for: message)
        XCTAssertNotNil(oldTimer)
        
        // when timer extended by 5 seconds
        message.extendDestructionTimer(to: Date(timeIntervalSinceNow: 15))
        
        // force a wait so timer map is updated
        _ = wait(withTimeout: 0.5, verificationBlock: { return false })
        
        // then a new timer was created
        let newTimer = self.deletionTimer.timer(for: message)
        XCTAssertNotEqual(oldTimer, newTimer)
    }
    
    func testThatItDoesNotExtendTheDeletionTimerWhenNewDateIsEarlier() {
        var oldTimer: ZMTimer?
        var message: ZMAssetClientMessage!
        
        // given
        self.conversation.messageDestructionTimeout = .local(MessageDestructionTimeoutValue(rawValue: 10))
        
        // send file
        let fileMetadata = self.addFile()
        message = self.conversation.appendMessage(with: fileMetadata) as? ZMAssetClientMessage
        message.sender = ZMUser.insertNewObject(in: self.uiMOC)
        message.sender?.remoteIdentifier = UUID.create()
        
        message.add(ZMGenericMessage.genericMessage(withUploadedOTRKey: Data(), sha256: Data(), messageID: message.nonce!))
        XCTAssertTrue(message.genericAssetMessage!.assetData!.hasUploaded())
        
        // check a timer was started
        XCTAssertTrue(message.startDestructionIfNeeded())
        oldTimer = self.deletionTimer.timer(for: message)
        XCTAssertNotNil(oldTimer)
        
        // when timer "extended" by 5 seconds earlier
        message.extendDestructionTimer(to: Date(timeIntervalSinceNow: 5))
        
        // force a wait so timer map is updated
        _ = wait(withTimeout: 0.5, verificationBlock: { return false })
        
        // then a new timer was created
        let newTimer = self.deletionTimer.timer(for: message)
        XCTAssertEqual(oldTimer, newTimer)
    }
}




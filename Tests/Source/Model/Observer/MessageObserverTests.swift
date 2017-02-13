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
@testable import ZMCDataModel


class MessageObserverTests : NotificationDispatcherTestBase {
    
    
    
    var messageObserver : MessageObserver!
    
    override func setUp() {
        super.setUp()
        messageObserver = MessageObserver()
    }

    override func tearDown() {
        messageObserver = nil
        super.tearDown()
    }
    
    func checkThatItNotifiesTheObserverOfAChange(_ message : ZMMessage, modifier: (ZMMessage) -> Void, expectedChangedField : String?, customAffectedKeys: AffectedKeys? = nil) {
        
        // given
        var token : NSObjectProtocol!
        performIgnoringZMLogError {
            token = MessageChangeInfo.add(observer: self.messageObserver, for: message)
        }
        
        self.uiMOC.saveOrRollback()
        
        // when
        modifier(message)
        self.uiMOC.saveOrRollback()
        self.spinMainQueue(withTimeout: 0.5)
        
        // then
        if expectedChangedField != nil {
            XCTAssertEqual(messageObserver.notifications.count, 1)
        } else {
            XCTAssertEqual(messageObserver.notifications.count, 0)
        }
        
        // and when
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertTrue(messageObserver.notifications.count <= 1, "Should have changed only once")
        
        let messageInfoKeys = [
            "imageChanged",
            "deliveryStateChanged",
            "senderChanged",
            "linkPreviewChanged",
            "isObfuscatedChanged"
        ]
        
        if let changedField = expectedChangedField {
            if let changes = messageObserver.notifications.first {
                for key in messageInfoKeys {
                    if let value = changes.value(forKey: key) as? NSNumber {
                        if key == changedField {
                            XCTAssertTrue(value.boolValue, "\(key) was supposed to be true")
                        } else {
                            XCTAssertFalse(value.boolValue, "\(key) was supposed to be false")
                        }
                    }
                    else {
                        XCTFail("Can't find key or key is not boolean for '\(key)'")
                    }
                }
            }
        }
        performIgnoringZMLogError {
            MessageChangeInfo.remove(observer: token, for: message)
        }
    }
    
    func testThatItNotifiesObserverWhenTheFileTransferStateChanges() {
        // given
        let message = ZMAssetClientMessage.insertNewObject(in: self.uiMOC)
        message.transferState = .uploading
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(message,
                                                     modifier: {
                                                        if let msg = $0 as? ZMAssetClientMessage {
                                                            msg.transferState = .uploaded
                                                        }
            },
                                                     expectedChangedField: ZMAssetClientMessageTransferStateKey
        )
    }
    
    
    func testThatItNotifiesObserverWhenTheMediumImageDataChanges() {
        // given
        let message = ZMAssetClientMessage.insertNewObject(in: self.uiMOC)
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(message,
                                                     modifier: { message in
                                                        let imageData = verySmallJPEGData()
                                                        let imageSize = ZMImagePreprocessor.sizeOfPrerotatedImage(with: imageData)
                                                        let properties = ZMIImageProperties(size:imageSize, length:UInt(imageData.count), mimeType:"image/jpeg")
                                                        let keys = ZMImageAssetEncryptionKeys(otrKey: Data.randomEncryptionKey(),
                                                                                              macKey: Data.zmRandomSHA256Key(),
                                                                                              mac: Data.zmRandomSHA256Key())
                                                        
                                                        let imageMessage = ZMGenericMessage.genericMessage(mediumImageProperties: properties,
                                                                                                           processedImageProperties: properties,
                                                                                                           encryptionKeys: keys,
                                                                                                           nonce: UUID.create().transportString(),
                                                                                                           format: .preview)
                                                        (message as? ZMAssetClientMessage)?.add(imageMessage)
            },
                                                     expectedChangedField: "imageChanged"
        )
    }
    
    func testThatItNotifiesObserverWhenTheLinkPreviewStateChanges() {
        // when
        checkThatItNotifiesTheObserverOfAChange(
            ZMClientMessage.insertNewObject(in: uiMOC),
            modifier: { ($0 as? ZMClientMessage)?.linkPreviewState = .downloaded },
            expectedChangedField: "linkPreviewChanged"
        )
    }
    
    func testThatItNotifiesObserverWhenTheLinkPreviewStateChanges_NewGenericMessageData() {
        // given
        let clientMessage = ZMClientMessage.insertNewObject(in: uiMOC)
        let nonce = UUID.create()
        clientMessage.add(ZMGenericMessage.message(text: name!, nonce: nonce.transportString()).data())
        let preview = ZMLinkPreview.linkPreview(
            withOriginalURL: "www.example.com",
            permanentURL: "www.example.com/permanent",
            offset: 42,
            title: "title",
            summary: "summary",
            imageAsset: nil
        )
        let updateGenericMessage = ZMGenericMessage.message(text: name!, linkPreview: preview, nonce: nonce.transportString())
        uiMOC.saveOrRollback()
        
        // when
        checkThatItNotifiesTheObserverOfAChange(
            clientMessage,
            modifier: { ($0 as? ZMClientMessage)?.add(updateGenericMessage.data()) },
            expectedChangedField: "linkPreviewChanged"
        )
    }
    
    func testThatItDoesNotNotifiyObserversWhenTheSmallImageDataChanges() {
        // given
        let message = ZMImageMessage.insertNewObject(in: self.uiMOC)
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(message,
                                                     modifier: { message in
                                                        if let imageMessage = message as? ZMImageMessage {
                                                            imageMessage.previewData = self.verySmallJPEGData()}
            },
                                                     expectedChangedField: nil
        )
    }
    
    func testThatItNotifiesWhenAReactionIsAddedOnMessage() {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.appendMessage(withText: "foo") as! ZMClientMessage
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { $0.addReaction("LOVE IT, HUH", forUser: ZMUser.selfUser(in: self.uiMOC))},
            expectedChangedField: "reactionsChanged"
        )
    }
    
    func testThatItNotifiesWhenAReactionIsAddedOnMessageFromADifferentUser() {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.appendMessage(withText: "foo") as! ZMClientMessage

        let otherUser = ZMUser.insertNewObject(in:uiMOC)
        otherUser.name = "Hans"
        otherUser.remoteIdentifier = .create()
        uiMOC.saveOrRollback()

        // when
        checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { $0.addReaction("👻", forUser: otherUser) },
            expectedChangedField: "reactionsChanged"
        )
    }
    
    func testThatItNotifiesWhenAReactionIsUpdateForAUserOnMessage() {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.appendMessage(withText: "foo") as! ZMClientMessage

        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        message.addReaction("LOVE IT, HUH", forUser: selfUser)
        uiMOC.saveOrRollback()

        // when
        self.checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: {$0.addReaction(nil, forUser: selfUser)},
            expectedChangedField: "reactionsChanged"
        )
    }
    
    func testThatItNotifiesWhenAReactionFromADifferentUserIsAddedOnTopOfSelfReaction() {
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.appendMessage(withText: "foo") as! ZMClientMessage

        let otherUser = ZMUser.insertNewObject(in:uiMOC)
        otherUser.name = "Hans"
        otherUser.remoteIdentifier = .create()
        
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        message.addReaction("👻", forUser: selfUser)
        uiMOC.saveOrRollback()

        // when
        checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { $0.addReaction("👻", forUser: otherUser) },
            expectedChangedField: "reactionsChanged"
        )
    }

    func testThatItNotifiesObserversWhenDeliveredChanges(){
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let message = conversation.appendMessage(withText: "foo") as! ZMClientMessage
        XCTAssertFalse(message.delivered)
        uiMOC.saveOrRollback()
        
        // when
        checkThatItNotifiesTheObserverOfAChange(
            message,
            modifier: { $0.markAsSent()
                        XCTAssertTrue(($0 as! ZMOTRMessage).delivered)},
            expectedChangedField: "deliveryStateChanged"
        )
    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let message = ZMClientMessage.insertNewObject(in: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        self.performIgnoringZMLogError{
            let token = MessageChangeInfo.add(observer: self.messageObserver, for: message)
            MessageChangeInfo.remove(observer: token, for: message)
        }
        // when
        message.serverTimestamp = Date()
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(messageObserver.notifications.count, 0)
    }
}

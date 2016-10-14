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
@testable import ZMCDataModel

// MARK: - Sending

class ZMClientMessageTests_Deletion: BaseZMClientMessageTests {
    
    func testThatItDeletesAMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        guard let sut = conversation.appendMessage(withText: name!) as? ZMMessage else { return XCTFail() }
        
        // when
        performPretendingUiMocIsSyncMoc { 
            sut.deleteForEveryone()
        }
        
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        assertDeletedContent(ofMessage: sut as! ZMOTRMessage, inConversation: conversation)
    }
    
    func testThatItDeletesAnAssetMessage_Image() {
        // given
        setUpCaches()
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        let sut = conversation.appendOTRMessage(withImageData: mediumJPEGData(), nonce: .create())
        
        let cache = uiMOC.zm_imageAssetCache!
        cache.storeAssetData(sut.nonce, format: .preview, encrypted: false, data: verySmallJPEGData())
        cache.storeAssetData(sut.nonce, format: .medium, encrypted: false, data: mediumJPEGData())
        cache.storeAssetData(sut.nonce, format: .original, encrypted: false, data: mediumJPEGData())
        cache.storeAssetData(sut.nonce, format: .preview, encrypted: true, data: verySmallJPEGData())
        cache.storeAssetData(sut.nonce, format: .medium, encrypted: true, data: mediumJPEGData())
        
        // when
        performPretendingUiMocIsSyncMoc {
            sut.deleteForEveryone()
        }
        
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        assertDeletedContent(ofMessage: sut, inConversation: conversation)
        wipeCaches()
    }
    
    func testThatItDeletesAnAssetMessage_File() {
        // given
        setUpCaches()
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        let data = "Hello World".data(using: String.Encoding.utf8)!
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let url = URL(fileURLWithPath: documents).appendingPathComponent("file.dat")

        defer { try! FileManager.default.removeItem(at: url) }

        try? data.write(to: url, options: [.atomic])
        let fileMetaData = ZMFileMetadata(fileURL: url, thumbnail: verySmallJPEGData())
        let sut = conversation.appendOTRMessage(with: fileMetaData, nonce: .create())

        let cache = uiMOC.zm_imageAssetCache!
        let fileCache = uiMOC.zm_fileAssetCache
        
        cache.storeAssetData(sut.nonce, format: .original, encrypted: true, data: verySmallJPEGData())
        fileCache.storeAssetData(sut.nonce, fileName: "file.dat", encrypted: true, data: mediumJPEGData())
        
        XCTAssertNotNil(cache.assetData(sut.nonce, format: .original, encrypted: false))
        XCTAssertNotNil(fileCache.assetData(sut.nonce, fileName: "file.dat", encrypted: false))
        
        // when
        performPretendingUiMocIsSyncMoc {
            sut.deleteForEveryone()
        }
        
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        assertDeletedContent(ofMessage: sut, inConversation: conversation, fileName: "file.dat")
        wipeCaches()
    }
    
    func testThatItDeletesAPreEndtoEndPlainTextMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        let sut = ZMTextMessage.insertNewObject(in: uiMOC) // Pre e2ee plain text message
        
        sut.visibleInConversation = conversation
        sut.nonce = .create()
        sut.sender = selfUser

        // when
        performPretendingUiMocIsSyncMoc {
            sut.deleteForEveryone()
        }

        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertTrue(sut.hasBeenDeleted)
        XCTAssertNil(sut.visibleInConversation)
        XCTAssertEqual(sut.hiddenInConversation, conversation)
        XCTAssertNil(sut.text)
        XCTAssertNil(sut.messageText)
        XCTAssertNil(sut.sender)
        XCTAssertNil(sut.senderClientID)
    }
    
    func testThatItDeletesAPreEndtoEndKnockMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        let sut = ZMKnockMessage.insertNewObject(in: uiMOC) // Pre e2ee knock message
        
        sut.visibleInConversation = conversation
        sut.nonce = .create()
        sut.sender = selfUser
        
        // when
        performPretendingUiMocIsSyncMoc {
            sut.deleteForEveryone()
        }
        
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertTrue(sut.hasBeenDeleted)
        XCTAssertNil(sut.visibleInConversation)
        XCTAssertEqual(sut.hiddenInConversation, conversation)
        XCTAssertNil(sut.sender)
        XCTAssertNil(sut.senderClientID)
    }
    
    func testThatItDeletesAPreEndToEndImageMessage() {
        // given
        setUpCaches()
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        let sut = ZMImageMessage.insertNewObject(in: uiMOC) // Pre e2ee image message
        
        sut.visibleInConversation = conversation
        sut.nonce = .create()
        sut.sender = selfUser
        
        let cache = uiMOC.zm_imageAssetCache!
        cache.storeAssetData(sut.nonce, format: .preview, encrypted: false, data: verySmallJPEGData())
        cache.storeAssetData(sut.nonce, format: .medium, encrypted: false, data: mediumJPEGData())
        cache.storeAssetData(sut.nonce, format: .original, encrypted: false, data: mediumJPEGData())
        
        // when
        performPretendingUiMocIsSyncMoc {
            sut.deleteForEveryone()
        }
        
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertTrue(sut.hasBeenDeleted)
        XCTAssertNil(sut.visibleInConversation)
        XCTAssertEqual(sut.hiddenInConversation, conversation)
        XCTAssertNil(sut.mediumRemoteIdentifier)
        XCTAssertNil(sut.mediumData)
        XCTAssertNil(sut.sender)
        XCTAssertNil(sut.senderClientID)
        
        XCTAssertNil(cache.assetData(sut.nonce, format: .original, encrypted: false))
        XCTAssertNil(cache.assetData(sut.nonce, format: .medium, encrypted: false))
        XCTAssertNil(cache.assetData(sut.nonce, format: .preview, encrypted: false))
        wipeCaches()
    }
    
    func testThatAMessageSentByAnotherUserCanotBeDeleted() {
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        let otherUser = ZMUser.insertNewObject(in:uiMOC)
        guard let sut = conversation.appendMessage(withText: name!) as? ZMMessage else { return XCTFail() }
        sut.sender = otherUser
        
        // when
        performPretendingUiMocIsSyncMoc {
            sut.deleteForEveryone()
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertFalse(sut.hasBeenDeleted)
        XCTAssertEqual(sut.visibleInConversation, conversation)
        XCTAssertNil(sut.hiddenInConversation)
    }
    
    func testThatTheInsertedDeleteMessageDoesNotHaveAnExpirationDate() {
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        let nonce = UUID.create()
        let deletedMessage = ZMGenericMessage(deleteMessage: nonce.transportString(), nonce: UUID().transportString())
        
        // when
        let sut = conversation.append(deletedMessage, expires: false, hidden: true)
        
        // then
        XCTAssertNil(sut.expirationDate)
        XCTAssertEqual(sut.hiddenInConversation, conversation)
        XCTAssertNil(sut.visibleInConversation)
        XCTAssertTrue(sut.hasBeenDeleted)
    }
}

// MARK: - System Messages

extension ZMClientMessageTests_Deletion {
    
    func testThatItDoesNotInsertASystemMessageIfTheMessageDoesNotExist() {
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.lastModifiedDate = Date(timeIntervalSince1970: 123456789)
        conversation.remoteIdentifier = .create()
        
        // when
        let updateEvent = createMessageDeletedUpdateEvent(.create(), conversationID: conversation.remoteIdentifier!, senderID: selfUser.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.messageUpdateResult(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        XCTAssertEqual(conversation.messages.count, 0)
    }
    
    func testThatItDoesNotInsertASystemMessageWhenAMessageIsDeletedForEveryoneLocally() {
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        guard let sut = conversation.appendMessage(withText: name!) else { return XCTFail() }
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMMessage.deleteForEveryone(sut)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(conversation.messages.count, 0)
    }
}

// MARK: - Receiving

extension ZMClientMessageTests_Deletion {

    func testThatAMessageCanNotBeDeletedByAUserThatDidNotInitiallySentIt() {
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.lastModifiedDate = Date(timeIntervalSince1970: 123456789)
        conversation.remoteIdentifier = .create()
        guard let sut = conversation.appendMessage(withText: name!) as? ZMMessage else { return XCTFail() }

        // when
        let updateEvent = createMessageDeletedUpdateEvent(sut.nonce, conversationID: conversation.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc { 
            ZMOTRMessage.messageUpdateResult(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(conversation.messages.count, 1)
        if let systemMessage = conversation.messages.lastObject as? ZMSystemMessage , systemMessage.systemMessageType == .messageDeletedForEveryone {
            return XCTFail()
        }
    }
    
    func testThatAMessageCanBeDeletedByTheUserThatDidInitiallySentIt() {
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        guard let sut = conversation.appendMessage(withText: name!) as? ZMMessage else { return XCTFail() }
        let lastModified = Date(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified

        // when
        let updateEvent = createMessageDeletedUpdateEvent(sut.nonce, conversationID: conversation.remoteIdentifier!, senderID: sut.sender!.remoteIdentifier!)

        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.messageUpdateResult(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        assertDeletedContent(ofMessage: sut as! ZMOTRMessage, inConversation: conversation)
        // No system message as the selfUser was the sender
        XCTAssertEqual(conversation.messages.count, 0)
        // A deletion should not update the lastModified date
        XCTAssertEqual(conversation.lastModifiedDate, lastModified)
    }
    
    func testThatAMessageSentByAnotherUserCanBeDeletedAndASystemMessageIsInserted() {
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        let otherUser = ZMUser.insertNewObject(in:uiMOC)
        otherUser.remoteIdentifier = .create()
        let message = ZMClientMessage.insertNewObject(in: uiMOC)
        message.sender = otherUser
        message.visibleInConversation = conversation
        message.nonce = .create()
        let timestamp = Date(timeIntervalSince1970: 123456789)
        message.serverTimestamp = timestamp
        
        let lastModified = Date(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified

        // when
        let updateEvent = createMessageDeletedUpdateEvent(message.nonce, conversationID: conversation.remoteIdentifier!, senderID: otherUser.remoteIdentifier!)
        
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.messageUpdateResult(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        assertDeletedContent(ofMessage: message, inConversation: conversation)
        XCTAssertEqual(conversation.messages.count, 1)

        // A deletion should not update the lastModified date
        XCTAssertEqual(conversation.lastModifiedDate, lastModified)
        
        guard let systemMessage = conversation.messages.lastObject as? ZMSystemMessage , systemMessage.systemMessageType == .messageDeletedForEveryone else {
            return XCTFail()
        }
        
        XCTAssertEqual(systemMessage.serverTimestamp, timestamp)
        XCTAssertEqual(systemMessage.sender, otherUser)
    }
    
    
    func testThatItDoesNotInsertAMessageWithTheSameNonceOfAMessageThatHasAlreadyBeenDeleted() {
        // given
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        guard let sut = conversation.appendMessage(withText: name!) as? ZMMessage else { return XCTFail() }
        let lastModified = Date(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified
        let nonce = sut.nonce!
        
        // when
        let updateEvent = createMessageDeletedUpdateEvent(nonce, conversationID: conversation.remoteIdentifier!, senderID: sut.sender!.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.messageUpdateResult(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        assertDeletedContent(ofMessage: sut as! ZMOTRMessage, inConversation: conversation)

        //when
        let genericMessage = ZMGenericMessage.message(text: name!, nonce: nonce.transportString())
        let nextEvent = createUpdateEvent(nonce, conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.messageUpdateResult(from: nextEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        assertDeletedContent(ofMessage: sut as! ZMOTRMessage, inConversation: conversation)

        // No system message as the selfUser was the sender
        XCTAssertEqual(conversation.messages.count, 0)
        // A deletion should not update the lastModified date
        XCTAssertEqual(conversation.lastModifiedDate, lastModified)
    }

}

// MARK: - Helper

extension ZMClientMessageTests_Deletion {

    func createMessageDeletedUpdateEvent(_ nonce: UUID, conversationID: UUID, senderID: UUID = .create()) -> ZMUpdateEvent {
        let genericMessage = ZMGenericMessage(deleteMessage: nonce.transportString(), nonce: UUID.create().transportString())
        return createUpdateEvent(nonce, conversationID: conversationID, genericMessage: genericMessage, senderID: senderID)
    }
    
    func assertDeletedContent(ofMessage message: ZMOTRMessage, inConversation conversation: ZMConversation, fileName: String? = nil, line: UInt = #line) {
        XCTAssertTrue(message.hasBeenDeleted, line: line)
        XCTAssertNil(message.visibleInConversation, line: line)
        XCTAssertEqual(message.hiddenInConversation, conversation, line: line)
        XCTAssertEqual(message.dataSet.count, 0, line: line)
        XCTAssertNil(message.textMessageData, line: line)
        XCTAssertNil(message.sender, line: line)
        XCTAssertNil(message.senderClientID, line: line)
        
        if let assetMessage = message as? ZMAssetClientMessage {
            XCTAssertNil(assetMessage.mimeType, line: line)
            XCTAssertNil(assetMessage.assetId, line: line)
            XCTAssertNil(assetMessage.associatedTaskIdentifier, line: line)
            XCTAssertNil(assetMessage.fileMessageData, line: line)
            XCTAssertNil(assetMessage.filename, line: line)
            XCTAssertNil(assetMessage.imageMessageData, line: line)
            XCTAssertNil(assetMessage.genericAssetMessage, line: line)
            XCTAssertEqual(assetMessage.size, 0, line: line)

            let cache = uiMOC.zm_imageAssetCache!
            XCTAssertNil(cache.assetData(message.nonce, format: .original, encrypted: false))
            XCTAssertNil(cache.assetData(message.nonce, format: .medium, encrypted: false))
            XCTAssertNil(cache.assetData(message.nonce, format: .preview, encrypted: false))
            XCTAssertNil(cache.assetData(message.nonce, format: .medium, encrypted: true))
            XCTAssertNil(cache.assetData(message.nonce, format: .preview, encrypted: true))

            guard let fileName = fileName else { return }
            let fileCache = uiMOC.zm_fileAssetCache
            XCTAssertNil(fileCache.assetData(message.nonce, fileName: fileName, encrypted: true))
            XCTAssertNil(fileCache.assetData(message.nonce, fileName: fileName, encrypted: false))
            
        } else if let clientMessage = message as? ZMClientMessage {
            XCTAssertNil(clientMessage.genericMessage, line: line)
        }
    }

}

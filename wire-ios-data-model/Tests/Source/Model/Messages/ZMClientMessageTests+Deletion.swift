//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
@testable import WireDataModel

// MARK: - Sending

class ZMClientMessageTests_Deletion: BaseZMClientMessageTests {
    func testThatItDeletesAMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        guard let sut = try? conversation.appendText(content: name) as? ZMMessage else { return XCTFail() }

        // when
        performPretendingUiMocIsSyncMoc {
            let delete = sut.deleteForEveryone()
            delete?.update(withPostPayload: [:], updatedKeys: Set())
        }

        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        assertDeletedContent(ofMessage: sut as! ZMOTRMessage, inConversation: conversation)
    }

    func testThatItSetsTheCategoryToUndefined() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        guard let sut = try? conversation.appendText(content: name) as? ZMMessage else { return XCTFail() }
        XCTAssertEqual(sut.cachedCategory, .text)

        // when
        performPretendingUiMocIsSyncMoc {
            let delete = sut.deleteForEveryone()
            delete?.update(withPostPayload: [:], updatedKeys: Set())
        }

        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.cachedCategory, .undefined)
    }

    func testThatItDeletesAnAssetMessage_Image() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let sut = try! conversation.appendImage(from: mediumJPEGData(), nonce: .create()) as! ZMAssetClientMessage

        let cache = uiMOC.zm_fileAssetCache!
        cache.storePreviewImage(data: verySmallJPEGData(), for: sut)
        cache.storeMediumImage(data: mediumJPEGData(), for: sut)
        cache.storeOriginalImage(data: mediumJPEGData(), for: sut)
        cache.storeEncryptedPreviewImage(data: verySmallJPEGData(), for: sut)
        cache.storeEncryptedMediumImage(data: mediumJPEGData(), for: sut)

        // expect
        let assetId = "asset-id"
        let asset = WireProtos.Asset(withUploadedOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key())
        var message = GenericMessage(content: asset, nonce: sut.nonce!)
        message.updateUploaded(assetId: assetId, token: nil, domain: nil)
        let updateEvent = createUpdateEvent(sut.nonce!, conversationID: UUID.create(), genericMessage: message)

        sut.update(with: updateEvent, initialUpdate: true)
        let observer = AssetDeletionNotificationObserver()

        // when
        performPretendingUiMocIsSyncMoc {
            let delete = sut.deleteForEveryone()
            delete?.update(withPostPayload: [:], updatedKeys: Set())
        }

        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        assertDeletedContent(ofMessage: sut, inConversation: conversation)
        XCTAssertEqual(observer.deletedIdentifiers, [assetId])
        wipeCaches()
    }

    func testThatItDeletesAnAssetMessage_File() {
        // given
        let data = Data("Hello World".utf8)
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let url = URL(fileURLWithPath: documents).appendingPathComponent("file.dat")

        defer { try! FileManager.default.removeItem(at: url) }

        try? data.write(to: url, options: [.atomic])
        let fileMetaData = ZMFileMetadata(fileURL: url, thumbnail: verySmallJPEGData())
        let sut = try! conversation.appendFile(with: fileMetaData, nonce: .create())  as! ZMAssetClientMessage

        let cache = uiMOC.zm_fileAssetCache!
        cache.storeEncryptedMediumImage(data: mediumJPEGData(), for: sut)
        XCTAssertTrue(cache.hasEncryptedMediumImageData(for: sut))

        // expect
        let assetId = UUID.create().transportString()
        let asset1 = WireProtos.Asset(withUploadedOTRKey: .zmRandomSHA256Key(), sha256: .zmRandomSHA256Key())
        var message = GenericMessage(content: asset1, nonce: sut.nonce!)
        message.updateUploaded(assetId: assetId, token: nil, domain: nil)
        let updateEvent1 = createUpdateEvent(sut.nonce!, conversationID: UUID.create(), genericMessage: message)
        sut.update(with: updateEvent1, initialUpdate: true)

        let previewAssetId = UUID.create().transportString()
        let remote = WireProtos.Asset.RemoteData(
            withOTRKey: .zmRandomSHA256Key(),
            sha256: .zmRandomSHA256Key(),
            assetId: previewAssetId,
            assetToken: nil
        )
        let image = WireProtos.Asset.ImageMetaData(width: 1024, height: 1024)
        let preview = WireProtos.Asset.Preview(
            size: 256,
            mimeType: "image/png",
            remoteData: remote,
            imageMetadata: image
        )
        let asset2 = WireProtos.Asset(original: nil, preview: preview)
        let genericMessage = GenericMessage(content: asset2, nonce: sut.nonce!)
        let updateEvent2 = createUpdateEvent(sut.nonce!, conversationID: UUID.create(), genericMessage: genericMessage)
        sut.update(with: updateEvent2, initialUpdate: true)

        let observer = AssetDeletionNotificationObserver()

        // when
        performPretendingUiMocIsSyncMoc {
            let delete = sut.deleteForEveryone()
            delete?.update(withPostPayload: [:], updatedKeys: Set())
        }

        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        assertDeletedContent(ofMessage: sut, inConversation: conversation, fileName: "file.dat")
        XCTAssertEqual(observer.deletedIdentifiers.count, 2)
        XCTAssert(observer.deletedIdentifiers.contains(assetId))
        XCTAssert(observer.deletedIdentifiers.contains(previewAssetId))
        wipeCaches()
    }

    func testThatItDeletesAPreEndtoEndPlainTextMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let sut = TextMessage(nonce: .create(), managedObjectContext: uiMOC) // Pre e2ee plain text message

        sut.visibleInConversation = conversation
        sut.sender = selfUser

        // when
        performPretendingUiMocIsSyncMoc {
            let delete = sut.deleteForEveryone()
            delete?.update(withPostPayload: [:], updatedKeys: Set())
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
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let sut = ZMKnockMessage(nonce: .create(), managedObjectContext: uiMOC) // Pre e2ee knock message

        sut.visibleInConversation = conversation
        sut.sender = selfUser

        // when
        performPretendingUiMocIsSyncMoc {
            let delete = sut.deleteForEveryone()
            delete?.update(withPostPayload: [:], updatedKeys: Set())
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
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let sut = ZMImageMessage(nonce: .create(), managedObjectContext: uiMOC) // Pre e2ee image message

        sut.visibleInConversation = conversation
        sut.sender = selfUser

        let cache = uiMOC.zm_fileAssetCache!
        cache.storePreviewImage(data: verySmallJPEGData(), for: sut)
        cache.storeMediumImage(data: mediumJPEGData(), for: sut)
        cache.storeOriginalImage(data: mediumJPEGData(), for: sut)

        // when
        performPretendingUiMocIsSyncMoc {
            let delete = sut.deleteForEveryone()
            delete?.update(withPostPayload: [:], updatedKeys: Set())
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

        XCTAssertNil(cache.originalImageData(for: sut))
        XCTAssertNil(cache.mediumImageData(for: sut))
        XCTAssertNil(cache.previewImageData(for: sut))
        wipeCaches()
    }

    func testThatAMessageSentByAnotherUserCanotBeDeleted() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        guard let sut = try? conversation.appendText(content: name) as? ZMMessage else { return XCTFail() }
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

    func testThatTheInsertedDeleteMessageDoesNotHaveAnExpirationDate() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let nonce = UUID.create()
        let deletedMessage = GenericMessage(content: MessageDelete(messageId: nonce))

        // when
        let sut = try conversation.appendClientMessage(with: deletedMessage, expires: false, hidden: true)

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
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastModifiedDate = Date(timeIntervalSince1970: 123_456_789)
        conversation.remoteIdentifier = .create()

        // when
        let updateEvent = createMessageDeletedUpdateEvent(
            .create(),
            conversationID: conversation.remoteIdentifier!,
            senderID: selfUser.remoteIdentifier!
        )
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(conversation.allMessages.count, 0)
    }

    func testThatItDoesNotInsertASystemMessageWhenAMessageIsDeletedForEveryoneLocally() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        guard let sut = try? conversation.appendText(content: name) else { return XCTFail() }

        // when
        performPretendingUiMocIsSyncMoc {
            ZMMessage.deleteForEveryone(sut)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation.allMessages.count, 0)
    }
}

// MARK: - Receiving

extension ZMClientMessageTests_Deletion {
    func testThatAMessageCanNotBeDeletedByAUserThatDidNotInitiallySentIt() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastModifiedDate = Date(timeIntervalSince1970: 123_456_789)
        conversation.remoteIdentifier = .create()
        guard let sut = try? conversation.appendText(content: name) as? ZMMessage else { return XCTFail() }

        // when
        let updateEvent = createMessageDeletedUpdateEvent(sut.nonce!, conversationID: conversation.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        if let systemMessage = conversation.lastMessage as? ZMSystemMessage,
           systemMessage.systemMessageType == .messageDeletedForEveryone {
            return XCTFail()
        }
    }

    func testThatAMessageCanBeDeletedByTheUserThatDidInitiallySentIt() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        guard let sut = try? conversation.appendText(content: name) as? ZMMessage else { return XCTFail() }
        let lastModified = Date(timeIntervalSince1970: 1_234_567_890)
        conversation.lastModifiedDate = lastModified

        // when
        let updateEvent = createMessageDeletedUpdateEvent(
            sut.nonce!,
            conversationID: conversation.remoteIdentifier!,
            senderID: sut.sender!.remoteIdentifier!
        )

        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        assertDeletedContent(ofMessage: sut as! ZMOTRMessage, inConversation: conversation)
        // No system message as the selfUser was the sender
        XCTAssertEqual(conversation.allMessages.count, 0)
        // A deletion should not update the lastModified date
        XCTAssertEqual(conversation.lastModifiedDate, lastModified)
    }

    func testThatTheMessageCategoryIsSetToUndefinedWhenReceiveingADeleteEvent() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        guard let sut = try? conversation.appendText(content: name) as? ZMMessage else { return XCTFail() }
        let lastModified = Date(timeIntervalSince1970: 1_234_567_890)
        conversation.lastModifiedDate = lastModified
        XCTAssertEqual(sut.cachedCategory, .text)

        // when
        let updateEvent = createMessageDeletedUpdateEvent(
            sut.nonce!,
            conversationID: conversation.remoteIdentifier!,
            senderID: sut.sender!.remoteIdentifier!
        )

        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(sut.cachedCategory, .undefined)
    }

    func testThatAMessageSentByAnotherUserCanBeDeletedAndASystemMessageIsInserted() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = .create()
        let message = ZMClientMessage(nonce: .create(), managedObjectContext: uiMOC)
        message.sender = otherUser
        message.visibleInConversation = conversation
        let timestamp = Date(timeIntervalSince1970: 123_456_789)
        message.serverTimestamp = timestamp

        let lastModified = Date(timeIntervalSince1970: 1_234_567_890)
        conversation.lastModifiedDate = lastModified

        // when
        let updateEvent = createMessageDeletedUpdateEvent(
            message.nonce!,
            conversationID: conversation.remoteIdentifier!,
            senderID: otherUser.remoteIdentifier!
        )

        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        assertDeletedContent(ofMessage: message, inConversation: conversation)

        // A deletion should not update the lastModified date
        XCTAssertEqual(conversation.lastModifiedDate, lastModified)

        guard let systemMessage = conversation.lastMessage as? ZMSystemMessage,
              systemMessage.systemMessageType == .messageDeletedForEveryone else {
            return XCTFail()
        }

        XCTAssertEqual(systemMessage.serverTimestamp, timestamp)
        XCTAssertEqual(systemMessage.sender, otherUser)
    }

    func testThatItDoesNotInsertAMessageWithTheSameNonceOfAMessageThatHasAlreadyBeenDeleted() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        guard let sut = try? conversation.appendText(content: name) as? ZMMessage else { return XCTFail() }
        let lastModified = Date(timeIntervalSince1970: 1_234_567_890)
        conversation.lastModifiedDate = lastModified
        let nonce = sut.nonce!

        // when
        let updateEvent = createMessageDeletedUpdateEvent(
            nonce,
            conversationID: conversation.remoteIdentifier!,
            senderID: sut.sender!.remoteIdentifier!
        )
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        assertDeletedContent(ofMessage: sut as! ZMOTRMessage, inConversation: conversation)

        // when
        let genericMessage = GenericMessage(content: Text(content: name), nonce: nonce)
        let nextEvent = createUpdateEvent(
            nonce,
            conversationID: conversation.remoteIdentifier!,
            genericMessage: genericMessage
        )
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdate(from: nextEvent, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        assertDeletedContent(ofMessage: sut as! ZMOTRMessage, inConversation: conversation)

        // No system message as the selfUser was the sender
        XCTAssertEqual(conversation.allMessages.count, 0)
        // A deletion should not update the lastModified date
        XCTAssertEqual(conversation.lastModifiedDate, lastModified)
    }
}

// MARK: - Ephemeral

extension ZMClientMessageTests_Deletion {
    func testThatItStopsDeletionTimerForEphemeralMessages() {
        // given
        conversation.setMessageDestructionTimeoutValue(.custom(1000), for: .selfUser)
        let sut = try! conversation.appendText(content: "foo") as! ZMClientMessage
        sut.sender = user1
        _ = uiMOC.zm_messageDeletionTimer?.startDeletionTimer(message: sut, timeout: 1000)
        XCTAssertEqual(uiMOC.zm_messageDeletionTimer?.isTimerRunning(for: sut), true)
        XCTAssertTrue(sut.isEphemeral)
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        syncMOC.performGroupedAndWait {
            self.syncMOC.refresh(self.syncConversation, mergeChanges: false)
            let updateEvent = self.createMessageDeletedUpdateEvent(
                sut.nonce!,
                conversationID: self.conversation.remoteIdentifier!,
                senderID: self.user2.remoteIdentifier!
            )
            ZMOTRMessage.createOrUpdate(from: updateEvent, in: self.syncMOC, prefetchResult: nil)
            XCTAssertTrue(self.syncMOC.saveOrRollback())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(uiMOC.zm_messageDeletionTimer?.isTimerRunning(for: sut), false)

        // teardown
        uiMOC.zm_teardownMessageDeletionTimer()
    }

    func testThatIfSenderDeletesGroupEphemeralThenAllUsersAreRecipientsOfDeleteMessage() {
        syncMOC.performGroupedAndWait {
            // given
            self.syncConversation.conversationType = .group
            self.syncConversation.setMessageDestructionTimeoutValue(.custom(1000), for: .selfUser)

            // self sends ephemeral
            let sut = try! self.syncConversation.appendText(content: "foo") as! ZMClientMessage
            sut.sender = self.syncSelfUser
            XCTAssertTrue(sut.startDestructionIfNeeded())
            XCTAssertNotNil(sut.destructionDate)

            // when self deletes the ephemeral
            let messageDelete = MessageDelete.with {
                $0.messageID = sut.nonce!.transportString()
            }
            let deletedMessage = GenericMessage(content: messageDelete)
            let recipients = deletedMessage.recipientUsersForMessage(
                in: self.syncConversation,
                selfUser: self.syncSelfUser
            ).users

            // then all users receive delete message
            XCTAssertEqual(4, recipients.count)
            XCTAssertTrue(recipients.contains(self.syncSelfUser))
            XCTAssertTrue(recipients.contains(self.syncUser1))
            XCTAssertTrue(recipients.contains(self.syncUser2))
            XCTAssertTrue(recipients.contains(self.syncUser3))
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatIfUserDeletesGroupEphemeralThenSelfAndSenderAreRecipientsOfDeleteMessage() {
        // given
        conversation.conversationType = .group
        conversation.setMessageDestructionTimeoutValue(.custom(1000), for: .selfUser)

        // ephemeral received
        let sut = try! conversation.appendText(content: "foo") as! ZMClientMessage
        sut.sender = user1
        XCTAssertTrue(sut.startDestructionIfNeeded())
        XCTAssertNotNil(sut.destructionDate)

        // when self deletes the ephemeral
        let messageDelete = MessageDelete.with {
            $0.messageID = sut.nonce!.transportString()
        }
        let deletedMessage = GenericMessage(content: messageDelete)
        let recipients = deletedMessage.recipientUsersForMessage(in: conversation, selfUser: selfUser).users

        // then only sender & self recieve the delete message
        XCTAssertEqual(2, recipients.count)
        XCTAssertTrue(recipients.contains(selfUser))
        XCTAssertTrue(recipients.contains(user1))
    }
}

// MARK: - Helper

extension ZMClientMessageTests_Deletion {
    func createMessageDeletedUpdateEvent(
        _ nonce: UUID,
        conversationID: UUID,
        senderID: UUID = .create()
    ) -> ZMUpdateEvent {
        let genericMessage = GenericMessage(content: MessageDelete(messageId: nonce))
        return createUpdateEvent(
            nonce,
            conversationID: conversationID,
            genericMessage: genericMessage,
            senderID: senderID
        )
    }

    func assertDeletedContent(
        ofMessage message: ZMOTRMessage,
        inConversation conversation: ZMConversation,
        fileName: String? = nil,
        line: UInt = #line
    ) {
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
            XCTAssertNil(assetMessage.underlyingMessage, line: line)
            XCTAssertEqual(assetMessage.size, 0, line: line)

            let cache = uiMOC.zm_fileAssetCache!
            XCTAssertNil(cache.originalImageData(for: message))
            XCTAssertNil(cache.mediumImageData(for: message))
            XCTAssertNil(cache.previewImageData(for: message))
            XCTAssertNil(cache.encryptedMediumImageData(for: message))
            XCTAssertNil(cache.encryptedPreviewImageData(for: message))

            XCTAssertNil(cache.encryptedFileData(for: message))
            XCTAssertNil(cache.originalFileData(for: message))

        } else if let clientMessage = message as? ZMClientMessage {
            XCTAssertNil(clientMessage.underlyingMessage, line: line)
        }
    }
}

private final class AssetDeletionNotificationObserver: NSObject {
    private(set) var deletedIdentifiers = [String]()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handle),
            name: Notification.Name.deleteAssetNotification,
            object: nil
        )
    }

    @objc
    private func handle(note: Notification) {
        guard let identifier = note.object as? String else { return }
        deletedIdentifiers.append(identifier)
    }
}

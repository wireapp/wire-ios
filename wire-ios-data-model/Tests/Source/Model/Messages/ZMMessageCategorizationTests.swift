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

import WireLinkPreview
import WireUtilities
import XCTest
@testable import WireDataModel

extension ZMConversationMessage {
    fileprivate var categorization: MessageCategory {
        guard let message = self as? ZMMessage else {
            return .none
        }
        return message.category
    }
}

class ZMMessageCategorizationTests: ZMBaseManagedObjectTest {
    var conversation: ZMConversation!

    override func setUp() {
        super.setUp()
        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.remoteIdentifier = UUID.create()

        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID()

        uiMOC.saveOrRollback()
    }

    override func tearDown() {
        conversation = nil
        super.tearDown()
    }

    func testThatItCategorizesATextMessage() {
        // GIVEN
        let message = try! conversation.appendText(content: "ramble on!")

        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.text)
    }

    func testThatItCategorizeTimedMessages() {
        // GIVEN
        let otherUser = ZMUser.insertNewObject(in: conversation.managedObjectContext!)
        otherUser.remoteIdentifier = UUID.create()

        conversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)
        conversation.setMessageDestructionTimeoutValue(.fiveMinutes, for: .selfUser)
        let message = try! conversation.appendText(content: "ramble on!") as! ZMMessage

        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.text)
    }

    func testThatItCategorizesATextMessageWithLink() {
        // GIVEN
        let message = try! conversation
            .appendText(content: "ramble on https://en.wikipedia.org/wiki/Ramble_On here")

        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.text, MessageCategory.link])
    }

    func testThatItCategorizesALinkPreviewMessage() throws {
        // GIVEN
        let article = ArticleMetadata(
            originalURLString: "www.example.com/article/original",
            permanentURLString: "http://www.example.com/article/1",
            resolvedURLString: "http://www.example.com/article/1",
            offset: 12
        )
        article.title = "title"
        article.summary = "summary"
        let genericMessage = GenericMessage(
            content: Text(content: "foo", mentions: [], linkPreviews: [article], replyingTo: nil),
            nonce: UUID.create()
        )
        let message = try conversation.appendClientMessage(with: genericMessage)
        message.linkPreviewState = .processed

        // THEN
        XCTAssertEqual(
            message.categorization,
            [MessageCategory.text, MessageCategory.link, MessageCategory.linkPreview]
        )
    }

    func testThatItCategorizesAnImageMessage() {
        // GIVEN
        let message = try! conversation.appendImage(from: verySmallJPEGData())

        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.image)
    }

    func testThatItCategorizesAnImageMessage_WithoutData() {
        // GIVEN
        let message = try! conversation.appendImage(from: verySmallJPEGData())
        uiMOC.zm_fileAssetCache.deleteOriginalImageData(for: message)

        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.image, MessageCategory.excludedFromCollection])
    }

    func testThatItCategorizesAGifImageMessage() {
        // GIVEN
        let data = data(forResource: "animated", extension: "gif")!
        let message = try! conversation.appendImage(from: data) as! ZMAssetClientMessage

        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.image, MessageCategory.GIF])
    }

    func testThatItCategorizesKnocks() throws {
        // GIVEN
        let message = try conversation.appendKnock() as! ZMClientMessage

        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.knock)
    }

    func testThatItCategorizesFile() {
        // GIVEN
        let message = try! conversation.appendFile(with: ZMFileMetadata(fileURL: fileURL(
            forResource: "Lorem Ipsum",
            extension: "txt"
        )))

        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.file)
    }

    func testThatItDoesCategorizeAFailedToUploadFile_ExcludedFromCollection() {
        // GIVEN
        let message = try! conversation.appendFile(with: ZMFileMetadata(fileURL: fileURL(
            forResource: "Lorem Ipsum",
            extension: "txt"
        ))) as! ZMAssetClientMessage
        message.transferState = .uploadingFailed
        message.updateCategoryCache()

        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.file, MessageCategory.excludedFromCollection])
    }

    func testThatItDoesNotCategorizeACancelledToUploadFile_ExcludedFromCollection() {
        // GIVEN
        let message = try! conversation.appendFile(with: ZMFileMetadata(fileURL: fileURL(
            forResource: "Lorem Ipsum",
            extension: "txt"
        ))) as! ZMAssetClientMessage
        message.transferState = .uploadingCancelled
        message.updateCategoryCache()

        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.file, MessageCategory.excludedFromCollection])
    }

    func testThatItCategorizesAudioFile() {
        // GIVEN
        let message = try! conversation.appendFile(with: ZMAudioMetadata(
            fileURL: fileURL(forResource: "audio", extension: "m4a"),
            duration: 12.2
        ))

        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.file, MessageCategory.audio])
    }

    func testThatItCategorizesVideoFile() {
        // GIVEN
        let message = try! conversation.appendFile(with: ZMVideoMetadata(
            fileURL: fileURL(forResource: "video", extension: "mp4"),
            thumbnail: verySmallJPEGData()
        ))

        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.file, MessageCategory.video])
    }

    func testThatItCategorizesLocation() throws {
        // GIVEN
        let message = try conversation.appendLocation(with: LocationData.locationData(
            withLatitude: 40.42,
            longitude: 50.2,
            name: "Fooland",
            zoomLevel: Int32(2)
        ))

        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.location)
    }

    func testThatItCategorizesV3Images() {
        // GIVEN
        let message = try! conversation.appendImage(from: verySmallJPEGData())

        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.image)
    }

    func testThatItCategorizesSystemMessage() {
        // GIVEN
        let message = ZMSystemMessage(nonce: UUID(), managedObjectContext: conversation.managedObjectContext!)
        message.systemMessageType = .conversationNameChanged

        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.systemMessage)
    }

    func testThatItCategorizesLikedTextMessageWhenLikedBySelfUser() {
        // GIVEN
        let message = try! conversation.appendText(content: "ramble on!") as! ZMClientMessage
        message.delivered = true
        ZMMessage.addReaction("❤️", to: message)
        XCTAssertFalse(message.usersReaction.isEmpty)
        conversation.managedObjectContext?.saveOrRollback()

        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.text, MessageCategory.reacted])
    }

    func testThatItCategorizesLikedFileMessageWhenLikedBySelfUser() {
        // GIVEN
        let message = try! conversation.appendFile(with: ZMFileMetadata(fileURL: fileURL(
            forResource: "Lorem Ipsum",
            extension: "txt"
        ))) as! ZMAssetClientMessage
        message.delivered = true
        ZMMessage.addReaction("❤️", to: message)
        XCTAssertFalse(message.usersReaction.isEmpty)
        conversation.managedObjectContext?.saveOrRollback()

        // THEN
        XCTAssertEqual(message.categorization, [MessageCategory.file, MessageCategory.reacted])
    }

    func testThatItCategorizesLikedTextMessageWhenNotLikedBySelfUser() {
        // GIVEN
        let otherUser = ZMUser.insertNewObject(in: conversation.managedObjectContext!)
        otherUser.remoteIdentifier = UUID.create()
        let message = try! conversation.appendText(content: "ramble on!") as! ZMClientMessage
        message.delivered = true
        message.setReactions(["❤️"], forUser: otherUser)
        XCTAssertFalse(message.usersReaction.isEmpty)
        conversation.managedObjectContext?.saveOrRollback()

        // THEN
        XCTAssertEqual(message.categorization, MessageCategory.text)
    }
}

// MARK: - Cache

extension ZMMessageCategorizationTests {
    func testThatItComputesTheCachedCategoryLazily() {
        // GIVEN
        let message = try! conversation.appendText(content: "ramble on!") as! ZMMessage
        message.setPrimitiveValue(NSNumber(value: 0), forKey: ZMMessageCachedCategoryKey)
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: 0))

        // WHEN
        let category = message.cachedCategory

        // THEN
        XCTAssertEqual(category, MessageCategory.text)
        XCTAssertEqual(
            message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber,
            NSNumber(value: MessageCategory.text.rawValue)
        )
    }

    func testThatItUsedCachedCategoryValueIfPresent() {
        // GIVEN
        let message = try! conversation.appendText(content: "ramble on!") as! ZMMessage
        message.willChangeValue(forKey: ZMMessageCachedCategoryKey)
        message.setPrimitiveValue(NSNumber(value: MessageCategory.audio.rawValue), forKey: ZMMessageCachedCategoryKey)
        message.didChangeValue(forKey: ZMMessageCachedCategoryKey)

        // WHEN
        let category = message.cachedCategory

        // THEN
        XCTAssertEqual(category, MessageCategory.audio)
        XCTAssertEqual(
            message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber,
            NSNumber(value: MessageCategory.audio.rawValue)
        )
    }

    func testThatItComputestheCachedCategoryWhenAsked() {
        // GIVEN
        let message = try! conversation.appendText(content: "ramble on!") as! ZMMessage
        message.setPrimitiveValue(NSNumber(value: 0), forKey: ZMMessageCachedCategoryKey)
        XCTAssertEqual(message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber, NSNumber(value: 0))

        // WHEN
        message.updateCategoryCache()

        // THEN
        message.willAccessValue(forKey: ZMMessageCachedCategoryKey)
        let category = message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber
        message.didAccessValue(forKey: ZMMessageCachedCategoryKey)

        XCTAssertEqual(category?.int32Value, MessageCategory.text.rawValue)
    }
}

// MARK: - Fetch request

extension ZMMessageCategorizationTests {
    func testThatItCreatesAFetchRequestToFetchText() {
        // GIVEN
        let textMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        textMessage.cachedCategory = MessageCategory.text
        textMessage.serverTimestamp = Date(timeIntervalSince1970: 100)
        let knockMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        knockMessage.cachedCategory = MessageCategory.knock
        knockMessage.serverTimestamp = Date(timeIntervalSince1970: 2000)
        let linkTextMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        linkTextMessage.cachedCategory = [MessageCategory.link, MessageCategory.text]
        linkTextMessage.serverTimestamp = Date(timeIntervalSince1970: 3000)
        let likedTextMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        likedTextMessage.cachedCategory = [MessageCategory.reacted, MessageCategory.text]
        likedTextMessage.serverTimestamp = Date(timeIntervalSince1970: 5000)
        conversation.managedObjectContext?.saveOrRollback()

        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(categories: [MessageCategory.text])
        let results = try? conversation.managedObjectContext!.fetch(fetchRequest)

        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertTrue(messages.contains(textMessage))
        XCTAssertFalse(messages.contains(knockMessage))
        XCTAssertTrue(messages.contains(linkTextMessage))
        XCTAssertTrue(messages.contains(likedTextMessage))
    }

    func testThatItCreatesAFetchRequestToFetchTextOrKnock() {
        // GIVEN
        let textMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        textMessage.cachedCategory = MessageCategory.text
        textMessage.serverTimestamp = Date(timeIntervalSince1970: 100)
        let knockMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        knockMessage.cachedCategory = MessageCategory.knock
        knockMessage.serverTimestamp = Date(timeIntervalSince1970: 2000)
        let linkTextMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        linkTextMessage.cachedCategory = [MessageCategory.link, MessageCategory.text]
        linkTextMessage.serverTimestamp = Date(timeIntervalSince1970: 3000)
        let likedTextMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        likedTextMessage.cachedCategory = [MessageCategory.reacted, MessageCategory.text]
        likedTextMessage.serverTimestamp = Date(timeIntervalSince1970: 5000)
        conversation.managedObjectContext?.saveOrRollback()

        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(categories: [MessageCategory.text, MessageCategory.knock])
        let results = try? conversation.managedObjectContext!.fetch(fetchRequest)

        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertTrue(messages.contains(textMessage))
        XCTAssertTrue(messages.contains(knockMessage))
        XCTAssertTrue(messages.contains(linkTextMessage))
        XCTAssertTrue(messages.contains(likedTextMessage))
    }

    func testThatItCreatesAFetchRequestToFetchLikedText() {
        // GIVEN
        let textMessage = try! conversation.appendText(content: "в ночной тиши") as! ZMMessage
        textMessage.cachedCategory = MessageCategory.text
        textMessage.serverTimestamp = Date(timeIntervalSince1970: 100)
        let knockMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        knockMessage.cachedCategory = MessageCategory.knock
        knockMessage.serverTimestamp = Date(timeIntervalSince1970: 2000)
        let linkTextMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        linkTextMessage.cachedCategory = [MessageCategory.link, MessageCategory.text]
        linkTextMessage.serverTimestamp = Date(timeIntervalSince1970: 3000)
        let likedTextMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        likedTextMessage.cachedCategory = [MessageCategory.reacted, MessageCategory.text]
        likedTextMessage.serverTimestamp = Date(timeIntervalSince1970: 5000)
        conversation.managedObjectContext?.saveOrRollback()

        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(categories: [[MessageCategory.text, MessageCategory.reacted]])
        let results = try? conversation.managedObjectContext!.fetch(fetchRequest)

        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertFalse(messages.contains(textMessage))
        XCTAssertFalse(messages.contains(knockMessage))
        XCTAssertFalse(messages.contains(linkTextMessage))
        XCTAssertTrue(messages.contains(likedTextMessage))
    }

    func testThatItCreatesAFetchRequestToFetchLikedTextOrKnock() {
        // GIVEN
        let textMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        textMessage.cachedCategory = MessageCategory.text
        textMessage.serverTimestamp = Date(timeIntervalSince1970: 100)
        let knockMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        knockMessage.cachedCategory = MessageCategory.knock
        knockMessage.serverTimestamp = Date(timeIntervalSince1970: 2000)
        let linkTextMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        linkTextMessage.cachedCategory = [MessageCategory.link, MessageCategory.text]
        linkTextMessage.serverTimestamp = Date(timeIntervalSince1970: 3000)
        let likedTextMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        likedTextMessage.cachedCategory = [MessageCategory.reacted, MessageCategory.text]
        likedTextMessage.serverTimestamp = Date(timeIntervalSince1970: 5000)
        conversation.managedObjectContext?.saveOrRollback()

        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(categories: [
            [MessageCategory.text, MessageCategory.reacted],
            MessageCategory.knock,
        ])
        let results = try? conversation.managedObjectContext!.fetch(fetchRequest)

        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertFalse(messages.contains(textMessage))
        XCTAssertTrue(messages.contains(knockMessage))
        XCTAssertFalse(messages.contains(linkTextMessage))
        XCTAssertTrue(messages.contains(likedTextMessage))
    }

    func testThatItCreatesAFetchRequestToFetchTextExcludingLinksAndLiked() {
        // GIVEN
        let textMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        textMessage.cachedCategory = MessageCategory.text
        textMessage.serverTimestamp = Date(timeIntervalSince1970: 100)
        let knockMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        knockMessage.cachedCategory = MessageCategory.knock
        knockMessage.serverTimestamp = Date(timeIntervalSince1970: 2000)
        let linkTextMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        linkTextMessage.cachedCategory = [MessageCategory.link, MessageCategory.text]
        linkTextMessage.serverTimestamp = Date(timeIntervalSince1970: 3000)
        let likedTextMessage = try! conversation.appendText(content: "in the still of the night") as! ZMMessage
        likedTextMessage.cachedCategory = [MessageCategory.reacted, MessageCategory.text]
        likedTextMessage.serverTimestamp = Date(timeIntervalSince1970: 5000)
        conversation.managedObjectContext?.saveOrRollback()

        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(
            categories: [MessageCategory.text],
            excluding: [MessageCategory.link, MessageCategory.reacted]
        )
        let results = try? conversation.managedObjectContext!.fetch(fetchRequest)

        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertTrue(messages.contains(textMessage))
        XCTAssertFalse(messages.contains(knockMessage))
        XCTAssertFalse(messages.contains(linkTextMessage))
        XCTAssertFalse(messages.contains(likedTextMessage))
    }

    func testThatItFetchesFromAllConversations() {
        // GIVEN
        let otherConversation = ZMConversation.insertNewObject(in: uiMOC)
        otherConversation.conversationType = .group
        otherConversation.remoteIdentifier = UUID.create()

        let textMessage1 = try! conversation.appendText(content: "hey Jean!") as! ZMMessage
        textMessage1.cachedCategory = MessageCategory.text
        textMessage1.serverTimestamp = Date(timeIntervalSince1970: 100)

        let textMessage2 = try! otherConversation.appendText(content: "hey Jean!") as! ZMMessage
        textMessage2.cachedCategory = MessageCategory.text
        textMessage2.serverTimestamp = Date(timeIntervalSince1970: 300)

        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(categories: [MessageCategory.text])
        let results = try? conversation.managedObjectContext!.fetch(fetchRequest)

        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertTrue(messages.contains(textMessage1))
        XCTAssertTrue(messages.contains(textMessage2))
    }

    func testThatItFetchesFromASpecificConversations() {
        // GIVEN
        let otherConversation = ZMConversation.insertNewObject(in: uiMOC)
        otherConversation.conversationType = .group
        otherConversation.remoteIdentifier = UUID.create()

        let textMessage1 = try! conversation.appendText(content: "hey Jean!") as! ZMMessage
        textMessage1.cachedCategory = MessageCategory.text
        textMessage1.serverTimestamp = Date(timeIntervalSince1970: 100)

        let textMessage2 = try! otherConversation.appendText(content: "hey Jean!") as! ZMMessage
        textMessage2.cachedCategory = MessageCategory.text
        textMessage2.serverTimestamp = Date(timeIntervalSince1970: 300)

        // WHEN
        let fetchRequest = ZMMessage.fetchRequestMatching(
            categories: [MessageCategory.text],
            conversation: otherConversation
        )
        let results = try? conversation.managedObjectContext!.fetch(fetchRequest)

        // THEN
        guard let messages = results as? [ZMMessage] else {
            XCTFail("Result is \(String(describing: results))")
            return
        }
        XCTAssertFalse(messages.contains(textMessage1))
        XCTAssertTrue(messages.contains(textMessage2))
    }
}

// MARK: Categorization on insert

extension ZMMessageCategorizationTests {
    func testThatItCategorizesAClientMessageOnInsert() {
        // when
        let message = try! conversation.appendText(content: "hey Jean!") as! ZMMessage

        // then
        XCTAssertEqual(
            message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber,
            NSNumber(value: MessageCategory.text.rawValue)
        )
    }

    func testThatItCategorizesALocationMessageOnInsert() throws {
        // when
        let message = try conversation.appendLocation(with: LocationData.locationData(
            withLatitude: 40.42,
            longitude: 50.2,
            name: "Fooland",
            zoomLevel: Int32(2)
        )) as! ZMMessage

        // then
        XCTAssertEqual(
            message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber,
            NSNumber(value: MessageCategory.location.rawValue)
        )
    }

    func testThatItCategorizesAKnockMessageOnInsert() throws {
        // when
        let message = try conversation.appendKnock() as! ZMMessage
        // then
        XCTAssertEqual(
            message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber,
            NSNumber(value: MessageCategory.knock.rawValue)
        )
    }

    func testThatItCategorizesAnImageMessageOnInsert() {
        // when
        let message = try! conversation.appendImage(from: verySmallJPEGData()) as! ZMMessage

        // then
        XCTAssertEqual(
            message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber,
            NSNumber(value: MessageCategory.image.rawValue)
        )
    }

    func testThatItCategorizesAVideoMessageOnInsert() {
        // when
        let message = try! conversation.appendFile(with: ZMVideoMetadata(
            fileURL: fileURL(forResource: "video", extension: "mp4"),
            thumbnail: verySmallJPEGData()
        )) as! ZMMessage

        // then
        let category = MessageCategory.file.union(MessageCategory.video)
        XCTAssertEqual(
            message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber,
            NSNumber(value: category.rawValue)
        )
    }

    func testThatItCategorizesAnAudioFile() {
        // GIVEN
        let message = try! conversation.appendFile(with: ZMAudioMetadata(
            fileURL: fileURL(forResource: "audio", extension: "m4a"),
            duration: 12.2
        )) as! ZMMessage

        // THEN
        let category = MessageCategory.file.union(MessageCategory.audio)
        XCTAssertEqual(
            message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber,
            NSNumber(value: category.rawValue)
        )
    }

    func testThatItCategorizesAFileOnInsert() {
        // GIVEN
        let message = try! conversation.appendFile(with: ZMFileMetadata(fileURL: fileURL(
            forResource: "Lorem Ipsum",
            extension: "txt"
        ))) as! ZMMessage

        // THEN
        XCTAssertEqual(
            message.primitiveValue(forKey: ZMMessageCachedCategoryKey) as? NSNumber,
            NSNumber(value: MessageCategory.file.rawValue)
        )
    }
}

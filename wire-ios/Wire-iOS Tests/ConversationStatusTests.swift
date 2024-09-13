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

import Foundation
import XCTest
@testable import Wire

final class ConversationStatusTests: CoreDataSnapshotTestCase {
    override var needsCaches: Bool {
        true
    }

    func testThatItReturnsStatusForEmptyConversation() {
        // GIVEN
        let sut = otherUserConversation!

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertFalse(status.hasMessages)
    }

    func testThatItReturnsStatusForEmptyConversation_group() {
        // GIVEN
        let sut = createGroupConversation()

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertFalse(status.hasMessages)
    }

    func testThatItReturnsStatusForConversationWithUnreadOneMessage() {
        // GIVEN
        let sut = otherUserConversation!
        (try! sut.appendText(content: "test") as! ZMMessage).sender = otherUser
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.messagesRequiringAttention.count, 1)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text]!, 1)
    }

    func testThatItReturnsStatusForConversationWithUnreadOnePing() throws {
        // GIVEN
        let sut = otherUserConversation!
        try (sut.appendKnock() as! ZMMessage).sender = otherUser
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.messagesRequiringAttention.count, 1)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text], .none)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.knock]!, 1)
    }

    func testThatItReturnsStatusForConversationWithUnreadOneImage() {
        // GIVEN
        let sut = otherUserConversation!
        (
            try! sut
                .appendImage(
                    from: image(inTestBundleNamed: "unsplash_burger.jpg")
                        .jpegData(compressionQuality: 1.0)!
                ) as! ZMMessage
        ).sender = otherUser
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.messagesRequiringAttention.count, 1)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text], .none)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.image]!, 1)
    }

    func testThatItReturnsStatusForConversationWithUnreadManyMessages() throws {
        // GIVEN
        let sut = otherUserConversation!
        try (sut.appendKnock() as! ZMMessage).sender = otherUser
        (try! sut.appendText(content: "test") as! ZMMessage).sender = otherUser
        (
            try! sut
                .appendImage(
                    from: image(inTestBundleNamed: "unsplash_burger.jpg")
                        .jpegData(compressionQuality: 1.0)!
                ) as! ZMMessage
        ).sender = otherUser
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.messagesRequiringAttention.count, 3)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text]!, 1)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.image]!, 1)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.knock]!, 1)
    }

    func testThatItReturnsStatusForConversationWithUnreadManyTexts() {
        // GIVEN
        let sut = otherUserConversation!
        (try! sut.appendText(content: "test 1") as! ZMMessage).sender = otherUser
        (try! sut.appendText(content: "test 2") as! ZMMessage).sender = otherUser
        (try! sut.appendText(content: "test 3") as! ZMMessage).sender = otherUser
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.messagesRequiringAttention.count, 3)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text]!, 3)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.image], .none)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.knock], .none)
    }

    func testThatItReturnsStatusForConversationWithUnreadManyPings() throws {
        // GIVEN
        let sut = otherUserConversation!
        try (sut.appendKnock() as! ZMMessage).sender = otherUser
        try (sut.appendKnock() as! ZMMessage).sender = otherUser
        try (sut.appendKnock() as! ZMMessage).sender = otherUser
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.messagesRequiringAttention.count, 3)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text], .none)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.image], .none)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.knock]!, 3)
    }

    func testThatItReturnsStatusForConversationWithUnreadManyImages() {
        // GIVEN
        let sut = otherUserConversation!
        (
            try! sut
                .appendImage(
                    from: image(inTestBundleNamed: "unsplash_burger.jpg")
                        .jpegData(compressionQuality: 1.0)!
                ) as! ZMMessage
        ).sender = otherUser
        (
            try! sut
                .appendImage(
                    from: image(inTestBundleNamed: "unsplash_burger.jpg")
                        .jpegData(compressionQuality: 1.0)!
                ) as! ZMMessage
        ).sender = otherUser
        (
            try! sut
                .appendImage(
                    from: image(inTestBundleNamed: "unsplash_burger.jpg")
                        .jpegData(compressionQuality: 1.0)!
                ) as! ZMMessage
        ).sender = otherUser
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.messagesRequiringAttention.count, 3)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.text], .none)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.image]!, 3)
    }

    func testThatItReturnsStatusForBlocked() {
        // GIVEN
        let sut = otherUserConversation!
        otherUser.connection?.status = .blocked

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertFalse(status.hasMessages)
        XCTAssertTrue(status.isBlocked)
    }

    func testThatItDetectsMentions() {
        // GIVEN
        let sut = otherUserConversation!
        let selfMention = Mention(range: NSRange(location: 0, length: 5), user: selfUser)
        (try! sut.appendText(content: "@self test", mentions: [selfMention]) as! ZMMessage).sender = otherUser
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.messagesRequiringAttention.count, 1)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.mention]!, 1)
    }

    func testThatItDetectsReplies() {
        // GIVEN
        let sut = otherUserConversation!
        let selfMessage = try! sut.appendText(content: "I am a programmer") as! ZMMessage

        selfMessage.sender = selfUser
        (try! sut.appendText(content: "Yes, it is true", replyingTo: selfMessage) as! ZMMessage).sender = otherUser
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertTrue(status.hasMessages)
        XCTAssertEqual(status.messagesRequiringAttention.count, 1)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.reply]!, 1)
    }
}

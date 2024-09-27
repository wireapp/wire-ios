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

final class ConversationStatusLineTests: CoreDataSnapshotTestCase {
    override var needsCaches: Bool {
        true
    }

    override func setUp() {
        selfUserInTeam = true
        super.setUp()
    }

    func testStatusForNotActiveConversationWithHandle() {
        // GIVEN
        let sut = otherUserConversation!

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "@" + otherUser.handle!)
    }

    func testStatusForNotActiveConversationGroup() {
        // GIVEN
        let sut = createGroupConversation()

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "")
    }

    func testStatusFailedToSend() {
        // GIVEN
        let sut = otherUserConversation!
        let message = try! sut.appendText(content: "text") as! ZMMessage
        message.expire()

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "⚠️ Unsent message")
    }

    func testStatusBlocked() {
        // GIVEN
        let sut = otherUserConversation!
        otherUser.connection?.status = .blocked

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "Blocked")
    }

    func testStatusMissedCall() {
        // GIVEN
        let sut = otherUserConversation!
        appendMissedCall(to: sut)
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "Missed call")
    }

    func testStatusMissedCallInGroup() {
        // GIVEN
        let sut = createGroupConversation()
        appendMissedCall(to: sut)
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "Missed call from Bruno")
    }

    func testStatusRejectedCall() {
        // GIVEN
        let sut = otherUserConversation!
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.sender = otherUser
        otherMessage.systemMessageType = .missedCall
        otherMessage.relevantForConversationStatus = false
        sut.append(otherMessage)
        sut.lastReadServerTimeStamp = Date.distantPast

        // WHEN
        let status = sut.status.description(for: sut)
        // THEN
        XCTAssertEqual(status.string, "")
    }

    func testStatusForMultipleTextMessagesInConversation() throws {
        // GIVEN
        let sut = otherUserConversation!
        for index in 1 ... 5 {
            let message = try sut.appendText(content: "test \(index)") as? ZMClientMessage
            message?.sender = otherUser
            message?.serverTimestamp = Date(timeIntervalSince1970: Double(index))
        }
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "test 5")
    }

    func testStatusSecondReplyDoesNotSummarize() {
        // GIVEN
        let sut = otherUserConversation!

        let selfMessage = appendSelfMessage(to: sut)

        for index in 1 ... 2 {
            appendReply(
                to: sut,
                selfMessage: selfMessage,
                text: "reply test \(index)",
                timestamp: Date(timeIntervalSince1970: -Double(2 - index))
            )
        }

        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "reply test 2")
    }

    func testStatusMissedCallAndUnreadMessagesAndReplies() {
        // GIVEN
        let sut = otherUserConversation!

        let selfMessage = try! sut.appendText(content: "I am a programmer") as! ZMMessage
        selfMessage.sender = selfUser

        for index in 1 ... 3 {
            (try! sut.appendText(content: "Yes, it is true \(index)", replyingTo: selfMessage) as! ZMMessage)
                .sender = otherUser
        }
        sut.setPrimitiveValue(3, forKey: ZMConversationInternalEstimatedUnreadSelfReplyCountKey)

        appendMissedCall(to: sut)

        // insert messages from other
        for index in 1 ... 2 {
            (try! sut.appendText(content: "test \(index)") as! ZMMessage).sender = otherUser
        }

        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "3 replies, 1 missed call, 2 messages")
    }

    func testStatusForMultipleTextMessagesInConversationIncludingMention() {
        // GIVEN
        let sut = otherUserConversation!
        for index in 1 ... 5 {
            (try! sut.appendText(content: "test \(index)") as! ZMMessage).sender = otherUser
        }

        let selfMention = Mention(range: NSRange(location: 0, length: 5), user: selfUser)
        (try! sut.appendText(content: "@self test", mentions: [selfMention]) as! ZMMessage).sender = otherUser
        sut.setPrimitiveValue(1, forKey: ZMConversationInternalEstimatedUnreadSelfMentionCountKey)

        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "1 mention, 5 messages")
    }

    func disable_testStatusForMultipleTextMessagesInConversation_LastRename() {
        // GIVEN
        let sut = otherUserConversation!
        for index in 1 ... 5 {
            (try! sut.appendText(content: "test \(index)") as! ZMMessage).sender = otherUser
        }
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.sender = otherUser
        otherMessage.systemMessageType = .conversationNameChanged
        sut.append(otherMessage)

        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "test 5")
    }

    func testStatusForSystemMessageILeft() {
        // GIVEN
        let sut = createGroupConversation()
        sut.removeParticipantsAndUpdateConversationState(users: [selfUser], initiatingUser: selfUser)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "You left")
    }

    func testStatusForSystemMessageIWasAdded() {
        // GIVEN
        let sut = createGroupConversation()
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .participantsAdded
        otherMessage.sender = otherUser
        otherMessage.users = Set([selfUser])
        otherMessage.addedUsers = Set([selfUser])
        sut.append(otherMessage)

        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "\(otherUser.name ?? "") added you")
    }

    func testNoStatusForSystemMessageIAddedSomeone() {
        // GIVEN
        let sut = createGroupConversation()
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .participantsAdded
        otherMessage.sender = selfUser
        otherMessage.users = Set([otherUser])
        otherMessage.addedUsers = Set([otherUser])
        sut.append(otherMessage)

        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "")
    }

    func testNoStatusForSystemMessageIRemovedSomeone() {
        // GIVEN
        let user = createUser(name: "Vanessa")
        let sut = createGroupConversation()
        sut.addParticipantAndUpdateConversationState(user: user)
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .participantsRemoved
        otherMessage.sender = selfUser
        otherMessage.users = Set([otherUser])
        otherMessage.removedUsers = Set([otherUser])
        sut.append(otherMessage)

        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "")
    }

    func testStatusForSystemMessageIWasRemoved() {
        // GIVEN
        let sut = createGroupConversation()
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .participantsRemoved
        otherMessage.sender = otherUser
        otherMessage.users = Set([selfUser])
        otherMessage.removedUsers = Set([selfUser])
        sut.append(otherMessage)

        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "You were removed")
    }

    func testStatusForSystemMessageSomeoneWasRemoved() {
        // GIVEN
        let user = createUser(name: "Lilly")
        let sut = createGroupConversation()
        sut.addParticipantAndUpdateConversationState(user: user)

        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .participantsRemoved
        otherMessage.sender = otherUser
        otherMessage.users = Set([otherUser])
        otherMessage.removedUsers = Set([otherUser])
        sut.append(otherMessage)

        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "")
    }

    func testStatusForConversationStarted() {
        // GIVEN
        let sut = createGroupConversation()
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .newConversation
        otherMessage.sender = otherUser
        otherMessage.users = Set([otherUser, selfUser])
        otherMessage.addedUsers = Set([otherUser, selfUser])
        sut.lastServerTimeStamp = Date()
        sut.append(otherMessage)
        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "\(otherUser.name ?? "") started a conversation")
    }

    func testNoStatusForSelfConversationStarted() {
        // GIVEN
        let sut = createGroupConversation()
        let otherMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        otherMessage.systemMessageType = .newConversation
        otherMessage.sender = selfUser
        otherMessage.users = Set([otherUser, selfUser])
        otherMessage.addedUsers = Set([otherUser, selfUser])
        sut.append(otherMessage)

        // WHEN
        let status = sut.status.description(for: sut)

        // THEN
        XCTAssertEqual(status.string, "")
    }

    func testThatTypingHasHigherPrioThanMentions() {
        // GIVEN
        let sut = createGroupConversation()
        sut.managedObjectContext?.saveOrRollback()
        sut.setTypingUsers([otherUser])

        let selfMention = Mention(range: NSRange(location: 0, length: 5), user: selfUser)
        (try! sut.appendText(content: "@self test", mentions: [selfMention]) as! ZMMessage).sender = otherUser

        markAllMessagesAsUnread(in: sut)

        // WHEN
        let status = sut.status

        // THEN
        XCTAssertEqual(status.isTyping, true)
        XCTAssertEqual(status.messagesRequiringAttentionByType[.mention]!, 1)
        XCTAssertEqual(status.description(for: sut).string, "Bruno: typing a message…")
    }
}

//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireDataModel
import XCTest

@testable import Wire

final class ConversationFilterPredicateTests: XCTestCase {

    private var coreDataFixture: CoreDataFixture!
    private var selfUser: ZMUser!
    private var otherUser: ZMUser!

    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
        selfUser = coreDataFixture.selfUser
        otherUser = coreDataFixture.otherUser
    }

    override func tearDown() {
        coreDataFixture = nil
        selfUser = nil
        otherUser = nil
        super.tearDown()
    }

    // MARK: - Unread Messages Predicate Tests

    func testUnreadMessagesPredicate_WithUnreadMessages() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add unread message
            let message = try! conversation.appendText(content: "Unread message") as! ZMClientMessage
            message.serverTimestamp = Date()
            conversation.updateTimestampsAfterUpdatingMessage(message)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // WHEN
        let hasUnread = conversation.estimatedUnreadCount > 0

        // THEN
        XCTAssertTrue(hasUnread, "Conversation should have unread messages")
        XCTAssertGreaterThan(conversation.estimatedUnreadCount, 0)
    }

    func testUnreadMessagesPredicate_WithoutUnreadMessages() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add read message
            let message = try! conversation.appendText(content: "Read message") as! ZMClientMessage
            message.serverTimestamp = Date(timeIntervalSinceNow: -120)
            conversation.updateTimestampsAfterUpdatingMessage(message)
            conversation.lastReadServerTimeStamp = Date()
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // WHEN
        let hasUnread = conversation.estimatedUnreadCount > 0

        // THEN
        XCTAssertFalse(hasUnread, "Conversation should not have unread messages")
        XCTAssertEqual(conversation.estimatedUnreadCount, 0)
    }

    // MARK: - Mentions Predicate Tests

    func testMentionsPredicate_WithUnreadMention() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add unread mention
            let mention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
            let message = try! conversation.appendText(
                content: "@self hello",
                mentions: [mention],
                replyingTo: nil,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            message.serverTimestamp = Date()
            conversation.updateTimestampsAfterUpdatingMessage(message)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // WHEN
        let hasMentions = conversation.unreadMessages.contains { message in
            message.textMessageData?.isMentioningSelf ?? false
        }

        // THEN
        XCTAssertTrue(hasMentions, "Conversation should have unread mentions")
    }

    func testMentionsPredicate_WithReadMention() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add read mention
            let mention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
            let message = try! conversation.appendText(
                content: "@self hello",
                mentions: [mention],
                replyingTo: nil,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            message.serverTimestamp = Date(timeIntervalSinceNow: -120)
            conversation.updateTimestampsAfterUpdatingMessage(message)
            conversation.lastReadServerTimeStamp = Date()
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // WHEN
        let hasMentions = conversation.unreadMessages.contains { message in
            message.textMessageData?.isMentioningSelf ?? false
        }

        // THEN
        XCTAssertFalse(hasMentions, "Conversation should not have unread mentions")
    }

    func testMentionsPredicate_WithMentionOfOtherUser() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add mention of other user (not self)
            let mention = Mention(range: NSRange(location: 0, length: 6), user: self.otherUser)
            let message = try! conversation.appendText(
                content: "@other hello",
                mentions: [mention],
                replyingTo: nil,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            message.serverTimestamp = Date()
            conversation.updateTimestampsAfterUpdatingMessage(message)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // WHEN
        let hasMentions = conversation.unreadMessages.contains { message in
            message.textMessageData?.isMentioningSelf ?? false
        }

        // THEN
        XCTAssertFalse(hasMentions, "Conversation should not have unread self mentions")
    }

    // MARK: - Replies Predicate Tests

    func testRepliesPredicate_WithUnreadReply() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Create original message from self
            let originalMessage = try! conversation.appendText(content: "Original message") as! ZMClientMessage
            originalMessage.sender = self.selfUser
            originalMessage.serverTimestamp = Date(timeIntervalSinceNow: -180)

            // Create unread reply from other user
            let replyMessage = try! conversation.appendText(
                content: "Reply to you",
                mentions: [],
                replyingTo: originalMessage,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            replyMessage.sender = self.otherUser
            replyMessage.serverTimestamp = Date()
            conversation.updateTimestampsAfterUpdatingMessage(replyMessage)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // WHEN
        let hasReplies = conversation.unreadMessages.contains { message in
            message.textMessageData?.isQuotingSelf ?? false
        }

        // THEN
        XCTAssertTrue(hasReplies, "Conversation should have unread replies")
    }

    func testRepliesPredicate_WithReadReply() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Create original message from self
            let originalMessage = try! conversation.appendText(content: "Original message") as! ZMClientMessage
            originalMessage.sender = self.selfUser
            originalMessage.serverTimestamp = Date(timeIntervalSinceNow: -240)

            // Create read reply from other user
            let replyMessage = try! conversation.appendText(
                content: "Reply to you",
                mentions: [],
                replyingTo: originalMessage,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            replyMessage.sender = self.otherUser
            replyMessage.serverTimestamp = Date(timeIntervalSinceNow: -120)
            conversation.updateTimestampsAfterUpdatingMessage(replyMessage)
            conversation.lastReadServerTimeStamp = Date()
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // WHEN
        let hasReplies = conversation.unreadMessages.contains { message in
            message.textMessageData?.isQuotingSelf ?? false
        }

        // THEN
        XCTAssertFalse(hasReplies, "Conversation should not have unread replies")
    }

    func testRepliesPredicate_WithReplyToOtherUser() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Create original message from other user
            let originalMessage = try! conversation.appendText(content: "Original message") as! ZMClientMessage
            originalMessage.sender = self.otherUser
            originalMessage.serverTimestamp = Date(timeIntervalSinceNow: -180)

            // Create reply to other user (not self)
            let replyMessage = try! conversation.appendText(
                content: "Reply to other",
                mentions: [],
                replyingTo: originalMessage,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            replyMessage.sender = self.selfUser
            replyMessage.serverTimestamp = Date()
            conversation.updateTimestampsAfterUpdatingMessage(replyMessage)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // WHEN
        let hasReplies = conversation.unreadMessages.contains { message in
            message.textMessageData?.isQuotingSelf ?? false
        }

        // THEN
        XCTAssertFalse(hasReplies, "Conversation should not have replies to self")
    }

    // MARK: - Drafts Predicate Tests

    func testDraftsPredicate_WithDraftMessage() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add draft message
            let draft = DraftMessage(
                text: "This is a draft message",
                mentions: [],
                quote: nil
            )
            conversation.draftMessage = draft
        }

        // WHEN
        let hasDraft = conversation.draftMessage != nil

        // THEN
        XCTAssertTrue(hasDraft, "Conversation should have a draft message")
    }

    func testDraftsPredicate_WithoutDraftMessage() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Ensure no draft message
            conversation.draftMessage = nil
        }

        // WHEN
        let hasDraft = conversation.draftMessage != nil

        // THEN
        XCTAssertFalse(hasDraft, "Conversation should not have a draft message")
    }

    func testDraftsPredicate_WithEmptyDraftMessage() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add empty draft message
            let draft = DraftMessage(
                text: "",
                mentions: [],
                quote: nil
            )
            conversation.draftMessage = draft
        }

        // WHEN
        let hasDraft = conversation.draftMessage != nil

        // THEN
        XCTAssertTrue(hasDraft, "Conversation should have a draft message even if empty")
    }

    func testDraftsPredicate_WithDraftContainingMentions() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add draft with mentions
            let mention = Mention(range: NSRange(location: 0, length: 5), user: self.otherUser)
            let draft = DraftMessage(
                text: "@user This is a draft with mention",
                mentions: [mention],
                quote: nil
            )
            conversation.draftMessage = draft
        }

        // WHEN
        let hasDraft = conversation.draftMessage != nil
        let hasMentions = conversation.draftMessage?.mentions.isEmpty == false

        // THEN
        XCTAssertTrue(hasDraft, "Conversation should have a draft message")
        XCTAssertTrue(hasMentions, "Draft should contain mentions")
    }

    func testDraftsPredicate_WithDraftContainingQuote() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Create a message to quote
            let originalMessage = try! conversation.appendText(content: "Original message") as! ZMClientMessage
            originalMessage.serverTimestamp = Date(timeIntervalSinceNow: -120)

            // Add draft with quote
            let draft = DraftMessage(
                text: "This is a reply draft",
                mentions: [],
                quote: originalMessage
            )
            conversation.draftMessage = draft
        }

        // WHEN
        let hasDraft = conversation.draftMessage != nil
        let hasQuote = conversation.draftMessage?.quote != nil

        // THEN
        XCTAssertTrue(hasDraft, "Conversation should have a draft message")
        XCTAssertTrue(hasQuote, "Draft should contain a quote")
    }

    // MARK: - Combined Predicate Tests

    func testCombinedPredicates_UnreadWithMentionAndReply() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add regular unread message
            let regularMessage = try! conversation.appendText(content: "Regular message") as! ZMClientMessage
            regularMessage.serverTimestamp = Date(timeIntervalSinceNow: -30)

            // Add unread mention
            let mention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
            let mentionMessage = try! conversation.appendText(
                content: "@self check this",
                mentions: [mention],
                replyingTo: nil,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            mentionMessage.serverTimestamp = Date(timeIntervalSinceNow: -20)

            // Add unread reply
            let originalMessage = try! conversation.appendText(content: "My question") as! ZMClientMessage
            originalMessage.sender = self.selfUser
            originalMessage.serverTimestamp = Date(timeIntervalSinceNow: -180)

            let replyMessage = try! conversation.appendText(
                content: "Here's the answer",
                mentions: [],
                replyingTo: originalMessage,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            replyMessage.sender = self.otherUser
            replyMessage.serverTimestamp = Date(timeIntervalSinceNow: -10)

            conversation.updateTimestampsAfterUpdatingMessage(regularMessage)
            conversation.updateTimestampsAfterUpdatingMessage(mentionMessage)
            conversation.updateTimestampsAfterUpdatingMessage(replyMessage)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // WHEN & THEN
        XCTAssertTrue(conversation.estimatedUnreadCount > 0, "Should have unread messages")
        XCTAssertTrue(
            conversation.unreadMessages.contains { $0.textMessageData?.isMentioningSelf ?? false },
            "Should have unread mentions"
        )
        XCTAssertTrue(
            conversation.unreadMessages.contains { $0.textMessageData?.isQuotingSelf ?? false },
            "Should have unread replies"
        )
    }

    func testCombinedPredicates_ConversationWithDraftAndUnreadMessages() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add draft message
            let draft = DraftMessage(
                text: "This is my draft",
                mentions: [],
                quote: nil
            )
            conversation.draftMessage = draft

            // Add unread message
            let unreadMessage = try! conversation.appendText(content: "Unread message") as! ZMClientMessage
            unreadMessage.serverTimestamp = Date()
            conversation.updateTimestampsAfterUpdatingMessage(unreadMessage)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // WHEN & THEN
        XCTAssertTrue(conversation.draftMessage != nil, "Should have draft message")
        XCTAssertTrue(conversation.estimatedUnreadCount > 0, "Should have unread messages")
    }

    // MARK: - Edge Cases

    func testPredicates_WithDeletedMessages() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add unread mention that will be deleted
            let mention = Mention(range: NSRange(location: 0, length: 5), user: self.selfUser)
            let message = try! conversation.appendText(
                content: "@self deleted",
                mentions: [mention],
                replyingTo: nil,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            message.serverTimestamp = Date()
            conversation.updateTimestampsAfterUpdatingMessage(message)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)

            // Delete the message
            message.markAsDeleted()

            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // WHEN
        let hasMentions = conversation.unreadMessages.contains { message in
            message.textMessageData?.isMentioningSelf ?? false
        }

        // THEN
        XCTAssertFalse(hasMentions, "Deleted messages should not count as unread mentions")
    }

    func testPredicates_WithSystemMessages() {
        // GIVEN
        let conversation = createConversation()

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add system message
            let systemMessage = ZMSystemMessage(
                nonce: UUID(),
                managedObjectContext: self.coreDataFixture.uiMOC
            )
            systemMessage.systemMessageType = .participantsAdded
            systemMessage.serverTimestamp = Date()
            systemMessage.visibleInConversation = conversation
            systemMessage.sender = self.otherUser

            conversation.updateTimestampsAfterUpdatingMessage(systemMessage)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // WHEN
        let hasUnread = conversation.estimatedUnreadCount > 0
        let hasMentions = conversation.unreadMessages.contains { message in
            message.textMessageData?.isMentioningSelf ?? false
        }
        let hasReplies = conversation.unreadMessages.contains { message in
            message.textMessageData?.isQuotingSelf ?? false
        }

        // THEN
        XCTAssertTrue(hasUnread, "System messages should count as unread")
        XCTAssertFalse(hasMentions, "System messages should not count as mentions")
        XCTAssertFalse(hasReplies, "System messages should not count as replies")
    }

    // MARK: - Helper Methods

    private func createConversation() -> ZMConversation {
        ZMConversation.createTeamGroupConversation(
            moc: coreDataFixture.uiMOC,
            otherUser: otherUser,
            selfUser: selfUser
        )
    }
}

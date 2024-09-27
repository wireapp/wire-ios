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

import UIKit
import WireTestingPackage
import XCTest
@testable import Wire

// MARK: - MockConversation

private final class MockConversation: MockStableRandomParticipantsConversation,
    ConversationStatusProvider,
    TypingStatusProvider,
    VoiceChannelProvider {
    // MARK: Lifecycle

    required init() {
        self.status = ConversationStatus(
            isGroup: false,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [],
            messagesRequiringAttentionByType: [:],
            isTyping: false,
            mutedMessageTypes: .none,
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: false,
            hasSelfReply: false
        )
    }

    // MARK: Internal

    var voiceChannel: VoiceChannel?

    var typingUsers: [UserType] = []

    var status: ConversationStatus

    static func createOneOnOneConversation(
        otherUser: MockUserType
    ) -> MockConversation {
        SelfUser.setupMockSelfUser()
        let otherUserConversation = MockConversation()

        // avatar
        otherUserConversation.stableRandomParticipants = [otherUser]
        otherUserConversation.conversationType = .oneOnOne

        // title
        otherUserConversation.displayName = otherUser.name!

        // subtitle
        otherUserConversation.connectedUserType = otherUser

        return otherUserConversation
    }

    func setIsTyping(
        _: Bool
    ) {
        // no-op
    }
}

// MARK: - ConversationListCellTests

final class ConversationListCellTests: XCTestCase {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        otherUser = MockUserType.createDefaultOtherUser()
        otherUserConversation = MockConversation.createOneOnOneConversation(otherUser: otherUser)

        accentColor = .blue
        // The cell must higher than 64, otherwise it breaks the constraints.
        sut = ConversationListCell(frame: CGRect(x: 0, y: 0, width: 375, height: ConversationListItemView.minHeight))
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        SelfUser.provider = nil
        otherUserConversation = nil
        otherUser = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatItRendersWithoutStatus() {
        // WHEN & THEN
        verify(otherUserConversation)
    }

    func testThatItRendersMutedConversation() {
        // WHEN
        let status = ConversationStatus(
            isGroup: false,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [],
            messagesRequiringAttentionByType: [:],
            isTyping: false,
            mutedMessageTypes: [.all],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: false,
            hasSelfReply: false
        )
        otherUserConversation.status = status

        // THEN
        verify(otherUserConversation)
    }

    func testThatItRendersBlockedConversation() {
        // WHEN
        otherUserConversation.connectedUserType?.block(completion: { _ in })

        let status = ConversationStatus(
            isGroup: false,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [],
            messagesRequiringAttentionByType: [:],
            isTyping: false,
            mutedMessageTypes: [],
            isOngoingCall: false,
            isBlocked: true,
            isSelfAnActiveMember: true,
            hasSelfMention: false,
            hasSelfReply: false
        )
        otherUserConversation.status = status

        otherUser.isConnected = false

        // THEN
        verify(otherUserConversation)
    }

    func testThatItRendersConversationWithNewMessage() {
        // WHEN

        let message = createNewMessage()

        let status = ConversationStatus(
            isGroup: false,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [message],
            messagesRequiringAttentionByType: [.text: 1],
            isTyping: false,
            mutedMessageTypes: [],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: false,
            hasSelfReply: false
        )
        otherUserConversation.status = status

        // THEN
        verify(otherUserConversation)
    }

    func testThatItRendersConversationWithNewMessages() {
        // WHEN
        var messages: [MockMessage] = []
        for _ in 0 ..< 8 {
            let message = createNewMessage()

            messages.append(message)
        }

        let status = ConversationStatus(
            isGroup: false,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: messages,
            messagesRequiringAttentionByType: [.text: 8],
            isTyping: false,
            mutedMessageTypes: [],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: false,
            hasSelfReply: false
        )
        otherUserConversation.status = status

        // THEN
        verify(otherUserConversation)
    }

    func testThatItRendersConversation_TextMessagesThenMention() {
        // WHEN
        let message = createNewMessage()

        let mentionMessage = createMentionSelfMessage()

        let status = ConversationStatus(
            isGroup: false,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [
                message,
                mentionMessage,
            ],
            messagesRequiringAttentionByType: [
                .mention: 1,
                .text: 1,
            ],
            isTyping: false,
            mutedMessageTypes: [],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: true,
            hasSelfReply: false
        )
        otherUserConversation.status = status

        // THEN
        verify(otherUserConversation)
    }

    func testThatItRendersConversation_TextMessagesThenMentionThenReply() {
        // WHEN
        let replyMessage = createNewMessage(text: "Pong!")

        let status = ConversationStatus(
            isGroup: false,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [replyMessage],
            messagesRequiringAttentionByType: [
                .mention: 1,
                .reply: 1,
            ],
            isTyping: false,
            mutedMessageTypes: [],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: true,
            hasSelfReply: false
        )
        otherUserConversation.status = status

        // THEN
        verify(otherUserConversation)
    }

    func testThatItRendersConversation_ReplySelfMessage() {
        // WHEN
        let replyMessage = createNewMessage(text: "reply test")

        let status = ConversationStatus(
            isGroup: false,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [replyMessage],
            messagesRequiringAttentionByType: [.reply: 1],
            isTyping: false,
            mutedMessageTypes: [],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: false,
            hasSelfReply: true
        )
        otherUserConversation.status = status

        // THEN
        verify(otherUserConversation)
    }

    func testThatItRendersConversation_MentionThenTextMessages() {
        // WHEN
        let message = createNewMessage()

        let mentionMessage: MockMessage = MockMessageFactory.textMessage(
            withText: "@self test",
            sender: otherUser,
            conversation: otherUserConversation
        )

        let status = ConversationStatus(
            isGroup: false,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [
                mentionMessage,
                message,
            ],
            messagesRequiringAttentionByType: [
                .text: 1,
                .mention: 1,
            ],
            isTyping: false,
            mutedMessageTypes: [],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: true,
            hasSelfReply: false
        )
        otherUserConversation.status = status

        // THEN
        verify(otherUserConversation)
    }

    func testThatItRendersMutedConversation_TextMessagesThenMention() {
        // WHEN
        let message = createNewMessage()
        let mentionMessage = createMentionSelfMessage()

        let status = ConversationStatus(
            isGroup: false,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [
                mentionMessage,
                message,
            ],
            messagesRequiringAttentionByType: [
                .text: 1,
                .mention: 1,
            ],
            isTyping: false,
            mutedMessageTypes: [.all],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: true,
            hasSelfReply: false
        )
        otherUserConversation.status = status

        // THEN
        verify(otherUserConversation)
    }

    // Notice: same result as testThatItRendersMutedConversation_TextMessagesThenMention with reversed message order
    func testThatItRendersMutedConversation_MentionThenTextMessages() {
        // WHEN

        let message = createNewMessage()
        let mentionMessage = createMentionSelfMessage()

        let status = ConversationStatus(
            isGroup: false,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [
                message,
                mentionMessage,
            ],
            messagesRequiringAttentionByType: [
                .mention: 1,
                .text: 1,
            ],
            isTyping: false,
            mutedMessageTypes: [.all],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: true,
            hasSelfReply: false
        )
        otherUserConversation.status = status

        // THEN
        verify(otherUserConversation)
    }

    func testThatItRendersConversationWithKnock() {
        // WHEN
        let message: MockMessage = MockMessageFactory.pingMessage()
        let status = ConversationStatus(
            isGroup: false,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [message],
            messagesRequiringAttentionByType: [.knock: 1],
            isTyping: false,
            mutedMessageTypes: [],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: false,
            hasSelfReply: false
        )
        otherUserConversation.status = status

        // THEN
        verify(otherUserConversation)
    }

    func testThatItRendersConversationWithTypingOtherUser() {
        // WHEN
        let status = ConversationStatus(
            isGroup: false,
            hasMessages: true,
            hasUnsentMessages: false,
            messagesRequiringAttention: [],
            messagesRequiringAttentionByType: [:],
            isTyping: true,
            mutedMessageTypes: [.none],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: false,
            hasSelfReply: false
        )
        otherUserConversation.status = status

        // THEN
        verify(otherUserConversation)
    }

    // no typing status and right icon
    func testThatItRendersConversationWithTypingSelfUser() {
        // WHEN
        otherUserConversation.setIsTyping(true)

        // THEN
        verify(otherUserConversation)
    }

    func testThatItRendersGroupConversation() {
        // WHEN
        let conversation = MockConversation()
        let newUser = MockUserType.createUser(name: "Ana")
        conversation.stableRandomParticipants = [newUser, otherUser]
        conversation.displayName = "Ana, Bruno"

        // THEN
        verify(conversation)
    }

    /// test for SelfUserLeftMatcher is matched
    func testThatItRendersGroupConversationThatWasLeft() {
        // WHEN
        let conversation = createGroupConversation()

        let status = ConversationStatus(
            isGroup: true,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [],
            messagesRequiringAttentionByType: [:],
            isTyping: true,
            mutedMessageTypes: [],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: false,
            hasSelfMention: false,
            hasSelfReply: false
        )
        otherUserConversation.status = status
        // THEN
        verify(conversation)
    }

    func testThatItRendersGroupConversationWithIncomingCall() {
        let conversation = createGroupConversation()
        let icon = CallingMatcher.icon(
            for: .incoming(video: false, shouldRing: true, degraded: false),
            conversation: conversation
        )
        verify(conversation, icon: icon)
    }

    func testThatItRendersGroupConversationWithIncomingCall_SilencedExceptMentions() {
        let conversation = createGroupConversation()
        conversation.mutedMessageTypes = .mentionsAndReplies
        let icon = CallingMatcher.icon(
            for: .incoming(video: false, shouldRing: true, degraded: false),
            conversation: conversation
        )
        verify(conversation, icon: icon)
    }

    func testThatItRendersGroupConversationWithIncomingCall_SilencedAll() {
        let conversation = createGroupConversation()
        conversation.mutedMessageTypes = .all
        let icon = CallingMatcher.icon(
            for: .incoming(video: false, shouldRing: true, degraded: false),
            conversation: conversation
        )
        verify(conversation, icon: icon)
    }

    func testThatItRendersGroupConversationWithOngoingCall() {
        let conversation = createGroupConversation()
        let icon = CallingMatcher.icon(for: .outgoing(degraded: false), conversation: conversation)
        verify(conversation, icon: icon)
    }

    func testThatItRendersGroupConversationWithTextMessages() {
        // WHEN
        let conversation = createGroupConversation()
        let message = createNewMessage()

        let status = ConversationStatus(
            isGroup: true,
            hasMessages: false,
            hasUnsentMessages: false,
            messagesRequiringAttention: [message],
            messagesRequiringAttentionByType: [.text: 1],
            isTyping: false,
            mutedMessageTypes: [],
            isOngoingCall: false,
            isBlocked: false,
            isSelfAnActiveMember: true,
            hasSelfMention: false,
            hasSelfReply: false
        )
        conversation.status = status

        // THEN
        verify(conversation)
    }

    func testThatItRendersOneOnOneConversationWithIncomingCall() {
        let conversation = otherUserConversation
        let icon = CallingMatcher.icon(
            for: .incoming(video: false, shouldRing: true, degraded: false),
            conversation: conversation
        )
        verify(conversation!, icon: icon)
    }

    func testThatItRendersOneOnOneConversationWithIncomingCall_SilencedExceptMentions() {
        let conversation = otherUserConversation
        conversation?.mutedMessageTypes = .mentionsAndReplies
        let icon = CallingMatcher.icon(
            for: .incoming(video: false, shouldRing: true, degraded: false),
            conversation: conversation
        )
        verify(conversation!, icon: icon)
    }

    func testThatItRendersOneOnOneConversationWithIncomingCall_SilencedAll() {
        let conversation = otherUserConversation
        conversation?.mutedMessageTypes = .all
        let icon = CallingMatcher.icon(
            for: .incoming(video: false, shouldRing: true, degraded: false),
            conversation: conversation
        )
        verify(conversation!, icon: icon)
    }

    func testThatItRendersOneOnOneConversationWithOngoingCall() {
        let conversation = otherUserConversation
        let icon = CallingMatcher.icon(for: .outgoing(degraded: false), conversation: conversation)
        verify(conversation!, icon: icon)
    }

    // MARK: Private

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: ConversationListCell!
    private var otherUserConversation: MockConversation!
    private var otherUser: MockUserType!

    // MARK: - Helper Methods

    private func createNewMessage(text: String = "Hey there!") -> MockMessage {
        let message: MockMessage = MockMessageFactory.textMessage(
            withText: text,
            sender: otherUser,
            conversation: otherUserConversation
        )

        return message
    }

    private func createMentionSelfMessage() -> MockMessage {
        let mentionMessage: MockMessage = MockMessageFactory.textMessage(
            withText: "@self test",
            sender: otherUser,
            conversation: otherUserConversation
        )

        return mentionMessage
    }

    private func verify(
        _ conversation: MockConversation,
        icon: ConversationStatusIcon? = nil,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        sut.conversation = conversation

        if let icon {
            sut.itemView.rightAccessory.icon = icon
        }

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut, file: file, testName: testName, line: line)
    }

    private func createGroupConversation() -> MockConversation {
        let conversation = MockConversation()
        conversation.stableRandomParticipants = [otherUser]
        conversation.displayName = otherUser.displayName

        return conversation
    }
}

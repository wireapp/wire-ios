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

import XCTest

@testable import Wire

final class ConversationReplyWithTextCellSnapshotTests: ConversationMessageSnapshotTestCase {

    // MARK: - Properties

    private var mockOtherUser: MockUserType!

    // MARK: - setUp / tearDown

    override func setUp() {
        super.setUp()
        mockOtherUser = MockUserType.createConnectedUser(name: "Alice", color: .blue)
    }

    override func tearDown() {
        mockOtherUser = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    /// Other user replies to another user's text message (default blue accent color).
    func testOtherUserReplyToTextMessage() {
        let quoteUser = MockUserType.createConnectedUser(name: "Bob", color: .green)
        let message = makeReplyMessage(
            replyText: "That's a great point!",
            quoteText: "We should refactor this code",
            quoteSender: quoteUser,
            replySender: mockOtherUser
        )
        verify(message: message, allColorSchemes: true)
    }

    /// Self user replies to another user's text message.
    func testSelfUserReplyToTextMessage() {
        let selfUser = MockUserType.createConnectedUser(name: "Me", isSelfUser: true, color: .red)
        let message = makeReplyMessage(
            replyText: "I am responsible",
            quoteText: "Who is responsible for this!",
            quoteSender: mockOtherUser,
            replySender: selfUser
        )
        verify(message: message, allColorSchemes: true)
    }

    /// Self user with purple accent color replies to another user.
    func testSelfUserReplyToTextMessage_purpleAccent() {
        let selfUser = MockUserType.createConnectedUser(name: "Me", isSelfUser: true, color: .purple)
        let message = makeReplyMessage(
            replyText: "Great discussion!",
            quoteText: "This is the original message",
            quoteSender: mockOtherUser,
            replySender: selfUser
        )
        verify(message: message, allColorSchemes: true)
    }

    /// Other user replies to an audio message (mic icon must always be white in the reply box).
    func testOtherUserReplyToAudioMessage() {
        let conversation = SwiftMockConversation()
        let audioSender = MockUserType.createConnectedUser(name: "Bob", color: .amber)
        let audioQuote = MockMessageFactory.audioMessage(sender: audioSender)!
        audioQuote.conversationLike = conversation
        audioQuote.serverTimestamp = Date.distantPast

        let message = MockMessageFactory.textMessage(withText: "I loved that voice message!")
        message.senderUser = mockOtherUser
        message.backingTextMessageData.hasQuote = true
        message.backingTextMessageData.quoteMessage = audioQuote

        verify(message: message, allColorSchemes: true)
    }

    /// Self user replies to an audio message.
    func testSelfUserReplyToAudioMessage() {
        let conversation = SwiftMockConversation()
        let selfUser = MockUserType.createConnectedUser(name: "Me", isSelfUser: true, color: .red)
        let audioQuote = MockMessageFactory.audioMessage(sender: mockOtherUser)!
        audioQuote.conversationLike = conversation
        audioQuote.serverTimestamp = Date.distantPast

        let message = MockMessageFactory.textMessage(withText: "Good point in that recording")
        message.senderUser = selfUser
        message.backingTextMessageData.hasQuote = true
        message.backingTextMessageData.quoteMessage = audioQuote

        verify(message: message, allColorSchemes: true)
    }

    // MARK: - Helpers

    private func makeReplyMessage(
        replyText: String,
        quoteText: String,
        quoteSender: MockUserType,
        replySender: MockUserType
    ) -> MockMessage {
        let conversation = SwiftMockConversation()
        let quote = MockMessageFactory.textMessage(withText: quoteText)
        quote.senderUser = quoteSender
        quote.conversationLike = conversation
        quote.serverTimestamp = Date.distantPast

        let message = MockMessageFactory.textMessage(withText: replyText)
        message.senderUser = replySender
        message.backingTextMessageData.hasQuote = true
        message.backingTextMessageData.quoteMessage = quote
        return message
    }
}

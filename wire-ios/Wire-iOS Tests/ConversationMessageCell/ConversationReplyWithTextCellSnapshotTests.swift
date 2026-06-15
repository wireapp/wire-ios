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

import WireLinkPreview
import XCTest

@testable import Wire

final class ConversationReplyWithTextCellSnapshotTests: ConversationMessageSnapshotTestCase {

    // MARK: - Properties

    private var mockOtherUser: MockUserType!
    private var mockSelfUser: MockUserType!

    // MARK: - setUp / tearDown

    override func setUp() {
        super.setUp()
        mockOtherUser = MockUserType.createConnectedUser(name: "Alice", color: .blue)
        mockSelfUser = MockUserType.createConnectedUser(name: "Me", isSelfUser: true, color: .red)
    }

    override func tearDown() {
        mockOtherUser = nil
        mockSelfUser = nil
        MediaAssetCache.defaultImageCache.cache.removeAllObjects()
        super.tearDown()
    }

    // MARK: - Text quote variations

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
        let message = makeReplyMessage(
            replyText: "I am responsible",
            quoteText: "Who is responsible for this!",
            quoteSender: mockOtherUser,
            replySender: mockSelfUser
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

    /// Inline code in the reply text must only highlight the code span itself,
    /// not extend the background across the full line width.
    func testReplyWithInlineCodeInReplyText() {
        let message = makeReplyMessage(
            replyText: "This is a test with a variable name `BACKEND_NAME` test here",
            quoteText: "This is a quote without inline code",
            quoteSender: mockOtherUser,
            replySender: mockSelfUser
        )
        verify(message: message, allColorSchemes: true)
    }

    /// Reply to a quote that contains an @-mention of another user.
    func testReplyToMessageWithOtherMention() {
        let quote = MockMessageFactory.textMessage(withText: "@Bruno is the annual report ready to go?")
        quote.backingTextMessageData.mentions = [
            Mention(range: NSRange(location: 0, length: 6), user: mockOtherUser)
        ]
        let reply = makeReply(replyText: "Almost done", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Reply to a quote that contains an @-mention of the self user (different highlight).
    func testReplyToMessageWithSelfMention() {
        let quote = MockMessageFactory.textMessage(withText: "@selfUser is the annual report ready to go?")
        quote.backingTextMessageData.mentions = [
            Mention(range: NSRange(location: 0, length: 9), user: mockSelfUser)
        ]
        let reply = makeReply(replyText: "On it", quote: quote, replySender: mockOtherUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Long quoted text gets truncated to 4 lines in the preview.
    func testReplyToLongTextIsTruncatedAfterFourLines() {
        let longText = "@Bruno do we have the latest mockup files ready to go for the annual report? Once we have the copy finalized I would like to drop it in and get this out as quickly as possible. We can also add more lines to the test message if we need."
        let quote = MockMessageFactory.textMessage(withText: longText)
        quote.backingTextMessageData.mentions = [
            Mention(range: NSRange(location: 0, length: 6), user: mockOtherUser)
        ]
        let reply = makeReply(replyText: "Let me check", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Markdown headers in the quote do not change font in the preview.
    func testReplyToMarkdownText() {
        let markdown = """
        # Summary of Today's Meeting Upcoming due dates:
        - Jan 4, final copy in review
        - Jan 15, final layout with copy
        - Jan 20, release on website
        """
        let quote = MockMessageFactory.textMessage(withText: markdown)
        let reply = makeReply(replyText: "Thanks for the summary", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Markdown numbered list without headers.
    func testReplyToMarkdownText_noHeaders() {
        let markdown = """
        1. Annual report status: We need to get the final copy finished before we can finalize a layout.
        2. Board meeting: Steph will begin brainstorming for the next project.
        """
        let quote = MockMessageFactory.textMessage(withText: markdown)
        let reply = makeReply(replyText: "Got it", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Quote containing only emoji.
    func testReplyToEmojiOnlyMessage() {
        let quote = MockMessageFactory.textMessage(withText: "🌮🌮🌮")
        quote.senderUser = mockOtherUser
        let reply = makeReply(replyText: "Yum", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Edit badge is shown when the quoted message was edited.
    func testReplyToEditedMessage() {
        let quote = MockMessageFactory.textMessage(withText: "@Bruno is the annual report ready to go?")
        quote.backingTextMessageData.mentions = [
            Mention(range: NSRange(location: 0, length: 6), user: mockOtherUser)
        ]
        quote.updatedAt = Date()
        let reply = makeReply(replyText: "Yes", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    // MARK: - Link preview quote

    /// Reply to a message that is a bare link preview.
    func testReplyToLinkPreviewMessage() {
        let url = "https://apple.com/de/apple-pay"
        let quote = MockMessageFactory.textMessage(withText: url)
        quote.backingTextMessageData.backingLinkPreview = LinkMetadata(
            originalURLString: url,
            permanentURLString: url,
            resolvedURLString: url,
            offset: 0
        )
        quote.senderUser = mockOtherUser
        let reply = makeReply(replyText: "Cool link", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Reply to a message that has both text and a link preview.
    func testReplyToLinkPreviewWithText() {
        let url = "https://apple.com/de/apple-pay"
        let quote = MockMessageFactory.textMessage(withText: "There you go! https://apple.com/de/apple-pay")
        quote.backingTextMessageData.backingLinkPreview = LinkMetadata(
            originalURLString: url,
            permanentURLString: url,
            resolvedURLString: url,
            offset: 14
        )
        quote.senderUser = mockOtherUser
        let reply = makeReply(replyText: "Thanks!", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    // MARK: - Rich content quote types

    /// Reply to an image message — square image thumbnail in the preview.
    func testReplyToImageMessage_square() {
        let image = image(inTestBundleNamed: "unsplash_square.jpg")
        let quote: MockMessage = MockMessageFactory.imageMessage(with: image)
        quote.senderUser = mockOtherUser
        let reply = makeReply(replyText: "Nice shot", quote: quote, replySender: mockSelfUser)
        verify(message: reply, waitForImagesToLoad: true, allColorSchemes: true)
    }

    /// Reply to an image message — portrait image thumbnail in the preview.
    func testReplyToImageMessage_portrait() {
        let image = image(inTestBundleNamed: "unsplash_vertical_pano.jpg")
        let quote: MockMessage = MockMessageFactory.imageMessage(with: image)
        quote.senderUser = mockOtherUser
        let reply = makeReply(replyText: "Nice shot", quote: quote, replySender: mockSelfUser)
        verify(message: reply, waitForImagesToLoad: true, allColorSchemes: true)
    }

    /// Reply to an image message — panoramic image thumbnail in the preview.
    func testReplyToImageMessage_pano() {
        let image = image(inTestBundleNamed: "unsplash_pano.jpg")
        let quote: MockMessage = MockMessageFactory.imageMessage(with: image)
        quote.senderUser = mockOtherUser
        let reply = makeReply(replyText: "Nice shot", quote: quote, replySender: mockSelfUser)
        verify(message: reply, waitForImagesToLoad: true, allColorSchemes: true)
    }

    /// Reply to an image message with empty image data.
    func testReplyToImageMessage_nullImage() {
        let quote: MockMessage = MockMessageFactory.imageMessage(with: UIImage())
        quote.senderUser = mockOtherUser
        let reply = makeReply(replyText: "Hmm", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Reply to a video message — thumbnail in the preview.
    func testReplyToVideoMessage() {
        let preview = image(inTestBundleNamed: "unsplash_square.jpg")
        let quote: MockMessage = MockMessageFactory.fileTransferMessage()
        quote.backingFileMessageData!.filename = "Video.mp4"
        quote.backingFileMessageData!.mimeType = "video/mp4"
        quote.backingFileMessageData!.previewData = preview.jpegData(compressionQuality: 1)
        quote.senderUser = mockOtherUser
        let reply = makeReply(replyText: "Cool video", quote: quote, replySender: mockSelfUser)
        verify(message: reply, waitForImagesToLoad: true, allColorSchemes: true)
    }

    /// Reply to a file message — filename + document icon in the preview.
    func testReplyToFileMessage() {
        let quote: MockMessage = MockMessageFactory.fileTransferMessage()
        quote.backingFileMessageData!.filename = "Annual Report.pdf"
        quote.backingFileMessageData!.mimeType = "application/pdf"
        quote.senderUser = mockOtherUser
        let reply = makeReply(replyText: "Reading now", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Other user replies to an audio message (mic icon must always be white in the reply box).
    func testOtherUserReplyToAudioMessage() {
        let audioSender = MockUserType.createConnectedUser(name: "Bob", color: .amber)
        let quote = MockMessageFactory.audioMessage(sender: audioSender)!
        let reply = makeReply(replyText: "I loved that voice message!", quote: quote, replySender: mockOtherUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Self user replies to an audio message.
    func testSelfUserReplyToAudioMessage() {
        let quote = MockMessageFactory.audioMessage(sender: mockOtherUser)!
        let reply = makeReply(replyText: "Good point in that recording", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Reply to a location message — location pin + name in the preview.
    func testReplyToLocationMessage() {
        let quote: MockMessage = MockMessageFactory.locationMessage()
        quote.backingLocationMessageData.name = "Rosenthaler Str. 40-41, 10178 Berlin"
        quote.senderUser = mockOtherUser
        let reply = makeReply(replyText: "On my way", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// A long location name should not be truncated mid-line.
    func testReplyToLocationMessage_longName() {
        let quote: MockMessage = MockMessageFactory.locationMessage()
        quote.backingLocationMessageData.name = "Hackesher Markt, Rosenthaler Str. 40-41, 10178 Berlin, Germany"
        quote.senderUser = mockOtherUser
        let reply = makeReply(replyText: "On my way", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Reply to a message type that cannot be quoted (e.g. ping) shows the "broken message" preview.
    func testReplyToUnsupportedMessage() {
        let quote: MockMessage = MockMessageFactory.pingMessage()
        quote.senderUser = mockOtherUser
        let reply = makeReply(replyText: "What?", quote: quote, replySender: mockSelfUser)
        verify(message: reply, allColorSchemes: true)
    }

    /// Reply to a message whose original was deleted (quoteMessage is nil, hasQuote is true and
    /// the deleted tombstone is resolvable). Shows "Deleted message".
    func testReplyToDeletedMessage() {
        let reply = MockMessageFactory.textMessage(withText: "Sorry, was that for me?")
        reply.senderUser = mockSelfUser
        reply.backingTextMessageData.hasQuote = true
        reply.backingTextMessageData.quoteMessage = nil
        reply.backingTextMessageData.quotedMessageIsDeleted = true
        verify(message: reply, allColorSchemes: true)
    }

    /// Reply to a message the user cannot see (quoteMessage is nil, hasQuote is true and the
    /// original isn't in the user's copy of the conversation). Shows "You cannot see this message".
    func testReplyToUnseenMessage() {
        let reply = MockMessageFactory.textMessage(withText: "Sorry, was that for me?")
        reply.senderUser = mockSelfUser
        reply.backingTextMessageData.hasQuote = true
        reply.backingTextMessageData.quoteMessage = nil
        reply.backingTextMessageData.quotedMessageIsDeleted = false
        verify(message: reply, allColorSchemes: true)
    }

    // MARK: - Helpers

    private func makeReplyMessage(
        replyText: String,
        quoteText: String,
        quoteSender: MockUserType,
        replySender: MockUserType
    ) -> MockMessage {
        let quote = MockMessageFactory.textMessage(withText: quoteText)
        quote.senderUser = quoteSender
        return makeReply(replyText: replyText, quote: quote, replySender: replySender)
    }

    private func makeReply(
        replyText: String,
        quote: MockMessage,
        replySender: MockUserType
    ) -> MockMessage {
        let conversation = SwiftMockConversation()
        quote.conversationLike = conversation
        quote.serverTimestamp = Date.distantPast

        let message = MockMessageFactory.textMessage(withText: replyText)
        message.senderUser = replySender
        message.backingTextMessageData.hasQuote = true
        message.backingTextMessageData.quoteMessage = quote
        return message
    }
}

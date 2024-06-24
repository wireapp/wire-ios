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

import WireDesign
import WireLinkPreview
import XCTest

@testable import Wire

// MARK: - UIView extension

extension UIView {

    fileprivate func prepareForSnapshot(_ size: CGSize = CGSize(width: 320, height: 216)) -> UIView {
        let container = ReplyRoundCornersView(containedView: self)
        container.translatesAutoresizingMaskIntoConstraints = false

        container.widthAnchor.constraint(equalToConstant: size.width).isActive = true

        container.backgroundColor = SemanticColors.View.backgroundUserCell

        return container
    }

}

// MARK: - MessageReplyPreviewViewTests

final class MessageReplyPreviewViewTests: XCTestCase {

    private let helper = SnapshotHelper()

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        FontScheme.configure(with: .large)
    }

    // MARK: - tearDown

    override func tearDown() {
        invalidateStyle()
        super.tearDown()
    }

    // MARK: - Helper methods

    func invalidateStyle() {
        NSAttributedString.invalidateMarkdownStyle()
        NSAttributedString.invalidateParagraphStyle()
    }

    private func verifyInLightMode(
        message: MockMessage,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let sut = message.replyPreview()!.prepareForSnapshot()
        helper.verifyViewInLightScheme(createSut: {sut
        }, file: file, testName: testName, line: line)
    }

    private func verifyInDarkMode(
        message: MockMessage,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let sut = message.replyPreview()!.prepareForSnapshot()
        helper.verifyViewInDarkScheme(createSut: { sut
        }, file: file, testName: testName, line: line)
    }

    // MARK: - Snapshot Tests

    func testThatItRendersTextMessagePreview() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed.")

        verifyInLightMode(message: message)
    }

    func testThatItRendersTextMessagePreview_DarkMode() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed.")

        verifyInDarkMode(message: message)
    }

    func testThatItRendersEmojiOnly() {
        let message = MockMessageFactory.textMessage(withText: "😀🌮")

        verifyInLightMode(message: message)
    }

    func testThatItRendersEmojiOnly_DarkMode() {
        let message = MockMessageFactory.textMessage(withText: "😀🌮")

        verifyInDarkMode(message: message)
    }

    // MARK: - Helper method

    private func mentionMessage() -> MockMessage {
        let message = MockMessageFactory.messageTemplate()

        let textMessageData = MockTextMessageData()
        textMessageData.messageText = "Hello @user"
        let mockUser = SwiftMockLoader.mockUsers().first!
        let mention = Mention(range: NSRange(location: 6, length: 5), user: mockUser)
        textMessageData.mentions = [mention]
        message.backingTextMessageData = textMessageData

        return message
    }

    // MARK: - Snapshot Tests

    func testThatItRendersMention() {
        verifyInLightMode(message: mentionMessage())
    }

    func testThatItRendersMention_DarkMode() {
        verifyInDarkMode(message: mentionMessage())
    }

    func testThatItRendersTextMessagePreview_LongText() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed.")
        verifyInLightMode(message: message)
    }

    func testThatItRendersTextMessagePreview_LongText_DarkMode() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed. Lorem Ipsum Dolor Sit Amed.")
        verifyInDarkMode(message: message)
    }

    func testThatItRendersFileMessagePreview() {
        let message = MockMessageFactory.fileTransferMessage()
        verifyInLightMode(message: message)
    }

    func testThatItRendersFileMessagePreview_DarkMode() {
        let message = MockMessageFactory.fileTransferMessage()
        verifyInDarkMode(message: message)
    }

    func testThatItRendersLocationMessagePreview() {
        let message = MockMessageFactory.locationMessage()
        verifyInLightMode(message: message)
    }

    func testThatItRendersLocationMessagePreview_DarkMode() {
        let message = MockMessageFactory.locationMessage()
        verifyInDarkMode(message: message)
    }

    func testThatItRendersLinkPreviewMessagePreview() {
        let url = "https://www.example.com/article/1"
        let article = ArticleMetadata(originalURLString: url, permanentURLString: url, resolvedURLString: url, offset: 0)
        article.title = "You won't believe what happened next!"

        let message = MockMessageFactory.textMessage(withText: "https://www.example.com/article/1")
        message.backingTextMessageData.backingLinkPreview = article
        message.backingTextMessageData.linkPreviewImageCacheKey = "image-id-unsplash_matterhorn.jpg"
        message.backingTextMessageData.imageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9)
        message.backingTextMessageData.linkPreviewHasImage = true

        let previewView = message.replyPreview()!
        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        verify(matching: previewView.prepareForSnapshot())
    }

    func testThatItRendersImageMessagePreview() throws {
        let image = self.image(inTestBundleNamed: "unsplash_matterhorn.jpg")
        let message = MockMessageFactory.imageMessage(with: image)

        let previewView = try XCTUnwrap(message.replyPreview())
        XCTAssert(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        verify(matching: previewView.prepareForSnapshot())
    }

    func disable_testThatItRendersVideoMessagePreview() {
        let message = MockMessageFactory.fileTransferMessage()
        message.backingFileMessageData.mimeType = "video/mp4"
        message.backingFileMessageData.filename = "vacation.mp4"
        message.backingFileMessageData.previewData = image(inTestBundleNamed: "unsplash_matterhorn.jpg").jpegData(compressionQuality: 0.9)

        let previewView = message.replyPreview()!
        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        verify(matching: previewView.prepareForSnapshot())
    }

    func testThatItRendersAudioMessagePreview() {
        let message = MockMessageFactory.fileTransferMessage()
        message.backingFileMessageData.mimeType = "audio/x-m4a"
        message.backingFileMessageData.filename = "vacation.m4a"

        let previewView = message.replyPreview()!
        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        verify(matching: previewView.prepareForSnapshot())
    }

    // MARK: - Unit Test

    func testDeallocation() {
        let message = MockMessageFactory.textMessage(withText: "Lorem Ipsum Dolor Sit Amed.")
        verifyDeallocation {
            return message.replyPreview()!
        }
    }
}

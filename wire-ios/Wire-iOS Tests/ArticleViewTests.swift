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

import WireDataModel
import WireLinkPreview
import XCTest
@testable import Wire

// MARK: - MockConversationMessageCellDelegate

final class MockConversationMessageCellDelegate: ConversationMessageCellDelegate {
    func conversationMessageWantsToShowActionsController(
        _ cell: UIView,
        actionsController: Wire.MessageActionsViewController
    ) {}

    func conversationMessageWantsToOpenUserDetails(
        _ cell: UIView,
        user: UserType,
        sourceView: UIView,
        frame: CGRect
    ) {
        // no-op
    }

    func conversationMessageWantsToOpenMessageDetails(
        _ cell: UIView,
        for message: ZMConversationMessage,
        preferredDisplayMode: MessageDetailsDisplayMode
    ) {
        // no-op
    }

    func conversationMessageWantsToOpenGuestOptionsFromView(
        _ cell: UIView,
        sourceView: UIView
    ) {
        // no-op
    }

    func conversationMessageWantsToOpenParticipantsDetails(
        _ cell: UIView,
        selectedUsers: [UserType],
        sourceView: UIView
    ) {
        // no-op
    }

    func conversationMessageShouldUpdate() {
        // no-op
    }

    func perform(
        action: MessageAction,
        for message: ZMConversationMessage,
        view: UIView
    ) {
        // no-op
    }
}

// MARK: - MockArticleViewDelegate

final class MockArticleViewDelegate: ContextMenuLinkViewDelegate {
    var url: URL?

    weak var delegate: ConversationMessageCellDelegate?
    var message: ZMConversationMessage?

    let mockConversationMessageCellDelegate = MockConversationMessageCellDelegate()

    init() {
        self.delegate = mockConversationMessageCellDelegate
        self.message = MockMessage()
    }
}

// MARK: - ArticleViewTests

final class ArticleViewTests: XCTestCase {
    // MARK: - Properties

    var sut: ArticleView!

    // MARK: - setUp

    override func setUp() {
        super.setUp()

        accentColor = .blue
    }

    // MARK: - tearDown

    override func tearDown() {
        MediaAssetCache.defaultImageCache.cache.removeAllObjects()
        sut = nil
        super.tearDown()
    }

    // MARK: - Fixture - Helper methods

    func articleWithoutPicture() -> MockTextMessageData {
        let article = ArticleMetadata(
            originalURLString: "https://www.example.com/article/1",
            permanentURLString: "https://www.example.com/article/1",
            resolvedURLString: "https://www.example.com/article/1",
            offset: 0
        )

        article.title = "Title with some words in it"
        article
            .summary =
            "Summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary"

        let textMessageData = MockTextMessageData()
        textMessageData.backingLinkPreview = article
        return textMessageData
    }

    private func articleWithPicture(imageNamed: String = "unsplash_matterhorn.jpg") -> MockTextMessageData {
        let article = ArticleMetadata(
            originalURLString: "https://www.example.com/article/1",
            permanentURLString: "https://www.example.com/article/1",
            resolvedURLString: "https://www.example.com/article/1",
            offset: 0
        )

        article.title = "Title with some words in it"
        article
            .summary =
            "Summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary"

        let textMessageData = MockTextMessageData()
        textMessageData.backingLinkPreview = article
        textMessageData.linkPreviewImageCacheKey = "image-id-\(imageNamed)"
        textMessageData.imageData = image(inTestBundleNamed: imageNamed).jpegData(compressionQuality: 0.9)
        textMessageData.linkPreviewHasImage = true

        return textMessageData
    }

    func articleWithLongURL() -> MockTextMessageData {
        let article = ArticleMetadata(
            originalURLString: "https://www.example.com/verylooooooooooooooooooooooooooooooooooooongpath/article/1/",
            permanentURLString: "https://www.example.com/veryloooooooooooooooooooooooooooooooooooongpath/article/1/",
            resolvedURLString: "https://www.example.com/veryloooooooooooooooooooooooooooooooooooongpath/article/1/",
            offset: 0
        )

        article.title = "Title with some words in it"
        article
            .summary =
            "Summary summary summary summary summary summary summary summary summary summary summary summary summary summary summary"

        let textMessageData = MockTextMessageData()
        textMessageData.backingLinkPreview = article
        textMessageData.linkPreviewImageCacheKey = "image-id"
        textMessageData.imageData = image(inTestBundleNamed: "unsplash_matterhorn.jpg")
            .jpegData(compressionQuality: 0.9)
        textMessageData.linkPreviewHasImage = true

        return textMessageData
    }

    func twitterStatusWithoutPicture() -> MockTextMessageData {
        let twitterStatus = TwitterStatusMetadata(
            originalURLString: "https://www.example.com/twitter/status/12345",
            permanentURLString: "https://www.example.com/twitter/status/12345/permanent",
            resolvedURLString: "https://www.example.com/twitter/status/12345/permanent",
            offset: 0
        )
        twitterStatus.author = "John Doe"
        twitterStatus.username = "johndoe"
        twitterStatus
            .message =
            "Message message message message message message message message message message message message message message message message message message"

        let textMessageData = MockTextMessageData()
        textMessageData.backingLinkPreview = twitterStatus

        return textMessageData
    }

    // MARK: - Unit Test

    func testContextMenuIsCreatedWithDeleteItem() {
        SelfUser.setupMockSelfUser()

        // GIVEN
        sut = ArticleView(withImagePlaceholder: true)
        let mockArticleViewDelegate = MockArticleViewDelegate()
        sut.delegate = mockArticleViewDelegate

        // WHEN
        let menu = sut.delegate?.makeContextMenu(title: "test", view: sut)

        // THEN
        let children = menu!.children
        XCTAssertEqual(children.count, 1)
        XCTAssertEqual(children.first?.title, "Delete")
    }

    func setUpArticleView(
        withImagePlaceholder: Bool,
        textMessageData: TextMessageData
    ) -> ArticleView {
        let sut = ArticleView(withImagePlaceholder: withImagePlaceholder)
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.configure(withTextMessageData: textMessageData, obfuscated: false)
        sut.layoutIfNeeded()
        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        return sut
    }

    // MARK: - Snapshot Tests

    func testArticleViewWithoutPicture() {
        // GIVEN && WHEN
        sut = setUpArticleView(
            withImagePlaceholder: false,
            textMessageData: articleWithoutPicture()
        )

        // THEN
        verifyInAllPhoneWidths(matching: sut)
    }

    func testArticleViewWithPicture() {
        // GIVEN && WHEN
        sut = setUpArticleView(
            withImagePlaceholder: true,
            textMessageData: articleWithPicture()
        )

        // THEN
        verifyInAllPhoneWidths(matching: sut)
    }

    func testArticleViewWithPictureStillDownloading() {
        // GIVEN && WHEN
        let textMessageData = articleWithPicture()
        textMessageData.imageData = .none

        sut = setUpArticleView(
            withImagePlaceholder: true,
            textMessageData: textMessageData
        )
        sut.layer.speed = 0 // freeze animations for deterministic tests
        sut.layer.beginTime = 0

        // THEN
        verifyInAllPhoneWidths(matching: sut)
    }

    func disable_testArticleViewWithTruncatedURL() {
        // GIVEN && WHEN
        sut = setUpArticleView(
            withImagePlaceholder: true,
            textMessageData: articleWithLongURL()
        )

        // THEN
        verifyInAllPhoneWidths(matching: sut)
    }

    func testArticleViewWithTwitterStatusWithoutPicture() {
        // GIVEN && WHEN
        sut = setUpArticleView(withImagePlaceholder: false, textMessageData: twitterStatusWithoutPicture())

        verifyInAllPhoneWidths(matching: sut)
    }

    func testArticleViewObfuscated() {
        sut = ArticleView(withImagePlaceholder: true)
        sut.layer.speed = 0
        sut.translatesAutoresizingMaskIntoConstraints = false
        sut.configure(withTextMessageData: articleWithPicture(), obfuscated: true)
        sut.layoutIfNeeded()
        XCTAssertTrue(waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

        verifyInAllPhoneWidths(matching: sut)
    }

    // MARK: - ArticleView images aspect

    func disable_testArticleViewWithImageHavingSmallSize() {
        createTestForArticleViewWithImage(named: "unsplash_matterhorn_small_size.jpg")
    }

    func disable_testArticleViewWithImageHavingSmallHeight() {
        createTestForArticleViewWithImage(named: "unsplash_matterhorn_small_height.jpg")
    }

    func disable_testArticleViewWithImageHavingSmallWidth() {
        createTestForArticleViewWithImage(named: "unsplash_matterhorn_small_width.jpg")
    }

    func disable_testArticleViewWithImageHavingExactSize() {
        createTestForArticleViewWithImage(named: "unsplash_matterhorn_exact_size.jpg")
    }

    func createTestForArticleViewWithImage(
        named: String,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        verifyInAllPhoneWidths(
            createSut: {
                self.sut = ArticleView(withImagePlaceholder: true)
                self.sut.translatesAutoresizingMaskIntoConstraints = false
                self.sut.configure(withTextMessageData: self.articleWithPicture(imageNamed: named), obfuscated: false)
                XCTAssert(self.waitForGroupsToBeEmpty([MediaAssetCache.defaultImageCache.dispatchGroup]))

                return self.sut
            } as () -> UIView,
            file: file,
            testName: testName,
            line: line
        )
    }
}

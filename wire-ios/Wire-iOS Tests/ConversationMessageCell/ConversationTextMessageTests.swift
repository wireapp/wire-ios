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

import GenericMessageProtocol
import WireLinkPreview
import XCTest

@testable import Wire

final class ConversationTextMessageTests: ConversationMessageSnapshotTestCase {

    var mockOtherUser: MockUserType!
    var message: MockMessage!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        UIColor.setAccentOverride(.red)
        message = createMessage()
        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
    }

    // MARK: - tearDown

    override func tearDown() {
        mockOtherUser = nil
        message = nil
        super.tearDown()
    }

    func testTextMessageAccessibilityDoesNotPromiseUnsupportedGestures() throws {
        let cell = ConversationTextMessageCell(frame: .zero)
        cell.configure(with: .init(
            attributedText: NSAttributedString(string: "Hello"),
            isObfuscated: false,
            userSession: nil
        ), animated: false)
        let container = try XCTUnwrap(cell.subviews.first { $0 is ConversationMessageContainerView })

        XCTAssertTrue(container.isAccessibilityElement)
        XCTAssertEqual(container.accessibilityLabel, "Hello")
        XCTAssertNil(container.accessibilityHint)
    }

    func testTextMessageParentActionsComposeLinksAndRefreshOnReconfiguration() throws {
        let previousProvider = SelfUser.provider
        SelfUser.provider = SelfProvider(providedSelfUser: MockUserType.createSelfUser(name: "Me"))
        defer { SelfUser.provider = previousProvider }
        let tableView = UITableView()
        let text = NSMutableAttributedString(string: "first second")
        text.addAttribute(
            .link,
            value: URL(string: "https://example.com/first")!,
            range: NSRange(location: 0, length: 5)
        )
        text.addAttribute(
            .link,
            value: URL(string: "https://example.com/second")!,
            range: NSRange(location: 6, length: 6)
        )
        let description = ConversationTextMessageCellDescription(
            attributedString: text,
            isObfuscated: false,
            userSession: nil
        )
        description.message = message
        let controller = ConversationMessageActionController(
            responder: nil, message: message, context: .content, view: tableView
        )
        description.actionController = controller
        description.register(in: tableView)

        let cell = description.makeCell(for: tableView, at: IndexPath(row: 0, section: 0))
        let menuNames = controller.makeAccessibilityActions().map(\.name)
        let actions = try XCTUnwrap(cell.accessibilityCustomActions)
        XCTAssertFalse(menuNames.isEmpty)
        XCTAssertEqual(Array(actions.prefix(menuNames.count)).map(\.name), menuNames)
        XCTAssertEqual(actions.count, menuNames.count + 2)

        description.configuration = .init(attributedText: text, isObfuscated: true, userSession: nil)
        description.configureCell(cell)
        XCTAssertEqual(cell.accessibilityCustomActions?.map(\.name), menuNames)

        description.configuration = .init(
            attributedText: NSAttributedString(string: "No links"), isObfuscated: false, userSession: nil
        )
        description.configureCell(cell)
        XCTAssertEqual(cell.accessibilityCustomActions?.map(\.name), menuNames)
    }

    func testTextMessageMentionActionsRequireMatchingMessageMetadataAndClearOnReuse() {
        let cell = ConversationTextMessageCell(frame: .zero)
        let mention = Mention(range: NSRange(location: 0, length: 5), user: mockOtherUser)
        let text = NSAttributedString(string: "Bruno", attributes: [.link: mention.link])
        cell.configure(with: .init(attributedText: text, isObfuscated: false, userSession: nil), animated: false)
        cell.message = message
        XCTAssertTrue(cell.inlineLinkAccessibilityActions.isEmpty)

        message.backingTextMessageData.mentions = [mention]
        XCTAssertEqual(cell.inlineLinkAccessibilityActions.count, 1)
        XCTAssertTrue(cell.inlineLinkAccessibilityActions[0].name.contains("Bruno"))

        cell.prepareForReuse()
        XCTAssertTrue(cell.inlineLinkAccessibilityActions.isEmpty)
    }

    // MARK: - Snapshot Tests

    func testPlainText_WithALongUsernameAndShowingTheDateOfTheMessage() {
        // GIVEN, WHEN
        message = createMessage(
            withText: "Welcome to Dub Dub 2023",
            userName: "Bruno with a long long long long long long long long long long long long name"
        )

        message.deliveryState = .delivered

        // THEN
        verify(message: message, allWidths: true)
    }

    func testPlainText() {
        verify(message: message)
    }

    func testLinkPreview() {
        // GIVEN
        let linkURL = "http://www.example.com"
        let linkPreview = LinkPreview.with {
            $0.url = linkURL
            $0.permanentURL = linkURL
            $0.urlOffset = 0
            $0.title = "Biggest catastrophe in history"
            $0.summary = ""
        }
        let article = ArticleMetadata(protocolBuffer: linkPreview)
        message = createMessage(withText: "http://www.example.com")
        message.backingTextMessageData.backingLinkPreview = article

        // THEN

        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = [message.nonce!.uuidString]
        verify(message: message)

        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = []
        message.senderUser = userSession.selfUser
        verify(message: message, named: "Collapsed")
    }

    func testTextWithLinkPreview() {
        // GIVEN
        let linkURL = "http://www.example.com"
        let linkPreview = LinkPreview.with {
            $0.url = linkURL
            $0.permanentURL = linkURL
            $0.urlOffset = 0
            $0.title = "Biggest catastrophe in history"
            $0.summary = ""
        }
        let article = ArticleMetadata(protocolBuffer: linkPreview)
        message = createMessage(withText: "What do you think about this http://www.example.com")
        message.backingTextMessageData.backingLinkPreview = article

        // THEN

        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = [message.nonce!.uuidString]

        verify(message: message)

        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = []
        message.senderUser = userSession.selfUser
        verify(message: message, named: "Collapsed")
    }

    func testTextWithQuote() {
        // GIVEN
        let conversation = SwiftMockConversation()
        let quote = createMessage(withText: "Who is responsible for this!")
        quote.conversationLike = conversation
        quote.serverTimestamp = Date.distantPast
        let message = MockMessageFactory.textMessage(withText: "I am")
        message.backingTextMessageData.hasQuote = true
        message.backingTextMessageData.quoteMessage = quote

        // THEN
        verify(message: message)
    }

    func testTextWithLinkPreviewAndQuote() {
        // GIVEN
        let linkURL = "http://www.example.com"
        let linkPreview = LinkPreview.with {
            $0.url = linkURL
            $0.permanentURL = linkURL
            $0.urlOffset = 5
            $0.title = "Biggest catastrophe in history"
            $0.summary = ""
        }
        let article = ArticleMetadata(protocolBuffer: linkPreview)
        let conversation = SwiftMockConversation()
        let quote = createMessage(withText: "Who is responsible for this!")
        quote.conversationLike = conversation
        quote.serverTimestamp = Date.distantPast
        let message = createMessage(withText: "I am http://www.example.com")
        message.backingTextMessageData.backingLinkPreview = article
        message.backingTextMessageData.hasQuote = true
        message.backingTextMessageData.quoteMessage = quote
        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = [message.nonce!.uuidString]

        // THEN
        verify(message: message)
    }

    func testMediaPreviewAttachment() {
        // GIVEN
        message = createMessage(withText: "https://www.youtube.com/watch?v=l7aqpSTa234")
        message.linkAttachments = [
            LinkAttachment(
                type: .youTubeVideo,
                title: "Lagar mat med Fernando Di Luca",
                permalink: URL(string: "https://www.youtube.com/watch?v=l7aqpSTa234")!,
                thumbnails: [],
                originalRange: NSRange(location: 0, length: 43)
            )
        ]

        // THEN

        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = [message.nonce!.uuidString]

        verify(message: message, waitForTextViewToLoad: true)

        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = []
        message.senderUser = userSession.selfUser
        verify(message: message, named: "Collapsed", waitForTextViewToLoad: true)
    }

    func testSoundCloudMediaPreviewAttachment() {
        // GIVEN
        message = createMessage(withText: "https://soundcloud.com/bridgitmendler/bridgit-mendler-atlantis-feat-kaiydo")
        message.linkAttachments = [
            LinkAttachment(
                type: .soundCloudTrack,
                title: "Bridgit Mendler - Atlantis feat. Kaiydo",
                permalink: URL(string: "https://soundcloud.com/bridgitmendler/bridgit-mendler-atlantis-feat-kaiydo")!,
                thumbnails: [],
                originalRange: NSRange(location: 0, length: 74)
            )
        ]

        // THEN
        #if targetEnvironment(simulator) && swift(>=5.4)
            let options = XCTExpectedFailure.Options()
            options.isStrict = false
            XCTExpectFailure("This test is flaky, may be related to sound cloud preview text view?", options: options) {
                verify(message: message, waitForTextViewToLoad: true)
            }
        #else
            verify(message: message, named: "Collapsed", waitForTextViewToLoad: true)
            mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = [message.nonce!.uuidString]
            verify(message: message, waitForTextViewToLoad: true)
        #endif
    }

    func testSoundCloudSetMediaPreviewAttachment() {
        // GIVEN
        message = createMessage(withText: "https://soundcloud.com/playback/sets/2019-artists-to-watch")
        message.linkAttachments = [
            LinkAttachment(
                type: .soundCloudPlaylist,
                title: "Artists To Watch 2019",
                permalink: URL(string: "https://soundcloud.com/playback/sets/2019-artists-to-watch")!,
                thumbnails: [],
                originalRange: NSRange(location: 0, length: 58)
            )
        ]

        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = [message.nonce!.uuidString]
        // THEN
        verify(message: message, waitForTextViewToLoad: true)
    }

    func testBlacklistedLinkPreview_YouTube() {
        // GIVEN
        let linkURL = "https://youtube.com/watch"
        let linkPreview = LinkPreview.with {
            $0.url = linkURL
            $0.permanentURL = linkURL
            $0.urlOffset = 14
            $0.title = "Lagar mat med Fernando Di Luca"
            $0.summary = ""
        }
        let article = ArticleMetadata(protocolBuffer: linkPreview)
        message = createMessage(withText: "Look at this! https://www.youtube.com/watch?v=l7aqpSTa234")
        message.backingTextMessageData.backingLinkPreview = article
        message.linkAttachments = [
            LinkAttachment(
                type: .youTubeVideo,
                title: "Lagar mat med Fernando Di Luca",
                permalink: URL(string: "https://www.youtube.com/watch?v=l7aqpSTa234")!,
                thumbnails: [],
                originalRange: NSRange(location: 14, length: 43)
            )
        ]

        // THEN

        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = [message.nonce!.uuidString]
        verify(message: message)

        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = []
        message.senderUser = userSession.selfUser
        verify(message: message, named: "Collapsed")
    }

    // MARK: - Helper Methods

    func createMessage(
        withText: String =
            "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem.",
        userName: String = "Bruno"
    ) -> MockMessage {
        let message = MockMessageFactory.textMessage(withText: withText)
        mockOtherUser = MockUserType.createConnectedUser(name: userName)
        message.senderUser = mockOtherUser
        return message
    }

}

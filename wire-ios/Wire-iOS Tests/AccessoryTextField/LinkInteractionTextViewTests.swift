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

import Down
import XCTest
@testable import Wire

final class LinkInteractionTextViewTests: XCTestCase {

    var sut: LinkInteractionTextView!

    override func setUp() {
        super.setUp()
        sut = LinkInteractionTextView(frame: .zero, textContainer: nil)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testAccessibilityActionsUseAttributedLinksAndDistinctNames() throws {
        let recorder = InteractionRecorder()
        sut.interactionDelegate = recorder
        let text = NSMutableAttributedString(string: "🔗 details details details 12345")
        let firstURL = URL(string: "https://example.com/first")!
        let secondURL = URL(string: "https://example.com/second")!
        text.addAttribute(.link, value: firstURL, range: NSRange(location: 3, length: 7))
        text.addAttribute(.link, value: secondURL, range: NSRange(location: 11, length: 7))
        text.addAttribute(.link, value: firstURL, range: NSRange(location: 19, length: 7))
        text.addAttribute(.link, value: URL(string: "tel:12345")!, range: NSRange(location: 27, length: 5))
        sut.attributedText = text

        let actions = sut.makeAccessibilityLinkActions { _ in true }

        XCTAssertEqual(actions.count, 2)
        XCTAssertEqual(Set(actions.map(\.name)).count, 2)
        for action in actions {
            XCTAssertTrue(try XCTUnwrap(action.actionHandler)(action))
        }
        XCTAssertEqual(recorder.openedURLs, [firstURL, secondURL])
    }

    func testAccessibilityActionsRejectChangedLinksAndInvalidatedConfigurations() throws {
        let recorder = InteractionRecorder()
        sut.interactionDelegate = recorder
        let url = URL(string: "https://example.com/first")!
        sut.attributedText = NSAttributedString(string: "details", attributes: [.link: url])
        let oldAction = try XCTUnwrap(sut.makeAccessibilityLinkActions { _ in true }.first)
        sut.attributedText = NSAttributedString(
            string: "details",
            attributes: [.link: URL(string: "https://example.com/second")!]
        )
        XCTAssertFalse(try XCTUnwrap(oldAction.actionHandler)(oldAction))

        let reusedAction = try XCTUnwrap(sut.makeAccessibilityLinkActions { _ in true }.first)
        sut.invalidateAccessibilityLinkActions()
        XCTAssertFalse(try XCTUnwrap(reusedAction.actionHandler)(reusedAction))
        XCTAssertTrue(recorder.openedURLs.isEmpty)
    }

    func testAccessibilityActionsRecheckAvailabilityAndHandledResult() throws {
        let recorder = InteractionRecorder()
        sut.interactionDelegate = recorder
        sut.attributedText = NSAttributedString(
            string: "details",
            attributes: [.link: URL(string: "https://example.com")!]
        )
        var isAvailable = true
        let action = try XCTUnwrap(sut.makeAccessibilityLinkActions { _ in isAvailable }.first)
        isAvailable = false
        XCTAssertFalse(try XCTUnwrap(action.actionHandler)(action))
        XCTAssertTrue(recorder.openedURLs.isEmpty)

        isAvailable = true
        recorder.handlesLinks = false
        XCTAssertFalse(try XCTUnwrap(action.actionHandler)(action))
        XCTAssertEqual(recorder.openedURLs.count, 1)
    }

    func testAccessibilityActionsDoNotRetainTextView() throws {
        let recorder = InteractionRecorder()
        weak var textView: LinkInteractionTextView?
        let action = try autoreleasepool {
            let view = LinkInteractionTextView(frame: .zero, textContainer: nil)
            view.interactionDelegate = recorder
            view.attributedText = NSAttributedString(
                string: "details",
                attributes: [.link: URL(string: "https://example.com")!]
            )
            textView = view
            return try XCTUnwrap(view.makeAccessibilityLinkActions { _ in true }.first)
        }

        XCTAssertNil(textView)
        XCTAssertFalse(try XCTUnwrap(action.actionHandler)(action))
        XCTAssertTrue(recorder.openedURLs.isEmpty)
    }

    func testAccessibilityMarkdownActionUsesConfirmationInsteadOfOpeningURL() throws {
        let recorder = InteractionRecorder()
        sut.interactionDelegate = recorder
        let url = URL(string: "https://example.com/destination")!
        sut.attributedText = NSAttributedString(
            string: "details",
            attributes: [.markdownID: Markdown.link, .link: url]
        )
        let previousPresenter = UIApplication.shared.topmostViewController(onlyFullScreen: false)
        defer {
            if let alert = previousPresenter?.presentedViewController as? UIAlertController {
                alert.dismiss(animated: false)
            }
        }
        let action = try XCTUnwrap(sut.makeAccessibilityLinkActions { _ in true }.first)

        XCTAssertTrue(try XCTUnwrap(action.actionHandler)(action))
        XCTAssertTrue(recorder.openedURLs.isEmpty)
        if let alert = previousPresenter?.presentedViewController as? UIAlertController {
            XCTAssertEqual(alert.title, L10n.Localizable.Content.Message.OpenLinkAlert.title)
            XCTAssertTrue(alert.message?.contains(url.absoluteString) == true)
        }
    }

    func testThatItOpensNormalLinks() {
        ["http://www.wire.com", "x-apple-data-detectors:some-detected-data", "tel:12345678", "mailto:bob@example.com"]
            .forEach {
                // GIVEN
                let str = $0
                let url = URL(string: str)!
                sut.attributedText = NSAttributedString(string: str, attributes: [.link: url])
                // WHEN
                let shouldOpenURL = sut.delegate!.textView!(
                    sut,
                    shouldInteractWith: url,
                    in: NSRange(location: 0, length: str.count),
                    interaction: .invokeDefaultAction
                )
                // THEN
                XCTAssertTrue(shouldOpenURL)
            }
    }

    func testThatItDoesNotPreviewNormalLinks() {
        ["http://www.wire.com", "x-apple-data-detectors:some-detected-data", "tel:12345678", "mailto:bob@example.com"]
            .forEach {
                // GIVEN
                let str = $0
                let url = URL(string: str)!
                sut.attributedText = NSAttributedString(string: str, attributes: [.link: url])
                // WHEN
                let shouldOpenURL = sut.delegate!.textView!(
                    sut,
                    shouldInteractWith: url,
                    in: NSRange(location: 0, length: str.count),
                    interaction: .preview
                )
                // THEN
                XCTAssertFalse(shouldOpenURL)
            }
    }

    // Note: Markdown links should not be opened directly, but only after
    // confirmation from the user.

    func testThatItDoesNotOpenMarkdownLinks() {
        ["http://www.wire.com", "x-apple-data-detectors:some-detected-data", "tel:12345678", "mailto:bob@example.com"]
            .forEach {
                // GIVEN
                let str = "I'm a markdown link!"
                let url = URL(string: $0)!
                let attrs: [NSAttributedString.Key: Any] = [.markdownID: Markdown.link, .link: url]
                sut.attributedText = NSAttributedString(string: str, attributes: attrs)
                // WHEN
                let shouldOpenURL = sut.delegate!.textView!(
                    sut,
                    shouldInteractWith: url,
                    in: NSRange(location: 0, length: str.count),
                    interaction: .invokeDefaultAction
                )
                // THEN
                XCTAssertFalse(shouldOpenURL)
            }
    }

    func testThatItDoesNotOpenStylizedMarkdownLinks() {
        // GIVEN
        let str = "I'm a markdown link!"
        let url = URL(string: "http://www.wire.com")!

        let markdownId: Markdown = [.bold, .italic, .link]
        let attrs: [NSAttributedString.Key: Any] = [.markdownID: markdownId, .link: url]
        sut.attributedText = NSAttributedString(string: str, attributes: attrs)

        // WHEN
        let shouldOpenURL = sut.delegate!.textView!(
            sut,
            shouldInteractWith: url,
            in: NSRange(location: 0, length: str.count),
            interaction: .invokeDefaultAction
        )

        // THEN
        XCTAssertFalse(shouldOpenURL)
    }

    func testThatItDoesNotPreviewMarkdownLinks() {
        ["http://www.wire.com", "x-apple-data-detectors:some-detected-data", "tel:12345678", "mailto:bob@example.com"]
            .forEach {
                // GIVEN
                let str = "I'm a markdown link!"
                let url = URL(string: $0)!
                let attrs: [NSAttributedString.Key: Any] = [.markdownID: Markdown.link, .link: url]
                sut.attributedText = NSAttributedString(string: str, attributes: attrs)
                // WHEN
                let shouldOpenURL = sut.delegate!.textView!(
                    sut,
                    shouldInteractWith: url,
                    in: NSRange(location: 0, length: str.count),
                    interaction: .preview
                )
                // THEN
                XCTAssertFalse(shouldOpenURL)
            }
    }
}

private final class InteractionRecorder: TextViewInteractionDelegate {
    var openedURLs: [URL] = []
    var handlesLinks = true

    func textView(_ textView: LinkInteractionTextView, open url: URL) -> Bool {
        openedURLs.append(url)
        return handlesLinks
    }

    func textViewDidLongPress(_ textView: LinkInteractionTextView) {}
}

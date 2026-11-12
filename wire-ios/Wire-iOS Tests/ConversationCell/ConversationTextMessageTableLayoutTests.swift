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

import WireFoundationSupport
import WireMessagingDomainSupport
import WireTestingPackage
import XCTest

@testable import Wire

/// Lays out text message cells in a real `UITableView` with self-sizing rows, like the conversation does.
///
/// Unlike the stack view based message snapshot tests, the chat bubble here hugs its content, so its width
/// comes from the text view's intrinsic size. That is where single-item lists lost their last word
/// (WPB-27203). The long message test covers the first display, scrolling, cell reuse and reloading, where
/// a previous fix for that bug left long messages blank (WPB-29736).
final class ConversationTextMessageTableLayoutTests: ConversationMessageSnapshotTestCase {

    private var snapshotHelper: SnapshotHelper!
    private var otherUser: MockUserType!
    private var selfUser: MockUserType!
    private var window: UIWindow?
    private var dataSource: TableDataSource?

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        otherUser = MockUserType.createConnectedUser(name: "Bruno", isSelfUser: false)
        selfUser = MockUserType.createConnectedUser(name: "Alice", isSelfUser: true, color: .blue)
        UIColor.setAccentOverride(.red)
    }

    override func tearDown() {
        window?.isHidden = true
        window = nil
        dataSource = nil
        otherUser = nil
        selfUser = nil
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Messages where every line is indented (WPB-27203)

    func testThatSingleItemOrderedListIsFullyVisible() {
        verifyFullyVisible(text: "1. One two")
    }

    func testThatSingleItemUnorderedListIsFullyVisible() {
        verifyFullyVisible(text: "- One two")
    }

    func testThatSingleParagraphBlockquoteIsFullyVisible() {
        verifyFullyVisible(text: "> One two")
    }

    func testThatRightToLeftSingleItemListIsFullyVisible() {
        verifyFullyVisible(text: "1. שלום עולם")
    }

    func testThatWrappingSingleItemListIsFullyVisible() {
        verifyFullyVisible(
            text: "1. Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore"
        )
    }

    // MARK: - Long message (WPB-29736)

    func testThatLongMessageStaysVisibleWhileScrollingReusingAndReloading() {
        // GIVEN
        // Several copies so that scrolling dequeues reused cells.
        let messages = (0 ..< 4).flatMap { _ in
            [
                textMessage(Self.releaseNotes, sender: otherUser),
                textMessage("1. One two", sender: selfUser)
            ]
        }
        let (tableView, dataSource) = makeTableView(messages: messages, size: CGSize(width: 375, height: 667))

        // WHEN
        tableView.reloadData()
        tableView.layoutIfNeeded()

        // THEN
        assertTextIsFullyLaidOut(in: tableView, step: "first display")
        snapshotHelper.verify(matching: snapshot(of: tableView), named: "top")

        for (name, position) in [("middle", UITableView.ScrollPosition.middle), ("bottom", .bottom)] {
            scrollToFirstMessage(in: tableView, dataSource: dataSource, position: position)
            assertTextIsFullyLaidOut(in: tableView, step: "scrolled to message \(name)")
            snapshotHelper.verify(matching: snapshot(of: tableView), named: name)
        }

        // WHEN
        tableView.setContentOffset(.zero, animated: false)
        tableView.layoutIfNeeded()
        var offset: CGFloat = 0
        while offset < tableView.contentSize.height - tableView.bounds.height {
            offset = min(offset + 250, tableView.contentSize.height - tableView.bounds.height)
            tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
            tableView.layoutIfNeeded()

            // THEN
            assertTextIsFullyLaidOut(in: tableView, step: "scrolled down to \(offset)")
        }
        XCTAssertLessThan(
            dataSource.dequeuedCells.count,
            dataSource.cellRequestCount,
            "Scrolling should reuse cells"
        )

        // WHEN
        tableView.setContentOffset(.zero, animated: false)
        tableView.layoutIfNeeded()

        // THEN
        assertTextIsFullyLaidOut(in: tableView, step: "scrolled back to the top")
        snapshotHelper.verify(matching: snapshot(of: tableView), named: "top")

        // WHEN
        tableView.reloadData()
        tableView.layoutIfNeeded()

        // THEN
        assertTextIsFullyLaidOut(in: tableView, step: "reloaded")
        snapshotHelper.verify(matching: snapshot(of: tableView), named: "top")
    }

    func testThatLongMessageIsVisibleWhenOpenedInTheMiddle() {
        verifyLongMessageOnOpening(at: .middle)
    }

    func testThatLongMessageIsVisibleWhenOpenedAtTheBottom() {
        verifyLongMessageOnOpening(at: .bottom)
    }

    // MARK: - Helpers

    private func verifyLongMessageOnOpening(
        at position: UITableView.ScrollPosition,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        let (tableView, _) = makeTableView(
            messages: [textMessage(Self.releaseNotes, sender: otherUser)],
            size: CGSize(width: 375, height: 667),
            initialMessagePosition: position
        )
        tableView.layoutIfNeeded()
        XCTAssertGreaterThan(
            tableView.contentOffset.y,
            0,
            "Expected the table to open below the top",
            file: file,
            line: line
        )
        assertTextIsFullyLaidOut(in: tableView, step: "opened at \(position)", file: file, line: line)
        snapshotHelper.verify(
            matching: snapshot(of: tableView),
            file: file,
            testName: testName,
            line: line
        )
    }

    private func scrollToFirstMessage(
        in tableView: UITableView,
        dataSource: TableDataSource,
        position: UITableView.ScrollPosition
    ) {
        guard let row = dataSource.sections.first?.firstIndex(where: {
            $0.instance is ConversationTextMessageCellDescription
        }) else {
            XCTFail("Expected a text message row")
            return
        }
        let indexPath = IndexPath(row: row, section: 0)
        let messageRect = tableView.rectForRow(at: indexPath)
        XCTAssertGreaterThan(messageRect.height, tableView.bounds.height)
        // Explicit offsets also work for rows taller than the viewport, where scrollToRow
        // may choose to expose the top of the row instead of its requested portion.
        let offset = position == .middle
            ? messageRect.midY - tableView.bounds.height / 2
            : messageRect.maxY - tableView.bounds.height
        tableView.setContentOffset(CGPoint(x: 0, y: max(0, offset)), animated: false)
        tableView.layoutIfNeeded()
    }

    private func verifyFullyVisible(
        text: String,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        for width in [320, 375, 414] as [CGFloat] {
            // GIVEN
            let messages = [
                textMessage(text, sender: otherUser),
                textMessage(text, sender: selfUser)
            ]
            let (tableView, _) = makeTableView(messages: messages, size: CGSize(width: width, height: 600))

            // WHEN
            tableView.reloadData()
            tableView.layoutIfNeeded()

            // THEN
            assertTextIsFullyLaidOut(in: tableView, step: "width \(width)", file: file, line: line)
            snapshotHelper.verify(
                matching: snapshot(of: tableView),
                named: "\(Int(width))",
                file: file,
                testName: testName,
                line: line
            )
        }
    }

    private func textMessage(_ text: String, sender: MockUserType) -> MockMessage {
        let message = MockMessageFactory.textMessage(withText: text, includingRichMedia: false)
        message.senderUser = sender
        return message
    }

    private func makeTableView(
        messages: [ConversationMessage],
        size: CGSize,
        initialMessagePosition: UITableView.ScrollPosition? = nil
    ) -> (UITableView, TableDataSource) {
        let factory = MockWireMessagingFactoryProtocol()
        factory.makeFetchCachedNodeUseCase_MockValue = MockWireDriveFetchCachedNodeUseCaseProtocol()
        factory.makeFetchNodeUseCase_MockValue = MockWireDriveFetchNodeUseCaseProtocol()

        let dataSource = TableDataSource()
        dataSource.messages = messages
        dataSource.sectionControllers = messages.map { message in
            let sectionController = ConversationMessageSectionController(
                message: message,
                context: ConversationMessageContext(
                    isSameSenderAsPrevious: false,
                    isTimestampInSameMinuteAsPreviousMessage: false,
                    isFirstMessageOfTheDay: false,
                    isFirstUnreadMessage: false,
                    isLastMessage: false,
                    searchQueries: [],
                    previousMessageIsKnock: false
                ),
                selfUser: userSession.selfUser,
                userSession: userSession,
                useInvertedIndices: false,
                contentWidth: size.width,
                userDefaults: mockUserDefaults,
                wireMessagingFactory: factory
            )
            // Like `ConversationTableViewDataSource`, hand the message to the cell descriptions.
            sectionController.updateMessage(message)
            return sectionController
        }
        dataSource.sections = dataSource.sectionControllers.map(\.cellDescriptionsForTesting)

        // Same row sizing as `ConversationContentViewController`.
        let tableView = UITableView(frame: CGRect(origin: .zero, size: size), style: .plain)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.backgroundColor = .white
        dataSource.sections.joined().forEach { $0.register(in: tableView) }
        tableView.dataSource = dataSource

        // The table view lays out and reuses cells like on screen only inside a visible window. The window
        // needs a scene, otherwise the render server can drop the content of tall text views from snapshots.
        let windowScene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = windowScene.map { UIWindow(windowScene: $0) } ?? UIWindow()
        window.frame = tableView.frame
        window.rootViewController = UIViewController()
        window.rootViewController?.view.addSubview(tableView)
        window.makeKeyAndVisible()
        if let initialMessagePosition {
            // Restore the viewing position before the first frame is rendered (at the end of this run loop
            // turn). A newly created table must render correctly there without first displaying the top.
            // Doing this before the window is visible does not work: the position is reset to the top.
            tableView.reloadData()
            tableView.layoutIfNeeded()
            scrollToFirstMessage(in: tableView, dataSource: dataSource, position: initialMessagePosition)
        }
        self.window?.isHidden = true
        self.window = window
        // `UITableView.dataSource` is weak.
        self.dataSource = dataSource

        return (tableView, dataSource)
    }

    /// Renders the table view as it is on screen, without re-laying it out.
    private func snapshot(of tableView: UITableView) -> UIImage {
        let image = UIGraphicsImageRenderer(bounds: tableView.bounds).image { _ in
            tableView.drawHierarchy(in: tableView.bounds, afterScreenUpdates: true)
        }
        // Compare the PNG representation, like the reference images, to avoid color space differences.
        return UIImage(data: image.pngData()!, scale: image.scale)!
    }

    /// Asserts that every visible message text view has room for all of its text.
    private func assertTextIsFullyLaidOut(
        in tableView: UITableView,
        step: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let textViews = tableView.visibleCells.flatMap { $0.descendants(ofType: LinkInteractionTextView.self) }
        XCTAssertFalse(textViews.isEmpty, "\(step): no visible text view", file: file, line: line)

        for textView in textViews {
            let layoutManager = textView.layoutManager
            let textContainer = textView.textContainer
            layoutManager.ensureLayout(for: textContainer)

            let visibleGlyphs = layoutManager.glyphRange(for: textContainer)
            let visibleCharacters = layoutManager.characterRange(forGlyphRange: visibleGlyphs, actualGlyphRange: nil)
            let text = textView.attributedText.string
            XCTAssertEqual(
                NSMaxRange(visibleCharacters),
                (text as NSString).length,
                "\(step): only \((text as NSString).substring(with: visibleCharacters).debugDescription) " +
                    "of \(text.debugDescription) fits into \(textView.bounds.size)",
                file: file,
                line: line
            )
            // The view must be neither shorter (clipped text) nor taller (blank space, WPB-29736) than its
            // text. The tolerance covers rounding the view height to pixels.
            let textHeight = layoutManager.usedRect(for: textContainer).maxY
                + textView.textContainerInset.top + textView.textContainerInset.bottom
            XCTAssertEqual(
                textView.bounds.height,
                textHeight,
                accuracy: 1,
                "\(step): view height \(textView.bounds.height) does not match text height \(textHeight)",
                file: file,
                line: line
            )
        }
    }

    /// The text of an Android beta release notes message, reconstructed from a screenshot, as an example
    /// of the long messages that were rendered blank in WPB-29736.
    private static let releaseNotes = """
    Hi Team 👋
    Android beta 4.39.0, build 1 is out 🔵
    Release: https://github.com/wireapp/wire-android/releases/tag/v4.39.0-beta.1

    **New**
    - Wire Drive: delete files permanently in bulk, and empty the recycle bin (WPB-29592, WPB-29591)

    **Improved**
    - Permission prompts are easier to use with accessibility tools (WPB-24974)
    - Wire Drive checks that a file is available before it opens (WPB-29376)
    - "Waiting for network" shows only for real network problems (WPB-29846)
    - Sync retries right away after you switch networks
    - Backups keep conversation read dates (WPB-29860)
    - The encryption notice shows at the start of every conversation (WPB-29856)
    - Unknown messages show as a notice, not as typed text

    **Fixed**
    - Typing indicator position with an expanded input box (WPB-22037)
    - Sketch screen info message placement (WPB-21862)
    - Audio playback stops when you delete the message (WPB-21425)
    - The app no longer closes when the share screen closes (WPB-23989)
    - Attachment options visibility (WPB-14777)
    - Screenshot sync issues are censored (WPB-23962)
    - Logout removes leftover files: oversized-file copies, camera captures, backup folders and Wire Drive downloads (WPB-27675)
    - Uploading files with special characters in the name (WPB-29369)
    - Read receipts go only to the original sender (WPB-29620)
    - Messages stay pending through network loss, and you can delete pending messages offline (WPB-29597, WPB-29750)
    - Sender profile refreshes after the user updates it (WPB-27513)
    - New team members appear (WPB-21722)
    - Deleting a conversation clears its notifications (WPB-23292)
    - Self-deleting messages count in the message list position (WPB-29861)
    - Typing indicators expire after 60 seconds
    - Link previews keep modern domain endings and check destinations more strictly (WPB-29748)
    - A kept connection stays accepted when its 1:1 conversation can't be resolved
    - Better error handling for welcome messages (WPB-22235)

    This is available for our selected audience 👀 jokes aside, we really need you, so if you have an android phone and you are not using our beta app, you are missing not only the earliest and greatest, but the chance to help us make Wire better 🤝
    """
}

// MARK: - TableDataSource

private final class TableDataSource: NSObject, UITableViewDataSource {

    /// Cell descriptions and cells reference their message weakly; in the app, Core Data keeps it alive.
    var messages: [ConversationMessage] = []
    var sectionControllers: [ConversationMessageSectionController] = []
    var sections: [[AnyConversationMessageCellDescription]] = []
    private(set) var cellRequestCount = 0
    private(set) var dequeuedCells = Set<ObjectIdentifier>()

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = sections[indexPath.section][indexPath.row].makeCell(for: tableView, at: indexPath)
        cellRequestCount += 1
        dequeuedCells.insert(ObjectIdentifier(cell))
        return cell
    }
}

// MARK: - UIView

private extension UIView {

    func descendants<T: UIView>(ofType type: T.Type) -> [T] {
        subviews.flatMap { subview in
            ((subview as? T).map { [$0] } ?? []) + subview.descendants(ofType: type)
        }
    }
}

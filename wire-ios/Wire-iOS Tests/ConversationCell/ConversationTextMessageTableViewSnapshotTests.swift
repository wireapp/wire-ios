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
import XCTest

@testable import Wire

/// Hosts the real `ConversationMessageCellTableViewAdapter` inside an actual self-sizing
/// `UITableView`, matching how `ConversationContentViewController` renders messages in
/// production. This is deliberately different from `ConversationMessageSnapshotTestCase
/// .verify(message:)`, which measures the bare cell view via a `UIStackView` and never
/// exercises `ConversationMessageCellTableViewAdapter.systemLayoutSizeFitting` — so it cannot
/// reproduce WPB-27203, where the adapter's self-sizing measurement under-reports the row
/// height and the last word of a single-item list is clipped off.
final class ConversationTextMessageTableViewSnapshotTests: ZMSnapshotTestCase {

    var mockSelfUser: MockUserType!
    var userSession: UserSessionMock!
    var mockUserDefaults: UserDefaultsProtocolMock!

    override func setUp() {
        super.setUp()

        mockSelfUser = MockUserType.createDefaultSelfUser()
        UIColor.setAccentOverride(.red)
        userSession = UserSessionMock()
        mockUserDefaults = UserDefaultsProtocolMock()
        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = []
        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = false
    }

    override func tearDown() {
        mockSelfUser = nil
        userSession = nil
        mockUserDefaults = nil

        super.tearDown()
    }

    private func verifyTableView(
        messageText: String,
        width: CGFloat,
        named: String,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        let message = MockMessageFactory.textMessage(
            withText: messageText,
            sender: mockSelfUser,
            includingRichMedia: false
        )

        let factory = MockWireMessagingFactoryProtocol()
        factory.makeFetchCachedNodeUseCase_MockValue = MockWireDriveFetchCachedNodeUseCaseProtocol()
        factory.makeFetchNodeUseCase_MockValue = MockWireDriveFetchNodeUseCaseProtocol()

        let sectionController = ConversationMessageSectionController(
            message: message,
            context: ConversationMessageContext(),
            selfUser: userSession.selfUser,
            userSession: userSession,
            useInvertedIndices: false,
            contentWidth: width,
            userDefaults: mockUserDefaults,
            wireMessagingFactory: factory
        )

        // A message maps to several rows (sender header, text content, footer…) — find the
        // one that actually renders the message text, not just the first (header) row.
        guard let cellDescription = sectionController.tableViewCellDescriptions.first(where: {
            $0.instance is ConversationTextMessageCellDescription
        }) else {
            XCTFail("Expected a ConversationTextMessageCellDescription", file: file, line: line)
            return
        }

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: width, height: 200), style: .plain)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.backgroundColor = ColorScheme.default.variant == .light ? .white : .black

        cellDescription.register(in: tableView)

        let cell = cellDescription.makeCell(for: tableView, at: IndexPath(row: 0, section: 0))
        cell.backgroundColor = tableView.backgroundColor

        // Reproduces exactly how `UITableView.automaticDimension` sizes a self-sizing row —
        // it asks the cell for its `systemLayoutSizeFitting` at the row's width. This is the
        // same call `ConversationMessageCellTableViewAdapter.systemLayoutSizeFitting`
        // overrides with a discarded "priming" measurement, which is the suspected cause of
        // WPB-27203.
        let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let computedSize = cell.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        cell.frame = CGRect(x: 0, y: 0, width: width, height: computedSize.height)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()

        verify(matching: cell, named: named, file: file, testName: testName, line: line)
    }

    /// Regression test for WPB-27203: a single ordered list item rendered through the real
    /// self-sizing table view cell, at the narrowest supported phone width.
    func testSingleOrderedListItem_320() {
        verifyTableView(messageText: "1. One two", width: 320, named: "320")
    }

    func testSingleOrderedListItem_375() {
        verifyTableView(messageText: "1. One two", width: 375, named: "375")
    }

    func testSingleOrderedListItem_414() {
        verifyTableView(messageText: "1. One two", width: 414, named: "414")
    }

    /// Regression test for WPB-27203: a single unordered list item rendered through the real
    /// self-sizing table view cell, at the narrowest supported phone width.
    func testSingleUnorderedListItem_320() {
        verifyTableView(messageText: "- One two", width: 320, named: "320")
    }

    func testSingleUnorderedListItem_375() {
        verifyTableView(messageText: "- One two", width: 375, named: "375")
    }

    func testSingleUnorderedListItem_414() {
        verifyTableView(messageText: "- One two", width: 414, named: "414")
    }

}

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

import WireTestingPackage
import XCTest

@testable import Wire

final class GroupDetailsTimeoutOptionsCellTests: CoreDataSnapshotTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var cell: GroupDetailsTimeoutOptionsCell!
    private var conversation: ZMConversation!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        cell = GroupDetailsTimeoutOptionsCell(frame: CGRect(x: 0, y: 0, width: 350, height: 56))
        conversation = createGroupConversation()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        cell = nil
        conversation = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatItDisplaysCell_WithoutTimeout_Light() {
        // GIVEN & WHEN
        updateTimeout(0)

        // THEN
        snapshotHelper.verify(matching: cell)
    }

    func testThatItDisplaysCell_WithoutTimeout_Dark() {
        // GIVEN & WHEN
        updateTimeout(0)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: cell)
    }

    func testThatItDisplaysCell_WithTimeout_Light() {
        // GIVEN & WHEN
        updateTimeout(300)

        // THEN
        snapshotHelper.verify(matching: cell)
    }

    func testThatItDisplaysCell_WithTimeout_Dark() {
        // GIVEN & WHEN
        updateTimeout(300)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: cell)
    }

    private func updateTimeout(_ newValue: TimeInterval) {
        conversation.setMessageDestructionTimeoutValue(.init(rawValue: newValue), for: .groupConversation)
        cell.configure(with: (conversation as Any) as! ZMConversation)
    }

}

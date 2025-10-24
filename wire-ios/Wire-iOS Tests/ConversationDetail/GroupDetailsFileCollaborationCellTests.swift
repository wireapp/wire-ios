//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class GroupDetailsFileCollaborationCellTests: CoreDataSnapshotTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var cell: GroupDetailsFileCollaborationCell!
    private var conversation: ZMConversation!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        cell = GroupDetailsFileCollaborationCell(frame: CGRect(x: 0, y: 0, width: 350, height: 56))
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

    func testThatItDisplaysCell_Light() {
        // GIVEN & WHEN
        cell.configure(with: conversation)

        // THEN
        snapshotHelper.verify(matching: cell)
    }

    func testThatItDisplaysCell_Dark() {
        // GIVEN & WHEN
        cell.configure(with: conversation)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: cell)
    }

}

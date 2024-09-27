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

final class CheckmarkCellTests: XCTestCase {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        conversation = SwiftMockConversation.groupConversation()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        conversation = nil
        super.tearDown()
    }

    // MARK: - Helper Method

    func setUpCheckMarkCell(
        title: String,
        showCheckmark: Bool
    ) {
        sut = CheckmarkCell(frame: CGRect(x: 0, y: 0, width: 350, height: 56))
        sut.title = title
        sut.showCheckmark = showCheckmark
    }

    // MARK: - Snapshot Tests

    func testCheckmarkCell_NoCheckmark_Light() {
        // GIVEN
        setUpCheckMarkCell(title: "Option A", showCheckmark: false)

        // WHEN & THEN
        snapshotHelper.verify(matching: sut)
    }

    func testCheckmarkCell_NoCheckmark_Dark() {
        // GIVEN
        setUpCheckMarkCell(title: "Option A", showCheckmark: false)

        // WHEN & THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testCheckmarkCell_WithCheckmark_Light() {
        // GIVEN
        setUpCheckMarkCell(title: "Option B", showCheckmark: true)

        // WHEN & THEN
        snapshotHelper.verify(matching: sut)
    }

    func testCheckmarkCell_WithCheckmark_Dark() {
        // GIVEN
        setUpCheckMarkCell(title: "Option B", showCheckmark: true)

        // WHEN & THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    // MARK: Private

    // MARK: - Properties

    private var sut: CheckmarkCell!
    private var conversation: SwiftMockConversation!
    private var snapshotHelper: SnapshotHelper!
}

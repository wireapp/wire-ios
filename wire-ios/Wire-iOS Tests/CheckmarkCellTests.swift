//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import SnapshotTesting
import XCTest
@testable import Wire

final class CheckmarkCellTests: BaseSnapshotTestCase {

    // MARK: - Properties

    var sut: CheckmarkCell!
    var conversation: MockConversation!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        conversation = MockConversation.groupConversation()
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        conversation = nil
        super.tearDown()
    }

    // MARK: - Helper Method

    func setUpCheckMarkCell(
        title: String,
        showCheckmark: Bool,
        userInterfaceStyle: UIUserInterfaceStyle = .light
    ) {
        sut = CheckmarkCell(frame: CGRect(x: 0, y: 0, width: 350, height: 56))
        sut.title = title
        sut.showCheckmark = showCheckmark
        sut.overrideUserInterfaceStyle = userInterfaceStyle
    }

    // MARK: - Snapshot Tests

    func testCheckmarkCell_NoCheckmark_Light() {
        setUpCheckMarkCell(title: "Option A", showCheckmark: false)
        verify(matching: sut)
    }

    func testCheckmarkCell_NoCheckmark_Dark() {
        setUpCheckMarkCell(title: "Option A", showCheckmark: false, userInterfaceStyle: .dark)
        verify(matching: sut)
    }

    func testCheckmarkCell_WithCheckmark_Light() {
        setUpCheckMarkCell(title: "Option B", showCheckmark: true)
        verify(matching: sut)
    }

    func testCheckmarkCell_WithCheckmark_Dark() {
        setUpCheckMarkCell(title: "Option B", showCheckmark: true, userInterfaceStyle: .dark)
        verify(matching: sut)
    }

}

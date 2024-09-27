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

final class CanvasViewControllerTests: XCTestCase {
    // MARK: - Properties

    private var sut: CanvasViewController!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        sut = CanvasViewController()

        sut.loadViewIfNeeded()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    func testForSendButtonEnabled() {
        sut.sendButton.isEnabled = true
        snapshotHelper.verify(matching: sut.view)
    }

    func testForEmojiKeyboard() {
        sut.emojiButton.sendActions(for: .touchUpInside)
        snapshotHelper.verify(matching: sut.view)
    }
}

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
        sut = CanvasViewController(userSession: UserSessionMock())

        sut.loadViewIfNeeded()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    func testEmojiSectionsKeepConstraintsStableWhenResizing() {
        let sections = EmojiSectionViewController(types: EmojiSectionType.allCases)
        let view = sections.view!
        let buttons = view.subviews
        view.frame = CGRect(x: 0, y: 0, width: 320, height: 48)
        view.layoutIfNeeded()
        let constraintCount = view.constraints.count

        for width: CGFloat in [320, 640, 320] {
            view.frame = CGRect(x: 0, y: 0, width: width, height: 48)
            view.layoutIfNeeded()
            view.setNeedsLayout()
            view.layoutIfNeeded()

            XCTAssertEqual(view.subviews, buttons)
            XCTAssertEqual(view.constraints.count, constraintCount)
            XCTAssertEqual(buttons.first!.frame.minX, 16, accuracy: 0.5)
            XCTAssertEqual(buttons.last!.frame.maxX, width - 16, accuracy: 0.5)
        }
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

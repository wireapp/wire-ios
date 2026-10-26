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

import XCTest

@testable import Wire

final class InputBarButtonsViewTests: XCTestCase {

    func testToggleAndButtonActionUpdateAccessibilityLabel() {
        let buttons = (0 ..< 7).map { _ in UIButton() }
        let sut = InputBarButtonsView(buttons: buttons)
        XCTAssertEqual(sut.expandRowButton.accessibilityLabel, L10n.Accessibility.Conversation.MoreButton.description)
        sut.frame = CGRect(x: 0, y: 0, width: 320, height: 56)
        sut.layoutIfNeeded()

        sut.expandRowButton.sendActions(for: .touchUpInside)
        XCTAssertEqual(sut.currentRow, 1)
        XCTAssertEqual(
            sut.expandRowButton.accessibilityLabel,
            L10n.Accessibility.Conversation.MoreButton.closeDescription
        )

        sut.expandRowButton.sendActions(for: .touchUpInside)
        XCTAssertEqual(sut.currentRow, 0)
        XCTAssertEqual(sut.expandRowButton.accessibilityLabel, L10n.Accessibility.Conversation.MoreButton.description)

        sut.expandRowButton.sendActions(for: .touchUpInside)
        buttons.last?.sendActions(for: .touchUpInside)
        XCTAssertEqual(sut.currentRow, 0)
        XCTAssertEqual(sut.expandRowButton.accessibilityLabel, L10n.Accessibility.Conversation.MoreButton.description)
    }

    func testWidthChangeResetsRowAndAccessibilityLabel() {
        let sut = InputBarButtonsView(buttons: (0 ..< 7).map { _ in UIButton() })
        sut.frame = CGRect(x: 0, y: 0, width: 320, height: 56)
        sut.layoutIfNeeded()
        sut.showRow(1, animated: false)
        XCTAssertEqual(
            sut.expandRowButton.accessibilityLabel,
            L10n.Accessibility.Conversation.MoreButton.closeDescription
        )

        sut.frame.size.width = 600
        sut.setNeedsLayout()
        sut.layoutIfNeeded()

        XCTAssertEqual(sut.currentRow, 0)
        XCTAssertTrue(sut.expandRowButton.isHidden)
        XCTAssertEqual(sut.expandRowButton.accessibilityLabel, L10n.Accessibility.Conversation.MoreButton.description)
    }
}

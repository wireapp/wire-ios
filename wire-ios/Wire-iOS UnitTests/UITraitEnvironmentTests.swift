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

import XCTest
@testable import Wire

// MARK: - UITraitEnvironmentTests

final class UITraitEnvironmentTests: XCTestCase {
    var sut: UITraitEnvironment!
    let compactMargins = HorizontalMargins(userInterfaceSizeClass: .compact)
    let regularMargins = HorizontalMargins(userInterfaceSizeClass: .regular)

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testForCompactMargins() {
        // GIVEN
        let view = UIView()

        // WHEN
        let margins = view.conversationHorizontalMargins
        // THEN
        XCTAssertEqual(margins.left, compactMargins.left)
        XCTAssertEqual(margins.right, compactMargins.right)
    }

    func testForRegularMarginsWithDefaultSimulatorWidth() {
        // GIVEN
        let mockView = MockRegularView()

        // WHEN
        let margins = mockView.conversationHorizontalMargins

        // THEN
        XCTAssertEqual(margins.left, compactMargins.left)
        XCTAssertEqual(margins.right, compactMargins.right)
    }

    func testForRegularMarginsWithFullScreenWidth() {
        // GIVEN
        let mockView = MockRegularView()

        // WHEN
        let margins = mockView.conversationHorizontalMargins(windowWidth: 1024)

        // THEN
        XCTAssertEqual(margins.left, regularMargins.left)
        XCTAssertEqual(margins.right, regularMargins.right)
    }
}

// MARK: - MockRegularView

final class MockRegularView: NSObject, UITraitEnvironment {
    var traitCollection = UITraitCollection(horizontalSizeClass: .regular)

    func traitCollectionDidChange(_: UITraitCollection?) {
        // no-op
    }
}

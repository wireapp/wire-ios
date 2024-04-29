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

import SnapshotTesting
@testable import Wire
import XCTest

final class TypingIndicatorViewSnapshotTests: BaseSnapshotTestCase {

    // MARK: - Properties

    var sut: TypingIndicatorView!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        sut = TypingIndicatorView()
        sut.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testOneTypingUser() {
        sut.typingUsers = Array(SwiftMockLoader.mockUsers().prefix(1))
        verify(matching: sut)
    }

    func testTwoTypingUsers() {
        sut.typingUsers = Array(SwiftMockLoader.mockUsers().prefix(2))
        verify(matching: sut)
    }

    func testManyTypingUsers() {
        // limit width to test overflow behaviour
        sut.widthAnchor.constraint(equalToConstant: 320).isActive = true

        sut.typingUsers = Array(SwiftMockLoader.mockUsers().prefix(5))
        verify(matching: sut)
    }

    // MARK: - Unit Tests

    func testThatContainerIsHidden() {
        sut.typingUsers = Array(SwiftMockLoader.mockUsers().prefix(5))
        sut.setHidden(true, animated: false)

        XCTAssertEqual(sut.container.alpha, 0)
    }

    func testThatContainerIsHiddenWhenAnimated() {
        sut.typingUsers = Array(SwiftMockLoader.mockUsers().prefix(5))
        sut.setHidden(true, animated: true)

        XCTAssertEqual(sut.container.alpha, 0)
    }

    func testThatLabelAndLineAreShownWhenAnimated() {
        // GIVEN
        sut.typingUsers = Array(SwiftMockLoader.mockUsers().prefix(5))

        let animationExpectation = expectation(description: "Animation completed")

        // WHEN
        sut.setHidden(false, animated: true) {
            XCTAssert(self.sut.animatedPen.isAnimating)
            animationExpectation.fulfill()
        }

        // THEN
        XCTAssertEqual(sut.container.alpha, 1)
        waitForExpectations(timeout: 0.5, handler: nil)
    }
}

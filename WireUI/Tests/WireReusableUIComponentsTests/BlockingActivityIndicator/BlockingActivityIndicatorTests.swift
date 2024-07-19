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

@testable import WireReusableUIComponents

final class BlockingActivityIndicatorTests: XCTestCase {

    private var sut: BlockingActivityIndicator!

    @MainActor
    func testBlockingSubviewIsAddedOnStart() throws {

        // Given
        let targetView = UIView(frame: .init(x: 100, y: 200, width: 300, height: 400))
        sut = .init(view: targetView)

        // When
        sut.start()
        targetView.setNeedsLayout()
        targetView.layoutIfNeeded()

        // Then
        let blockingView = try XCTUnwrap(targetView.subviews.first, "blocking view found")
        XCTAssertEqual(targetView.subviews.count, 1, "too many views added")
        XCTAssertEqual(blockingView.frame, targetView.bounds, "blocking view frame does not match target view bounds")

        let activityIndicatorView = try XCTUnwrap(blockingView.subviews.first as? UIActivityIndicatorView, "activity indicator view not found")
        XCTAssertTrue(activityIndicatorView.isAnimating)
    }
}

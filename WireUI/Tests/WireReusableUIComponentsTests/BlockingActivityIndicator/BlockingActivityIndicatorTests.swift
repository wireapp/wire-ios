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

import UIKit
import XCTest
@testable import WireReusableUIComponents

// MARK: - BlockingActivityIndicatorTests

final class BlockingActivityIndicatorTests: XCTestCase {
    private typealias SUT = BlockingActivityIndicator
    private var sut: SUT!

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

        let activityIndicatorView = try XCTUnwrap(
            blockingView.subviews.first as? ProgressSpinner,
            "activity indicator view not found"
        )
        XCTAssertTrue(activityIndicatorView.isAnimating)
    }

    @MainActor
    func testOnlyOneBlockingSubviewIsAdded() {
        // Given
        let targetView = UIView()
        sut = .init(view: targetView)
        let sut_ = SUT(view: targetView)

        // When
        sut.start()
        sut_.start()

        // Then
        XCTAssertEqual(targetView.subviews.count, 1, "too many views added")
    }

    @MainActor
    func testBlockingSubviewIsRemovedOnStop() {
        // Given
        let targetView = UIView()
        sut = .init(view: targetView)

        // When
        sut.start()
        sut.stop()

        // Then
        XCTAssertTrue(targetView.subviews.isEmpty, "subviews have not been cleaned up")
    }

    @MainActor
    func testSubsequentStopsAreIgnored() {
        // Given
        let targetView = UIView()
        sut = .init(view: targetView)

        // When
        sut.start()
        sut.stop()
        sut.stop()

        // Then
        XCTAssertTrue(targetView.subviews.isEmpty, "subviews have not been cleaned up")
    }

    @MainActor
    func testStopWithoutStart() {
        // Given
        let targetView = UIView()
        sut = .init(view: targetView)

        // When
        sut.stop()

        // Then
        XCTAssertTrue(targetView.subviews.isEmpty, "subviews have not been cleaned up")
    }

    @MainActor
    func testTargetViewCanBeDealocated() {
        // Given
        weak var weakTargetView: UIView?
        var targetView = UIView()
        sut = .init(view: targetView)
        weakTargetView = targetView

        // When
        targetView = .init()

        // Then
        XCTAssertNil(weakTargetView)

        // ensure these methods don't crash
        sut.start()
        sut.stop()
    }

    @MainActor
    func testViewIsNotCleanedUpAfterFirstIndicatorStop() {
        // Given
        let targetView = UIView()
        let indicators = [SUT(view: targetView), SUT(view: targetView)]
        indicators.forEach { sut in sut.start() }

        // When
        indicators[0].stop()

        // Then
        XCTAssertFalse(targetView.subviews.isEmpty, "subviews have been cleaned up")
    }

    @MainActor
    func testViewIsCleanedUpOnSingleIndicatorDealocation() {
        // Given
        let targetView = UIView()

        // When
        SUT(view: targetView).start()

        // Then
        wait(forConditionToBeTrue: targetView.subviews.isEmpty, timeout: 5)
    }

    @MainActor
    func testViewIsNotCleanedUpAfterFirstIndicatorDealocation() {
        // Given
        let targetView = UIView()
        var indicators = [SUT(view: targetView), SUT(view: targetView)]
        indicators.forEach { sut in sut.start() }

        // When
        indicators.remove(at: 0)

        // Then
        XCTAssertFalse(targetView.subviews.isEmpty, "subviews have been cleaned up")
    }

    @MainActor
    func testViewIsCleanedUpAfterLastIndicatorDealocation() {
        // Given
        let targetView = UIView()
        var indicators = [SUT(view: targetView), SUT(view: targetView)]
        indicators.forEach { sut in sut.start() }

        // When
        indicators.removeAll()

        // Then
        wait(forConditionToBeTrue: targetView.subviews.isEmpty, timeout: 5)
    }
}

extension BlockingActivityIndicator {
    fileprivate convenience init(view: UIView) {
        self.init(
            view: view,
            accessibilityAnnouncement: .none
        )
    }
}

// TODO: [WPB-10368] remove this temporary extension once XCTestCase+waitForPredicate.swift has been moved to a Swift package and is accessible from WireUI

extension XCTestCase {
    fileprivate func wait(
        forConditionToBeTrue predicate: @escaping @autoclosure () -> Bool,
        timeout seconds: TimeInterval
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: .init { _, _ in predicate() },
            object: .none
        )
        wait(for: [expectation], timeout: seconds)
    }
}

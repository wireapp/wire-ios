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
import WireReusableUIComponents
import WireUITesting
import XCTest

@testable import Wire

// MARK: - MockLoadingViewController

final class MockLoadingViewController: SpinnerCapableViewController {
    var dismissSpinner: SpinnerCompletion?
    let accessibilityAnnouncement = L10n.Localizable.General.loading
}

// MARK: - LoadingViewControllerTests

final class LoadingViewControllerTests: XCTestCase {

    // MARK: - Properties

    var sut: MockLoadingViewController!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        sut = MockLoadingViewController()
        sut.view.backgroundColor = .white
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatItShowsLoadingIndicator() {
        // GIVEN && WHEN
        sut.isLoadingViewVisible = true

        // THEN
        XCTAssert(sut.isLoadingViewVisible)
        verifyInAllDeviceSizes(matching: sut)
    }

    func testThatItDismissesLoadingIndicator() {
        // GIVEN && WHEN
        sut.isLoadingViewVisible = true
        sut.isLoadingViewVisible = false

        // THEN
        XCTAssertFalse(sut.isLoadingViewVisible)
        snapshotHelper.verify(matching: sut)
    }

    func testThatItShowsLoadingIndicatorWithSubtitle() {
        // GIVEN && WHEN
        sut.showLoadingView(title: "RESTORING…")

        // THEN
        verifyInAllDeviceSizes(matching: sut)
    }

}

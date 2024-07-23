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

import WireUITesting
import WireReusableUIComponents
import XCTest

@testable import Wire

// MARK: - MockLoadingViewController

// TODO: remove
final class MockLoadingViewController: UIViewController, SpinnerCapable {
    var dismissSpinner: (() -> Void)?
}

// MARK: - LoadingViewControllerTests

final class LoadingViewControllerTests: XCTestCase {

    // MARK: - Properties

    private var viewController: UIViewController!
    private var sut: BlockingActivityIndicator!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() async throws {
        await MainActor.run {

            viewController = UIViewController()
            viewController.view.backgroundColor = .white

            sut = .init(view: viewController.view)
            snapshotHelper = SnapshotHelper()
        }
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    @MainActor
    func testThatItShowsLoadingIndicator() {

        // When
        sut.start()

        // Then
        verifyInAllDeviceSizes(matching: viewController)
    }

    @MainActor
    func testThatItDismissesLoadingIndicator() {

        // Given
        sut.start()

        // When
        sut.stop()

        // Then
        verifyInAllDeviceSizes(matching: viewController)
    }

    @MainActor
    func testThatItShowsLoadingIndicatorWithSubtitle() {

        // Given
        let viewController = MockLoadingViewController()
        viewController.view.backgroundColor = .white

        // When
        viewController.showLoadingView(title: "RESTORING…")

        // Then
        verifyInAllDeviceSizes(matching: viewController)
    }
}

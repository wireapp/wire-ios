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
import XCTest

@testable import WireReusableUIComponents

final class BlockingActivityIndicatorSnapshotTests: XCTestCase {

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
            snapshotHelper = .init()
                .withSnapshotDirectory(relativeTo: #file)
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
        snapshotHelper.verify(matching: viewController)
    }

    @MainActor
    func testThatItShowsLoadingIndicatorWithSubtitle() {

        // When
        sut.start(text: "RESTORING…")

        // Then
        verifyInAllDeviceSizes(matching: viewController)
    }
}

// TODO: [WPB-10368] remove this temporary extension once XCTestCase+SnapshotTesting and XCTestCase+waitForPredicate.swift has been moved to a Swift package and is accessible from WireUI

private extension XCTestCase {

    func verifyInAllDeviceSizes(
        matching value: UIViewController,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        fatalError("TODO")
        /*
        let allDevices = XCTestCase.phoneConfigNames().merging(XCTestCase.padConfigNames) { current, _ in current }

        for (config, name) in allDevices {
            if let deviceMockable = value as? DeviceMockable {
                (deviceMockable.device as? MockDevice)?.userInterfaceIdiom = config.traits.userInterfaceIdiom
            }

            verify(
                matching: value,
                as: .image(on: config, precision: precision, perceptualPrecision: perceptualPrecision),
                named: name,
                file: file,
                testName: testName,
                line: line
            )
        }
         */
    }

    func wait(
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

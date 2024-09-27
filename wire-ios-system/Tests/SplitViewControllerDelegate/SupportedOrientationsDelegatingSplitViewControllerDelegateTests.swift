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
@testable import WireSystem

// MARK: - SupportedOrientationsDelegatingSplitViewControllerDelegateTests

final class SupportedOrientationsDelegatingSplitViewControllerDelegateTests: XCTestCase {
    private var sut: SupportedOrientationsDelegatingSplitViewControllerDelegate!

    override func setUp() async throws {
        sut = await MainActor.run { .init() }
    }

    override func tearDown() {
        sut = nil
    }

    @MainActor
    func testAllOrientationsSupported() {
        // Given
        let splitViewController = UISplitViewController(style: .doubleColumn)
        splitViewController.setViewController(ViewController(), for: .primary)
        splitViewController.setViewController(ViewController(), for: .secondary)

        // When
        let result = sut.splitViewControllerSupportedInterfaceOrientations(splitViewController)

        // Then
        XCTAssertEqual(result, .all)
    }

    @MainActor
    func testOnlyUpsideDownSupported() {
        // Given
        let splitViewController = UISplitViewController(style: .tripleColumn)
        splitViewController.setViewController(ViewController([.portrait, .portraitUpsideDown]), for: .primary)
        splitViewController.setViewController(
            ViewController([.landscapeLeft, .portraitUpsideDown]),
            for: .supplementary
        )
        splitViewController.setViewController(ViewController([.landscapeRight, .portraitUpsideDown]), for: .secondary)

        // When
        let result = sut.splitViewControllerSupportedInterfaceOrientations(splitViewController)

        // Then
        XCTAssertEqual(result, .portraitUpsideDown)
    }

    @MainActor
    func testAllSupportedWhenNoViewControllers() {
        // Given
        let splitViewController = UISplitViewController(style: .tripleColumn)

        // When
        let result = sut.splitViewControllerSupportedInterfaceOrientations(splitViewController)

        // Then
        XCTAssertEqual(result, .all)
    }

    @MainActor
    func testDelegateIsSet() {
        // Given
        let splitViewController = UISplitViewController(style: .tripleColumn)

        // When
        sut.setAsDelegateAndNontomicRetainedAssociatedObject(splitViewController)

        // Then
        XCTAssert(splitViewController.delegate === sut)
    }

    @MainActor
    func testDelegateIsRetained() {
        // Given
        let splitViewController = UISplitViewController(style: .tripleColumn)

        // When
        sut.setAsDelegateAndNontomicRetainedAssociatedObject(splitViewController)
        weak var weakSut = sut
        sut = nil

        // Then
        withExtendedLifetime(splitViewController) {
            XCTAssertNotNil(weakSut)
        }
    }
}

// MARK: - ViewController

private final class ViewController: UIViewController {
    private let interfaceOrientations: UIInterfaceOrientationMask
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { interfaceOrientations }

    init(_ interfaceOrientations: UIInterfaceOrientationMask = .all) {
        self.interfaceOrientations = interfaceOrientations
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

// MARK: - SupportedOrientationsDelegatingSplitViewControllerDelegate + Sendable

extension SupportedOrientationsDelegatingSplitViewControllerDelegate: Sendable {}

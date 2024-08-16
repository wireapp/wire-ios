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
        let result = splitViewController.withOverridenIsCollapsed(false) {
            sut.splitViewControllerSupportedInterfaceOrientations(splitViewController)
        }

        // Then
        XCTAssertEqual(result, .all)
    }

    @MainActor
    func testOnlyUpsideDownSupported() {

        // Given
        let splitViewController = UISplitViewController(style: .tripleColumn)
        splitViewController.setViewController(ViewController([.portrait, .portraitUpsideDown]), for: .primary)
        splitViewController.setViewController(ViewController([.landscapeLeft, .portraitUpsideDown]), for: .supplementary)
        splitViewController.setViewController(ViewController([.landscapeRight, .portraitUpsideDown]), for: .secondary)

        // When
        let result = splitViewController.withOverridenIsCollapsed(false) {
            sut.splitViewControllerSupportedInterfaceOrientations(splitViewController)
        }

        // Then
        XCTAssertEqual(result, .portraitUpsideDown)
    }

    @MainActor
    func testAllButUpsideDownSupported() {

        // Given
        let splitViewController = UISplitViewController(style: .doubleColumn)
        splitViewController.setViewController(ViewController([.portrait, .portraitUpsideDown]), for: .primary)
        splitViewController.setViewController(ViewController([.landscapeRight, .portraitUpsideDown]), for: .secondary)

        // When
        let result = splitViewController.withOverridenIsCollapsed(false) {
            sut.splitViewControllerSupportedInterfaceOrientations(splitViewController)
        }

        // Then
        XCTAssertEqual(result, .portraitUpsideDown)
    }

    @MainActor
    func testAllSupportedWhenNoViewControllersAndCollapsed() {

        // Given
        let splitViewController = UISplitViewController(style: .tripleColumn)

        // When
        let result = splitViewController.withOverridenIsCollapsed(true) {
            sut.splitViewControllerSupportedInterfaceOrientations(splitViewController)
        }

        // Then
        XCTAssertEqual(result, .all)
    }

    @MainActor
    func testAllSupportedWhenNoViewControllersAndNotCollapsed() {

        // Given
        let splitViewController = UISplitViewController(style: .tripleColumn)

        // When
        let result = splitViewController.withOverridenIsCollapsed(false) {
            sut.splitViewControllerSupportedInterfaceOrientations(splitViewController)
        }

        // Then
        XCTAssertEqual(result, .all)
    }
}

// MARK: - ViewController

private final class ViewController: UIViewController {

    var interfaceOrientations: UIInterfaceOrientationMask

    init(_ interfaceOrientations: UIInterfaceOrientationMask = .all) {
        self.interfaceOrientations = interfaceOrientations
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        interfaceOrientations
    }
}

extension SupportedOrientationsDelegatingSplitViewControllerDelegate: Sendable {}

// MARK: - Swizzle IsCollapsed

private extension UISplitViewController {

    private var overridenIsCollapsed: Bool? {
        get { objc_getAssociatedObject(self, &overridenIsCollapsedKey) as? Bool }
        set { objc_setAssociatedObject(self, &overridenIsCollapsedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    @objc var swizzledIsCollapsed: Bool {
        overridenIsCollapsed!
    }

    func withOverridenIsCollapsed<T>(_ isCollapsed: Bool, perform: () -> T) -> T {

        let isCollapsedSelector = #selector(getter: UISplitViewController.isCollapsed)
        let isCollapsedGetter = class_getInstanceMethod(UISplitViewController.self, isCollapsedSelector)!

        let swizzledIsCollapsedSelector = #selector(getter: UISplitViewController.swizzledIsCollapsed)
        let swizzledIsCollapsedGetter = class_getInstanceMethod(UISplitViewController.self, swizzledIsCollapsedSelector)!

        method_exchangeImplementations(isCollapsedGetter, swizzledIsCollapsedGetter)
        defer { method_exchangeImplementations(isCollapsedGetter, swizzledIsCollapsedGetter) }

        overridenIsCollapsed = isCollapsed
        defer { overridenIsCollapsed = nil }

        return perform()
    }
}

private nonisolated(unsafe) var overridenIsCollapsedKey = 0

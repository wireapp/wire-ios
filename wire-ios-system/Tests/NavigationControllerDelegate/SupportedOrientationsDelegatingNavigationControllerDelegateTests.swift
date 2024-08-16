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

final class SupportedOrientationsDelegatingNavigationControllerDelegateTests: XCTestCase {

    private var sut: SupportedOrientationsDelegatingNavigationControllerDelegate!

    override func setUp() async throws {
        sut = await MainActor.run { .init() }
    }

    override func tearDown() {
        sut = nil
    }

    @MainActor
    func testAllOrientationsSupported() {

        // Given
        let navigationViewController = UINavigationController(rootViewController: ViewController())

        // When
        let result = sut.navigationControllerSupportedInterfaceOrientations(navigationViewController)

        // Then
        XCTAssertEqual(result, .all)
    }
}

// MARK: - ViewController

private final class ViewController: UIViewController {

    var interfaceOrientations: UIInterfaceOrientationMask

    init(interfaceOrientations: UIInterfaceOrientationMask = .all) {
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

extension SupportedOrientationsDelegatingNavigationControllerDelegate: Sendable {}

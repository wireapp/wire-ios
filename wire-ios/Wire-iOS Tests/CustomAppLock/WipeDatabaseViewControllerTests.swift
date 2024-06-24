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
import XCTest

@testable import Wire

final class WipeDatabaseViewControllerTests: XCTestCase {

    // MARK: - Properties

    private var sut: WipeDatabaseViewController!
    private let helper = SnapshotHelper()

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        FontScheme.configure(with: .large)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testForAllScreenSizes() {
        sut = WipeDatabaseViewController()
        verifyInAllDeviceSizes(matching: sut)
    }

    func testForDarkTheme() {
        let createSut: () -> UIViewController = {
            let navigationController = UIViewController().wrapInNavigationController(navigationBarClass: TransparentNavigationBar.self)
            navigationController.pushViewController(WipeDatabaseViewController(), animated: false)

            return navigationController
        }

        helper.verifyInDarkScheme(createSut: createSut)
    }

    func testForConfirmAlert() throws {
        // GIVEN
        sut = WipeDatabaseViewController()

        // WHEN
        sut.presentConfirmAlert()

        // THEN
        try verify(matching: sut.confirmController!.alertController)
    }
}

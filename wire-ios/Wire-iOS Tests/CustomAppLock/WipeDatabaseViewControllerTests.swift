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

import WireTestingPackage
import XCTest

@testable import Wire

final class WipeDatabaseViewControllerTests: XCTestCase {

    // MARK: - Properties

    private var sut: WipeDatabaseViewController!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testForAllScreenSizes() {
        sut = WipeDatabaseViewController()
        snapshotHelper.verifyInAllDeviceSizes(matching: sut)
    }

    func testWipeDatabaseViewController() {
        let createSut: () -> UIViewController = {
            let navigationController = UIViewController().wrapInNavigationController(navigationBarClass: TransparentNavigationBar.self)
            navigationController.pushViewController(WipeDatabaseViewController(), animated: false)
            return navigationController
        }

        let sut = createSut()
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: sut,
                named: "DarkTheme",
                file: #file,
                testName: #function,
                line: #line
            )
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

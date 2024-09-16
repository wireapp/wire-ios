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

class AppLockChangeWarningViewControllerTests: XCTestCase {

    // MARK: - Properties

    private var userSession: UserSessionMock!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        userSession = UserSessionMock()
    }

    override func tearDown() {
        snapshotHelper = nil
        userSession = nil
        super.tearDown()
    }

    func testWarningThatAppLockIsActive() {
        let createSut: () -> UIViewController = {
            return AppLockChangeWarningViewController(
                isAppLockActive: true,
                userSession: self.userSession
            )
        }

        let sut = createSut()

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
            matching: sut,
            named: "LightTheme",
            file: #file,
            testName: #function,
            line: #line
        )

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

    func testWarningThatAppLockIsNotActive() {
        let createSut: () -> UIViewController = {
            return AppLockChangeWarningViewController(
                isAppLockActive: false,
                userSession: self.userSession
            )
        }

        let sut = createSut()

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
            matching: sut,
            named: "LightTheme",
            file: #file,
            testName: #function,
            line: #line
        )

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

}

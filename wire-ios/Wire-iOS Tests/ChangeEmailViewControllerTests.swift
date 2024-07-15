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
import WireUITesting
import XCTest

@testable import Wire

final class ChangeEmailViewControllerTests: XCTestCase {

    private var userSession: UserSession!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
    }

    override func tearDown() {
        snapshotHelper = nil
        userSession = nil
        super.tearDown()
    }

    private func createSut(emailAddress: String?) -> UIViewController {
        let mockUser = MockUserType.createSelfUser(name: "User")
        userSession = UserSessionMock(mockUser: mockUser)
        mockUser.emailAddress = emailAddress

        let sut = ChangeEmailViewController(user: mockUser, userSession: userSession, useTypeIntrinsicSizeTableView: true)
        let viewController = sut.wrapInNavigationController(navigationControllerClass: NavigationController.self)

        return viewController
    }

    func testForChangingExistingEmail() {
        // GIVEN & WHEN
        let viewController = createSut(emailAddress: "user@example.com")

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: viewController,
                named: "DarkTheme",
                file: #file,
                testName: #function,
                line: #line
            )
    }

    func testForAddingEmail() {
        // GIVEN & WHEN
        let viewController = createSut(emailAddress: nil)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: viewController,
                named: "DarkTheme",
                file: #file,
                testName: #function,
                line: #line
            )
    }

}

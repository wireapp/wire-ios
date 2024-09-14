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

import WireSyncEngineSupport
import WireTestingPackage
import XCTest

@testable import Wire

final class ChangeEmailViewControllerSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var userSession: UserSessionMock!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        userSession = nil
        super.tearDown()
    }

    // MARK: - Helper method

    private func createSut(emailAddress: String?) -> UIViewController {
        let mockUser = MockUserType.createSelfUser(name: "User")
        let userProfile = MockUserProfile()
        userSession = UserSessionMock(mockUser: mockUser)
        userSession.userProfile = userProfile
        mockUser.emailAddress = emailAddress

        userProfile.addObserver_MockMethod = { _ in }

        let sut = ChangeEmailViewController(user: mockUser, userSession: userSession)
        let viewController = sut.wrapInNavigationController()

        return viewController
    }

    // MARK: Snapshot Tests

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

}

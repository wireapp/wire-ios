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

import WireDesign
import WireTestingPackage
import XCTest
@testable import Wire

// MARK: - MockAddressBookHelper

final class MockAddressBookHelper: NSObject, AddressBookHelperProtocol {
    static var sharedHelper: AddressBookHelperProtocol = MockAddressBookHelper()

    var isAddressBookAccessDisabled = false

    var accessStatusDidChangeToGranted = true

    var isAddressBookAccessGranted: Bool {
        false
    }

    var isAddressBookAccessUnknown: Bool {
        true
    }

    func persistCurrentAccessStatus() {}

    func requestPermissions(_ callback: ((Bool) -> Void)?) {
        // no-op
        callback?(false)
    }
}

// MARK: - StartUIViewControllerSnapshotTests

final class StartUIViewControllerSnapshotTests: CoreDataSnapshotTestCase {
    // MARK: Internal

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        mockMainCoordinator = .init()
        snapshotHelper = SnapshotHelper()
        mockAddressBookHelper = MockAddressBookHelper()
        SelfUser.provider = selfUserProvider
        userSession = UserSessionMock()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        mockAddressBookHelper = nil
        SelfUser.provider = nil
        userSession = nil
        mockMainCoordinator = nil

        super.tearDown()
    }

    // MARK: - Helper Method

    func setupSut() {
        sut = StartUIViewController(
            addressBookHelperType: MockAddressBookHelper.self,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator
        )
        sut.view.backgroundColor = SemanticColors.View.backgroundDefault

        // Set the size for the SUT to match iPhone 14 dimensions
        let screenSize = CGSize(width: 390, height: 844)
        sut.view.frame = CGRect(origin: .zero, size: screenSize)
    }

    // MARK: - Snapshot Tests

    func testForWrappedInNavigationViewController() {
        nonTeamTest {
            setupSut()

            let navigationController = UIViewController()
                .wrapInNavigationController(navigationControllerClass: NavigationController.self)

            navigationController.pushViewController(sut, animated: false)

            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: sut.view)
        }
    }

    func testForNoContact() {
        nonTeamTest {
            setupSut()

            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: sut.view)
        }
    }

    /// has create group and create guest room rows
    func testForNoContactWhenSelfIsTeamMember() {
        teamTest {
            setupSut()

            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: sut.view)
        }
    }

    /// has no create group and create guest room rows, and no group selector tab
    func testForNoContactWhenSelfIsPartner() {
        teamTest {
            selfUser.membership?.setTeamRole(.partner)

            setupSut()

            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: sut.view)
        }
    }

    // MARK: Private

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var mockMainCoordinator: MockMainCoordinator!
    private var sut: StartUIViewController!
    private var mockAddressBookHelper: MockAddressBookHelper!
    private var userSession: UserSessionMock!
}

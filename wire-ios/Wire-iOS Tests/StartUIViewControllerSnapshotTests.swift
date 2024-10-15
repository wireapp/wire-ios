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
import WireMainNavigationUI
import WireTestingPackage
import XCTest

@testable import Wire

final class MockAddressBookHelper: NSObject, AddressBookHelperProtocol {

    var isAddressBookAccessDisabled: Bool = false

    var accessStatusDidChangeToGranted: Bool = true

    static var sharedHelper: AddressBookHelperProtocol = MockAddressBookHelper()

    func persistCurrentAccessStatus() {

    }

    var isAddressBookAccessGranted: Bool {
        return false
    }

    var isAddressBookAccessUnknown: Bool {
        return true
    }

    func requestPermissions(_ callback: ((Bool) -> Void)?) {
        // no-op
        callback?(false)
    }
}

final class StartUIViewControllerSnapshotTests: CoreDataSnapshotTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var mockMainCoordinator: AnyMainCoordinator<Wire.MainCoordinatorDependencies>!
    private var sut: StartUIViewController!
    private var mockAddressBookHelper: MockAddressBookHelper!
    private var userSession: UserSessionMock!

    // MARK: - setUp

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        mockMainCoordinator = .init(mainCoordinator: MockMainCoordinator())
    }

    override func setUp() {
        super.setUp()
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

    // MARK: - Helper Methods

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

    func setupNavigationController() -> UINavigationController {
        setupSut()
        let navigationController = UINavigationController(rootViewController: sut)
        navigationController.view.backgroundColor = SemanticColors.View.backgroundDefault
        navigationController.overrideUserInterfaceStyle = .dark
        return navigationController
    }

    // MARK: - Snapshot Tests

    func testStartUIViewControllerWrappedInNavigationController() {
        nonTeamTest {
            let navigationController = setupNavigationController()
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: navigationController.view)
        }
    }

    func testStartUIViewControllerNoContact() {
        nonTeamTest {
            let navigationController = setupNavigationController()
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: navigationController.view)
        }
    }

    func testStartUIViewControllerNoContactWhenSelfIsTeamMember() {
        teamTest {
            let navigationController = setupNavigationController()
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: navigationController.view)
        }
    }

    func testStartUIViewControllerNoContactWhenSelfIsPartner() {
        teamTest {
            selfUser.membership?.setTeamRole(.partner)
            let navigationController = setupNavigationController()
            snapshotHelper
                .withUserInterfaceStyle(.dark)
                .verify(matching: navigationController.view)
        }
    }
}

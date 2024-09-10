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

final class ClientListViewControllerTests: XCTestCase, CoreDataFixtureTestHelper {

    // MARK: - Properties

    private var sut: ClientListViewController!
    private var mockUser: MockUserType!
    private var client: UserClient!
    private var selfClient: UserClient!
    private weak var clientRemovalObserver: ClientRemovalObserver!
    private var snapshotHelper: SnapshotHelper!
    var coreDataFixture: CoreDataFixture!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        coreDataFixture = CoreDataFixture()

        mockUser = SwiftMockLoader.mockUsers().first
        selfClient = mockUserClient()
        client = mockUserClient()
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        mockUser = nil
        client = nil
        selfClient = nil

        coreDataFixture = nil

        super.tearDown()
    }

    // MARK: - Helper method

    /// Prepare SUT for snapshot tests
    ///
    /// - Parameters:
    /// - numberOfClients: number of clients other than self device. Default: display 3 cells, to show footer in same screen
    @MainActor
    func prepareSut(numberOfClients: Int = 3) {
        sut = ClientListViewController(
            clientsList: Array(
                repeating: mockUserClient(),
                count: numberOfClients
            ),
            selfClient: selfClient,
            credentials: nil,
            detailedView: true,
            showTemporary: true
        )
        sut.activityIndicator.stop()
    }

    // MARK: - Unit Tests

    @MainActor
    func testThatObserverIsNonRetained() {
        prepareSut()

        let emailCredentials = UserEmailCredentials(email: "foo@bar.com", password: "12345678")
        sut.deleteUserClient(client, credentials: emailCredentials)

        clientRemovalObserver = sut.removalObserver
        XCTAssertNotNil(clientRemovalObserver)

        sut.viewDidDisappear(false)
        XCTAssertNil(clientRemovalObserver)
    }

    // MARK: - Snapshot Tests

    @MainActor
    func testForLightTheme() {
        prepareSut()
        snapshotHelper.verify(matching: sut)
    }

    @MainActor
    func testForDarkTheme() {
        prepareSut()

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    @MainActor
    func testForLightThemeWrappedInNavigationController() {
        prepareSut()
        let navWrapperController = sut.wrapInNavigationController()
        navWrapperController.navigationBar.tintColor = UIColor.accent()

        snapshotHelper.verify(matching: navWrapperController)
    }

    @MainActor
    func testForOneDeviceWithNoEditButton() {
        prepareSut(numberOfClients: 0)
        let navWrapperController = sut.wrapInNavigationController()

        snapshotHelper.verify(matching: navWrapperController)
    }

    @MainActor
    func testForOneDeviceWithBackButtonAndNoEditButton() {
        prepareSut(numberOfClients: 0)
        let mockRootViewController = UIViewController()
        let navWrapperController = mockRootViewController.wrapInNavigationController()
        navWrapperController.pushViewController(sut, animated: false)

        snapshotHelper.verify(matching: navWrapperController)
    }

    @MainActor
    func testForEditMode() {
        prepareSut()
        let navWrapperController = sut.wrapInNavigationController()
        navWrapperController.navigationBar.tintColor = UIColor.accent()

        sut.setEditingState(true)

        snapshotHelper.verify(matching: navWrapperController)
    }
}

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
import WireTestingPackage
import XCTest
@testable import Wire

// MARK: - MockServicesOptionsViewModelConfiguration

final class MockServicesOptionsViewModelConfiguration: ConversationServicesOptionsViewModelConfiguration {
    // MARK: Properties

    typealias SetHandler = (Bool, (Result<Void, Error>) -> Void) -> Void
    var allowServices: Bool
    var allowServicesChangedHandler: ((Bool) -> Void)?
    var areServicePresent = true
    var setAllowServices: SetHandler?

    // MARK: Init

    init(allowServices: Bool, setAllowServices: SetHandler? = nil) {
        self.allowServices = allowServices
        self.setAllowServices = setAllowServices
    }

    func setAllowServices(_ allowServices: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        setAllowServices?(allowServices, completion)
    }
}

// MARK: - ConversationServicesOptionsViewControllerTests

final class ConversationServicesOptionsViewControllerTests: XCTestCase {
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
    }

    override func tearDown() {
        snapshotHelper = nil
        super.tearDown()
    }

    // MARK: Renders Services Screen When Services are either Allowed or not allowed

    func testThatItRendersServicesScreenWhenServicesAreNotAllowed() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowServices: false)
        let viewModel = ConversationServicesOptionsViewModel(configuration: config)
        let sut = ConversationServicesOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersServicesScreenWhenServicesAreNotAllowed_DarkTheme() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowServices: false)
        let viewModel = ConversationServicesOptionsViewModel(configuration: config)
        let sut = ConversationServicesOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testThatItRendersServicesScreenWhenServicesAreAllowed() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowServices: true)
        let viewModel = ConversationServicesOptionsViewModel(configuration: config)
        let sut = ConversationServicesOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersServicesScreenWhenServicesAreAllowed_DarkTheme() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowServices: true)
        let viewModel = ConversationServicesOptionsViewModel(configuration: config)
        let sut = ConversationServicesOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    // MARK: Renders Services Screen when a change is occured

    func testThatItUpdatesServicesScreenWhenItReceivesAChange() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowServices: false)
        let viewModel = ConversationServicesOptionsViewModel(configuration: config)
        let sut = ConversationServicesOptionsViewController(viewModel: viewModel)

        // Verify that the toggle should be off.
        snapshotHelper.verify(matching: sut)

        // WHEN
        config.allowServices = true
        // confusingly, the value passed here has no affect
        config.allowServicesChangedHandler?(true)

        // Then, verify the toggle is now on.
        snapshotHelper.verify(matching: sut)
    }

    // MARK: Renders Group's Title in Services Screen

    func testThatItRendersItsGroupTitle() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowServices: true)
        let viewModel = ConversationServicesOptionsViewModel(configuration: config)
        let sut = ConversationServicesOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper.verify(matching: sut.wrapInNavigationController())
    }

    // MARK: Renders different kind of alerts

    func testThatItRendersRemoveServicesConfirmationAlert() {
        // WHEN
        let sut = UIAlertController.confirmRemovingServices { _ in }
        // THEN
        XCTAssertNotNil(sut)
    }

    func testThatNoAlertIsShowIfNoServiceIsPresent() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowServices: true)
        config.areServicePresent = false

        let viewModel = ConversationServicesOptionsViewModel(configuration: config)

        // Show the alert
        let sut = viewModel.setAllowServices(false, sender: .init())

        // THEN
        XCTAssertNil(sut)
    }

    func testThatItRendersRemoveServicesWarning() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowServices: true)
        let viewModel = ConversationServicesOptionsViewModel(configuration: config)

        // For ConversationServicesOptionsViewModel's delegate
        let viewController = ConversationServicesOptionsViewController(viewModel: viewModel)

        // Show the alert
        let sut = viewModel.setAllowServices(false, sender: viewController.view.subviews[0])!

        // THEN
        XCTAssertNotNil(sut)
    }
}

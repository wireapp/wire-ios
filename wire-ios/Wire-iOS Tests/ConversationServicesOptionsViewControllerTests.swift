//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireDataModel
import WireTestingPackage
import XCTest

@testable import Wire

final class MockServicesOptionsViewModelConfiguration: ConversationServicesOptionsViewModelConfiguration {
    // MARK: Properties

    typealias SetHandler = (Bool, (Result<Void, Error>) -> Void) -> Void

    var messageProtocol: MessageProtocol = .proteus
    var areLegacyBotsAvailable = false
    var isAppsFeatureEnabled = true
    var allowApps: Bool
    var allowAppsChangedHandler: ((Bool) -> Void)?
    var areAppsPresent = true
    var setAllowApps: SetHandler?

    // MARK: Init

    init(allowApps: Bool, setAllowApps: SetHandler? = nil) {
        self.allowApps = allowApps
        self.setAllowApps = setAllowApps
    }

    func setAllowApps(_ allowApps: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        setAllowApps?(allowApps, completion)
    }

}

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
        let config = MockServicesOptionsViewModelConfiguration(allowApps: false)
        let viewModel = ConversationServicesOptionsViewModel(configuration: config)
        let sut = ConversationServicesOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersServicesScreenWhenServicesAreNotAllowed_DarkTheme() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowApps: false)
        let viewModel = ConversationServicesOptionsViewModel(configuration: config)
        let sut = ConversationServicesOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut)
    }

    func testThatItRendersServicesScreenWhenServicesAreAllowed() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowApps: true)
        let viewModel = ConversationServicesOptionsViewModel(configuration: config)
        let sut = ConversationServicesOptionsViewController(viewModel: viewModel)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItRendersServicesScreenWhenServicesAreAllowed_DarkTheme() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowApps: true)
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
        let config = MockServicesOptionsViewModelConfiguration(allowApps: false)
        let viewModel = ConversationServicesOptionsViewModel(configuration: config)
        let sut = ConversationServicesOptionsViewController(viewModel: viewModel)

        // Verify that the toggle should be off.
        snapshotHelper.verify(matching: sut)

        // WHEN
        config.allowApps = true
        // confusingly, the value passed here has no affect
        config.allowAppsChangedHandler?(true)

        // Then, verify the toggle is now on.
        snapshotHelper.verify(matching: sut)

    }

    // MARK: Renders Group's Title in Services Screen

    func testThatItRendersItsGroupTitle() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowApps: true)
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
        let config = MockServicesOptionsViewModelConfiguration(allowApps: true)
        config.areAppsPresent = false

        let sut = ConversationServicesOptionsViewModel(configuration: config)

        // THEN
        XCTAssertEqual(sut.actionForAllowAppsToggle(false), .setAllowApps(false))
    }

    func testThatItRendersRemoveServicesWarning() {
        // GIVEN
        let config = MockServicesOptionsViewModelConfiguration(allowApps: true)
        let sut = ConversationServicesOptionsViewModel(configuration: config)

        // THEN
        XCTAssertEqual(sut.actionForAllowAppsToggle(false), .confirmRemovingServices(false))
    }

    func testThatItReturnsNoActionWhenAllowAppsValueDoesNotChange() {
        let config = MockServicesOptionsViewModelConfiguration(allowApps: true)
        let sut = ConversationServicesOptionsViewModel(configuration: config)

        XCTAssertEqual(sut.actionForAllowAppsToggle(true), .none)
    }

    func testThatItReturnsSetAllowAppsAfterRemovingServicesConfirmation() {
        let config = MockServicesOptionsViewModelConfiguration(allowApps: true)
        let sut = ConversationServicesOptionsViewModel(configuration: config)

        XCTAssertEqual(
            sut.actionForRemovingServicesConfirmation(confirmed: true, allowApps: false),
            .setAllowApps(false)
        )
    }

    func testThatItReturnsNoActionWhenRemovingServicesIsCancelled() {
        let config = MockServicesOptionsViewModelConfiguration(allowApps: true)
        let sut = ConversationServicesOptionsViewModel(configuration: config)

        XCTAssertEqual(
            sut.actionForRemovingServicesConfirmation(confirmed: false, allowApps: false),
            .none
        )
    }

    func testThatItBuildsDisabledHintWhenAppsAreNotAvailable() {
        let config = MockServicesOptionsViewModelConfiguration(allowApps: false)
        config.messageProtocol = .proteus
        config.areLegacyBotsAvailable = false
        let sut = ConversationServicesOptionsViewModel(configuration: config)

        XCTAssertEqual(
            sut.state.rows,
            [
                .appsDisabledHint(
                    title: L10n.Localizable.Conversation.Create.AppsDisabled.title,
                    body: L10n.Localizable.Conversation.Create.AppsDisabled.message
                )
            ]
        )
    }

    func testThatItBuildsToggleWhenAppsAreAvailable() {
        let config = MockServicesOptionsViewModelConfiguration(allowApps: false)
        config.messageProtocol = .proteus
        config.areLegacyBotsAvailable = true
        let sut = ConversationServicesOptionsViewModel(configuration: config)

        XCTAssertEqual(
            sut.state.rows,
            [
                .allowAppsToggle(
                    .init(
                        title: L10n.Localizable.AppsOptions.AllowApps.title,
                        subtitle: L10n.Localizable.AppsOptions.AllowApps.subtitle,
                        accessibilityIdentifier: "toggle.guestoptions.allowapps",
                        titleAccessibilityIdentifier: "label.guestoptions.apps.description",
                        isEnabled: true,
                        isOn: false
                    )
                )
            ]
        )
    }
}

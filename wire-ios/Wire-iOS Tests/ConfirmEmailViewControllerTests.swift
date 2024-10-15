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
import WireSettingsUI

@testable import Wire

final class ConfirmEmailViewControllerTests: XCTestCase {

    // MARK: Properties

    private var sut: ConfirmEmailViewController!
    private var userSession: UserSessionMock!
    private var snapshotHelper: SnapshotHelper!
    private var settingsCoordinator: AnySettingsCoordinator!

    // MARK: setUp

    @MainActor
    override func setUp() async throws {
        snapshotHelper = SnapshotHelper()
        userSession = UserSessionMock()
        settingsCoordinator = .init(settingsCoordinator: MockSettingsCoordinator())
        sut = ConfirmEmailViewController(
            newEmail: "bill@wire.com",
            delegate: nil,
            userSession: userSession,
            useTypeIntrinsicSizeTableView: true,
            settingsCoordinator: settingsCoordinator
        )
        sut.overrideUserInterfaceStyle = .dark
    }

    // MARK: tearDown

    override func tearDown() {
        settingsCoordinator = nil
        snapshotHelper = nil
        userSession = nil
        sut = nil
    }

    // MARK: Snapshot Tests

    func testConfirmationSentToEmail_Dark() {
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: sut.view)
    }
}

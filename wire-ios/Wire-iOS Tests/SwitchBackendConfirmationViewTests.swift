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

final class SwitchBackendConfirmationViewTests: XCTestCase {

    private var snapshotHelper: SnapshotHelper_!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper_().withLayout(.device(config: .iPhone13))
    }

    override func tearDown() {
        snapshotHelper = nil
        super.tearDown()
    }

    private func createSUT() -> SwitchBackendConfirmationView {
        SwitchBackendConfirmationView(viewModel: SwitchBackendConfirmationViewModel(
            backendName: "Staging",
            backendURL: "www.staging.com",
            backendWSURL: "www.ws.staging.com",
            blacklistURL: "www.blacklist.staging.com",
            teamsURL: "www.teams.staging.com",
            accountsURL: "www.accounts.staging.com",
            websiteURL: "www.wire.com",
            didConfirm: { _ in }
        ))
    }

    func testLightUI() {
        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(matching: createSUT)
    }

    func testDarkUI() {
        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(matching: createSUT)
    }

}

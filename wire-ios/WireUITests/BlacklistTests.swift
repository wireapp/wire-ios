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

import XCTest

/// [core-messenger]
final class BlacklistTests: WireUITestCase {

    override func setUpWithError() throws {
        uiTestConfig.isBuildBlacklisted = true

        try super.setUpWithError()
    }

    /// [critical]
    @MainActor
    func testBlacklistAfterLogin__TC_9483() async throws {
        let user = try await UserHelper.default.createPersonalUser()
        _ = try app.loginUser(email: user.email, password: user.password)

        let blockerPage = try BlockerPage()

        XCTAssertTrue(
            blockerPage.clientObsoleteAlert.waitForExistence(timeout: 10),
            "Client obsolete alert did not appear"
        )
    }
}

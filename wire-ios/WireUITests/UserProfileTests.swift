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
final class UserProfileTests: WireUITestCase {

    @MainActor
    private func openTeamUserProfilePage() async throws -> UserProfilePage {
        let (teamOwner, _, _, _) = try await UserHelper.default.registerTeam(withMemberCount: 0)

        return try skipUiLogin(user: teamOwner)
            .openUserProfilePage()
    }

    @MainActor
    func testSetAvailabilityStatuses_TC_8935_8936_8937_8938() async throws {
        let userProfilePage = try await openTeamUserProfilePage()

        // Set status as available and verify.
        _ = userProfilePage
            .setUserStatus(.available)
            .verifyUserStatus(.available)

        // Set status as busy and verify.
        _ = userProfilePage
            .setUserStatus(.busy)
            .verifyUserStatus(.busy)

        // Set status as none and verify.
        _ = userProfilePage
            .setUserStatus(.none)
            .verifyUserStatus(.none)

        // Set status as away and verify.
        _ = userProfilePage
            .setUserStatus(.away)
            .verifyUserStatus(.away)
    }

}

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
    private func loginTeamOwner() async throws -> (ConversationsPage, UserInfo) {
        let (teamOwner, _, _, _) = try await UserHelper.default.registerTeam(withMemberCount: 0)

        let conversationsPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()

        return (conversationsPage, teamOwner)
    }

    @MainActor
    private func openTeamUserProfilePage() async throws -> (UserProfilePage, UserInfo) {
        let (conversationsPage, teamOwner) = try await loginTeamOwner()
        let userProfilePage = try conversationsPage.openUserProfilePage()

        return (userProfilePage, teamOwner)
    }

    @MainActor
    func testSetAvailabilityStatuses_TC_8935_8936_8937_8938() async throws {
        let (userProfilePage, _) = try await openTeamUserProfilePage()

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

    @MainActor
    func testUserProfileAttributes_TC_8811_8812_8815_8816() async throws {
        let (userProfilePage, teamOwner) = try await openTeamUserProfilePage()

        _ = userProfilePage
            .verifyName(teamOwner.name)
            .verifyUsername(teamOwner.username)
            .verifyUserStatus(.none) // default
            .verifyProfileQRCodeButton()
    }
}

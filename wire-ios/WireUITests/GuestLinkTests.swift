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
final class GuestLinkTests: WireUITestCase {

    @MainActor
    private func openGuestOptionsAsGroupAdmin() async throws -> GuestOptionsPage {
        let (teamOwner, _, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .group(UserGenerator.generateRandomConversationName())
        )

        return try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .openConversation()
            .openConversationDetails()
            .openGuestOptions()
    }

    @MainActor
    func testGroupAdminCanCreateGuestLinkWithoutAndWithPassword_TC_11832_11831() async throws {

        // GIVEN
        let guestOptionsPage = try await openGuestOptionsAsGroupAdmin()

        // WHEN
        guestOptionsPage
            .createLinkWithoutPassword()
            .assertLinkCreated(passwordSecured: false)
            .revokeLink()

        let updatedGuestOptionsPage = try guestOptionsPage
            .startCreatingLinkWithPassword()
            .generatePassword()
            .createLink()

        // THEN
        updatedGuestOptionsPage.assertLinkCreated(passwordSecured: true)
    }
}

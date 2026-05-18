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

final class SSOTests: WireUITestCase {

    private func registerTeamOwnerWithSSOEnabled() async throws -> UserInfo {
        let (_, teamOwner) = try await UserHelper.default.registerUserAsTeamOwner()
        let teamID = try XCTUnwrap(teamOwner.teamID, "teamOwner.teamID is nil")
        try await ssoHelper.enableSSOFeature(teamID: teamID)
        return teamOwner
    }

    @MainActor
    private func loginWithSSOCode(email: String, password: String, ssoCode: String) async throws -> FirstTimePage {
        try await WelcomePage()
            .enterSSOCode(ssoCode)
            .oktaLogin(email: email, password: password)
            .acceptFirstTimeAlert()
    }

    @MainActor
    func testSSOLoginWithSSOCodeAndNoResetPassword_TC_8966_TC_10850() async throws {
        // GIVEN
        let teamOwner = try await registerTeamOwnerWithSSOEnabled()
        let ssoMember = UserGenerator.generateUniqueUserInfo()
        let ssoUser = try await ssoHelper.createSSOUser(owner: teamOwner, ssoUser: ssoMember)
        let ssoCode = try ssoHelper.getSSOCode()

        // WHEN
        let accountSettingsPage = try await loginWithSSOCode(
            email: ssoUser.email,
            password: ssoUser.password,
            ssoCode: ssoCode
        )
        .acceptPopupOnTeamMemberSetup()
        .setUsername(ssoUser.username)
        .openSettings()
        .openAccountSettings()

        // THEN
        XCTAssertFalse(
            accountSettingsPage.resetPasswordButton.exists,
            "Reset password option is visible for SSO users"
        )
    }

    @MainActor
    func testSCIMManagedUserCannotChangeAccountFields_TC_10851() async throws {

        // GIVEN
        let teamOwner = try await registerTeamOwnerWithSSOEnabled()
        let scimMember = UserGenerator.generateUniqueUserInfo()
        let scimUser = try await ssoHelper.createSCIMManagedSSOUser(owner: teamOwner, ssoUser: scimMember)
        let ssoCode = try ssoHelper.getSSOCode()

        // WHEN
        let accountSettingsPage = try await loginWithSSOCode(
            email: scimUser.email,
            password: scimUser.password,
            ssoCode: ssoCode
        )
        .acceptPopup()
        .openSettings()
        .openAccountSettings()

        // THEN
        XCTAssertTrue(
            accountSettingsPage.nameFieldDisabled.exists,
            "name field editable, should be disabled"
        )

        XCTAssertTrue(
            accountSettingsPage.usernameFieldDisabled.exists,
            "username field editable, shold be disabled"
        )
    }
}

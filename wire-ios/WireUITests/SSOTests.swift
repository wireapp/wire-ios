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
final class SSOTests: WireUITestCase {

    private func registerTeamOwnerWithSSOEnabled() async throws -> UserInfo {
        let (_, teamOwner) = try await UserHelper.default.registerUserAsTeamOwner()
        let teamID = try XCTUnwrap(teamOwner.teamID, "teamOwner.teamID is nil")
        try await ssoHelper.enableSSOFeature(teamID: teamID)
        return teamOwner
    }

    private func createSSOUser() async throws -> UserInfo {
        let teamOwner = try await registerTeamOwnerWithSSOEnabled()
        let ssoMember = UserGenerator.generateUniqueUserInfo()
        return try await ssoHelper.createSSOUser(owner: teamOwner, ssoUser: ssoMember)
    }

    @MainActor
    private func loginWithSSOCode(email: String, password: String, ssoCode: String) async throws -> FirstTimePage {
        try await WelcomePage()
            .enterSSOCode(ssoCode)
            .ssoWebLogin(email: email, password: password)
            .acceptFirstTimeAlert()
    }

    /// [critical]
    @MainActor
    func testSSOLoginWithSSOCodeAndNoResetPassword_TC_8966_TC_10850() async throws {
        // Skipped: Okta license removed, so the SSO IdP backing this test is no longer available.
        // Re-enable once a replacement SSO provider is configured.
        throw XCTSkip("Okta license removed - SSO IdP unavailable")

        // GIVEN
        let ssoUser = try await createSSOUser()
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

    /// [critical]
    @MainActor
    func testReloginSSO_TC_8970() async throws {
        // Skipped: Okta license removed, so the SSO IdP backing this test is no longer available.
        // Re-enable once a replacement SSO provider is configured.
        throw XCTSkip("Okta license removed - SSO IdP unavailable")

        // GIVEN
        let ssoUser = try await createSSOUser()
        let ssoCode = try ssoHelper.getSSOCode()

        // WHEN
        _ = try await loginWithSSOCode(
            email: ssoUser.email,
            password: ssoUser.password,
            ssoCode: ssoCode
        )
        .acceptPopupOnTeamMemberSetup()
        .setUsername(ssoUser.username)
        .openSettings()
        .openAccountSettings()
        .logoutWithoutPassword()

        // AND Perform Relogin
        let conversationsPage = try await loginWithSSOCode(
            email: ssoUser.email,
            password: ssoUser.password,
            ssoCode: ssoCode
        )
        .acceptPopup()

        // THEN
        XCTAssertTrue(
            conversationsPage.pageMainElement.exists,
            "Conversations page did not appear after SSO relogin"
        )
    }

    @MainActor
    func testSCIMManagedUserCannotChangeAccountFields_TC_10851() async throws {
        // Skipped: Okta license removed, so the SSO IdP backing this test is no longer available.
        // Re-enable once a replacement SSO provider is configured.
        throw XCTSkip("Okta license removed - SSO IdP unavailable")

        // GIVEN
        let teamOwner = try await registerTeamOwnerWithSSOEnabled()
        let scimUser = try await ssoHelper.createSCIMManagedSSOUser(
            owner: teamOwner,
            ssoUser: UserGenerator.generateUniqueUserInfo()
        )
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

    /// [critical]
    @MainActor
    func testSSOLoginWithClaimedDomain_TC_8967() async throws {

        // GIVEN
        let environmentVariables = try EnvironmentVariables()

        // WHEN
        _ = try await WelcomePage()
            .enterSSOCode(environmentVariables.ssoClaimedUserEmail)
            .ssoWebLogin(
                email: environmentVariables.ssoClaimedUserEmail,
                password: environmentVariables.ssoClaimedUserPassword
            )
            .acceptFirstTimeAlert()

        // THEN
        let conversationsPage = try ManagedDevicesPage().removeDeviceAndContinueIfShown()

        XCTAssertTrue(
            conversationsPage.pageMainElement.waitForExistence(timeout: 2),
            "Conversations page did not appear after SSO login"
        )
    }
}

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

    private var customBackendDomain: String?
    private var previousQAFixedSSOCode: String?
    private var didUpdateQAFixedSSOCode = false
    private var qaFixedSSOHelper: SSOHelper?

    @MainActor
    override func tearDown() async throws {
        if let environmentVariables = try? EnvironmentVariables() {
            if didUpdateQAFixedSSOCode {
                let userHelper = UserHelper.instance(backend: .qaFixedSSO)
                let backOffice = BackOffice(backendURL: environmentVariables.backendURL(for: .qaFixedSSO))
                try? await backOffice.setDefaultSSOCode(previousQAFixedSSOCode, basicAuth: userHelper.basicAuth())
            }

            if let customBackendDomain {
                let backOffice = BackOffice(backendURL: environmentVariables.backendURL(for: .staging))
                try? await backOffice.deleteCustomBackendDomain(
                    customBackendDomain,
                    basicAuth: UserHelper.default.basicAuth()
                )
            }
        }

        await qaFixedSSOHelper?.cleanUpSSOResources()
        qaFixedSSOHelper = nil

        try await super.tearDown()
    }

    private func registerTeamOwnerWithSSOEnabled(
        userHelper: UserHelper = UserHelper.default,
        ssoHelperOverride: SSOHelper? = nil
    ) async throws -> UserInfo {
        let (_, teamOwner) = try await userHelper.registerUserAsTeamOwner()
        let teamID = try XCTUnwrap(teamOwner.teamID, "teamOwner.teamID is nil")
        let helper = ssoHelperOverride ?? ssoHelper!
        try await helper.enableSSOFeature(teamID: teamID)
        return teamOwner
    }

    private func createSSOUser(
        userHelper: UserHelper = UserHelper.default,
        ssoHelperOverride: SSOHelper? = nil
    ) async throws -> UserInfo {
        let teamOwner = try await registerTeamOwnerWithSSOEnabled(
            userHelper: userHelper,
            ssoHelperOverride: ssoHelperOverride
        )
        let ssoMember = UserGenerator.generateUniqueUserInfo()
        let helper = ssoHelperOverride ?? ssoHelper!
        return try await helper.createSSOUser(owner: teamOwner, ssoUser: ssoMember)
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
    func testSSOLoginWithSSOCodeAndNoResetPassword_TC_8966_10850() async throws {
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

        // THEN - account settings show the registered SSO user details
        XCTAssertTrue(
            accountSettingsPage.getUsername().contains(ssoUser.username),
            "Username didn't contain \(ssoUser.username)"
        )
        XCTAssertEqual(
            accountSettingsPage.getDomainInfo(),
            BackendTarget.staging.domainInfo,
            "Domain info mismatched on account page"
        )
        XCTAssertFalse(
            accountSettingsPage.resetPasswordButton.exists,
            "Reset password option is visible for SSO users"
        )
    }

    /// [critical]
    @MainActor
    func testReloginSSO_TC_8970() async throws {
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
    func testLoginOnRegisteredCustomBackendWithFixedSSO_TC_0000() async throws {
        // GIVEN - staging routes random domain to QA-Fixed-SSO, where default SSO code is set
        let environmentVariables = try EnvironmentVariables()
        let qaFixedSSOUserHelper = UserHelper.instance(backend: .qaFixedSSO)
        let qaFixedSSOHelper = SSOHelper(userHelper: qaFixedSSOUserHelper)
        self.qaFixedSSOHelper = qaFixedSSOHelper

        let ssoUser = try await createSSOUser(
            userHelper: qaFixedSSOUserHelper,
            ssoHelperOverride: qaFixedSSOHelper
        )
        let ssoCode = try XCTUnwrap(qaFixedSSOHelper.identityProviderId, "identityProviderId is nil")

        let qaFixedSSOBackOffice = BackOffice(backendURL: environmentVariables.backendURL(for: .qaFixedSSO))
        previousQAFixedSSOCode = try await qaFixedSSOBackOffice.getDefaultSSOCode(
            basicAuth: qaFixedSSOUserHelper.basicAuth()
        )
        try await qaFixedSSOBackOffice.setDefaultSSOCode(
            ssoCode,
            basicAuth: qaFixedSSOUserHelper.basicAuth()
        )
        didUpdateQAFixedSSOCode = true

        let domain = "fixed-sso-\(UUID().uuidString.prefix(8).lowercased()).com"
        customBackendDomain = domain
        let stagingBackOffice = BackOffice(backendURL: environmentVariables.backendURL(for: .staging))
        try await stagingBackOffice.addCustomBackendDomain(
            domain,
            configURL: environmentVariables.deepLinkURL(for: .qaFixedSSO),
            webappURL: environmentVariables.qaFixedSSOWebAppURL,
            basicAuth: UserHelper.default.basicAuth()
        )

        // WHEN - user enters email for mapped domain and accepts custom backend redirect
        let confirmationPage = try WelcomePage().enterDomainForBackendSwitch("joe@\(domain)")
        XCTAssertTrue(
            confirmationPage.backendUrlValue(containing: environmentVariables.backendURL(for: .qaFixedSSO))
                .waitForExistence(timeout: 5),
            "Confirmation dialog did not show expected backend URL"
        )

        let firstTimePage = try await confirmationPage
            .tapOnProceedButtonToSSOLogin()
            .ssoWebLogin(email: ssoUser.email, password: ssoUser.password)

        let conversationsPage = try firstTimePage
            .acceptFirstTimeAlert()
            .acceptPopupOnTeamMemberSetup()
            .setUsername(ssoUser.username)

        // THEN - login reaches conversation list without user entering SSO code manually
        XCTAssertTrue(
            conversationsPage.pageMainElement.waitForExistence(timeout: 5),
            "Conversations page did not appear after fixed SSO custom backend login"
        )
    }

    @MainActor
    func testSCIMManagedUserCannotChangeAccountFields_TC_10851() async throws {
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
        let conversationsPage = try ManagedDevicesPage.removeDeviceAndContinueIfShown(app: app)

        XCTAssertTrue(
            conversationsPage.pageMainElement.waitForExistence(timeout: 2),
            "Conversations page did not appear after SSO login"
        )
    }
}

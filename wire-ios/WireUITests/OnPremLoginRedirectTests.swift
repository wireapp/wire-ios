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

final class OnPremLoginRedirectTests: WireUITestCase {

    private var claimedDomain: String?

    @MainActor
    override func tearDown() async throws {
        if let claimedDomain {
            let environmentVariables = try EnvironmentVariables()
            let backOffice = BackOffice(backendURL: environmentVariables.backendURL(for: .staging))
            try? await backOffice.deleteCustomBackendDomain(claimedDomain, basicAuth: UserHelper.default.basicAuth())
            try? await backOffice.deleteDomainClaim(claimedDomain, basicAuth: UserHelper.default.basicAuth())
        }
        try await super.tearDown()
    }

    @MainActor
    func testOnPremLoginRedirect_TC_8965() async throws {

        // GIVEN - on-prem redirect is configured for a claimed domain on staging
        let environmentVariables = try EnvironmentVariables()
        let domain = "redirect-\(UUID().uuidString.prefix(8).lowercased()).com"
        let email = "redirect-user@\(domain)"
        let targetBackend = BackendTarget.qaFederationA
        let targetBackendURL = environmentVariables.backendURL(for: targetBackend)
        let targetConfigURL = environmentVariables.deepLinkURL(for: targetBackend)
        let backendLookupURL = environmentVariables.backendURL(for: .staging)
            .appendingPathComponent("custom-backend")
            .appendingPathComponent("by-domain")
            .appendingPathComponent(domain)

        let backOffice = BackOffice(backendURL: environmentVariables.backendURL(for: .staging))
        try await backOffice.addCustomBackendDomain(
            domain,
            configURL: targetConfigURL,
            webappURL: targetBackendURL,
            basicAuth: UserHelper.default.basicAuth()
        )
        claimedDomain = domain
        try await backOffice.claimDomain(
            domain,
            configURL: backendLookupURL,
            webappURL: targetBackendURL,
            basicAuth: UserHelper.default.basicAuth()
        )
        try await backOffice.waitForDomainRegistration(email: email, expectedConfigURL: backendLookupURL)

        // WHEN - user enters an email with the claimed domain
        let confirmationPage = try WelcomePage().enterDomainForBackendSwitch(email)

        // THEN - redirect confirmation shows the federated backend URL
        XCTAssertTrue(
            confirmationPage.backendUrlValue(containing: targetBackendURL).waitForExistence(timeout: 5),
            "Confirmation dialog did not show expected backend URL \(targetBackendURL.absoluteString)"
        )

        // WHEN - user confirms the redirect
        try confirmationPage.tapOnProceedButton()

        // THEN - app switches to the federated backend
        let welcomePage = try WelcomePage()
        XCTAssertTrue(
            welcomePage.setBackendLabel.waitForExistence(timeout: 7),
            "App did not switch to the on-prem backend after confirming redirect"
        )
        XCTAssertTrue(
            welcomePage.setBackendLabel.label.contains(targetBackend.domainInfo),
            "Expected backend domain missing from \(welcomePage.setBackendLabel.label)"
        )
    }

    /// Validates custom domain redirect opens Idp login
    /// Ref Bug: [WPB-28698]
    @MainActor
    func testCustomDomainRedirectOpensIdP_TC_11927() async throws {

        let environmentVariables = try EnvironmentVariables()

        // GIVEN - relaunch without staging backend, not needed for this flow
        app.terminate()
        app.launchArguments = ["-resetData"]
        app.launch()

        // WHEN - user enters email with custom domain
        let confirmationPage = try WelcomePage()
            .enterDomainForBackendSwitch(environmentVariables.customDomainRedirectEmail)

        let expectedBackendURL = try XCTUnwrap(
            URL(string: environmentVariables.customDomainRedirectBackendURL)
        )
        XCTAssertTrue(
            confirmationPage.backendUrlValue(containing: expectedBackendURL).waitForExistence(timeout: 5),
            "Confirmation dialog did not show expected backend URL"
        )

        // WHEN - user proceeds with the backend change
        try confirmationPage.tapOnProceedButton()

        // THEN - custom domain webpage opens in the app
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(
                    NSPredicate(
                        format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@",
                        environmentVariables.customDomainRedirectIdpDomain,
                        environmentVariables.customDomainRedirectIdpDomain
                    )
                )
                .firstMatch
                .waitForExistence(timeout: 10),
            "Webpage did not open expected URL \(environmentVariables.customDomainRedirectIdpDomain)"
        )
    }
}

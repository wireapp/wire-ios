//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class MultiBackendSupportTests: WireUITestCase {

    @MainActor
    private func testLoginToBackend(
        _ backend: BackendTarget,
        expectedDomain: String
    ) async throws -> (AccountSettingsPage, UserInfo) {

        let userHelper = UserHelper()
        let user = try await userHelper.createPersonalUser()
        let firstTimePage = try app.loginUser(email: user.email, password: user.password)
        let accountPage = try firstTimePage
            .acceptPopup()
            .openSettings()
            .openAccountSettings()

        let accountName = try XCTUnwrap(accountPage.getAccountName())
        let domainInfo = try XCTUnwrap(accountPage.getDomainInfo())

        XCTAssertEqual(accountName, user.name, "Account name didn't match \(user.name)")
        XCTAssertTrue(
            accountPage.getUsername().contains(user.username),
            "Username didn't contain \(user.username)"
        )
        XCTAssertEqual(accountPage.getEmail(), user.email, "Email didn't match \(user.email)")
        XCTAssertEqual(domainInfo, expectedDomain, "Domain info \(domainInfo) mismatched on account page")
        return (accountPage, user)
    }

    @MainActor
    func test_Add_MultiBackend_Accounts() async throws {

        defer { BackendContext.current = .staging }
        let domainInfoStaging = "staging.zinfra.io"
        let domainInfoAnta = "anta.wire.link"

        var (accountPageBackend1, userBackend1) = try await testLoginToBackend(
            BackendTarget.staging,
            expectedDomain: domainInfoStaging
        )

        _ = try accountPageBackend1.backToSettings()
            .switchToConversationsTab()
            .openUserAccountPageForUser(with: userBackend1.name)
            .tapAddAccountOrTeamButton()

        let deeplink = try EnvironmentVariables().antaDeepLinkURL
        setCustomBackend(byDeeplink: deeplink, domainInfo: domainInfoAnta)

        BackendContext.current = .anta

        let (accountPageBackend2, userBackend2) = try await testLoginToBackend(
            BackendTarget.anta,
            expectedDomain: domainInfoAnta
        )

        accountPageBackend1 = try accountPageBackend2.backToSettings()
            .switchToConversationsTab()
            .openUserAccountPageForUser(with: userBackend2.name)
            .switchUserAccountForUser(withName: userBackend1.name)
            .openSettings()
            .openAccountSettings()

        // Verify switching account
        let accountName = try XCTUnwrap(accountPageBackend1.getAccountName())
        let domanInfo = try XCTUnwrap(accountPageBackend1.getDomainInfo())
        XCTAssertEqual(accountName, userBackend1.name, "Account name didn't match \(userBackend1.name)")
        XCTAssertTrue(
            accountPageBackend1.getUsername().contains(userBackend1.username),
            "Username didn't contain \(userBackend1.username)"
        )
        XCTAssertEqual(accountPageBackend1.getEmail(), userBackend1.email, "Email didn't contain \(userBackend1.email)")
        XCTAssertEqual(domanInfo, domainInfoStaging, "Domain info \(domanInfo) mismatched on account page")
    }
}

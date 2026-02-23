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

final class MultiBackendSupportTests: WireUITestCase {

    @MainActor
    private func testLoginToBackend(
        _ backend: BackendTarget
    ) async throws -> (AccountSettingsPage, UserInfo) {

        let userHelper = UserHelper()
        let user = try await userHelper.createPersonalUser()

        let firstTimePage = try app.loginUser(email: user.email, password: user.password)

        let accountPage = try firstTimePage
            .acceptPopup(with: self)
            .openSettings()
            .openAccountSettings()

        try verifySwitchingAccount(
            accountPage: accountPage,
            expectedUser: user,
            expectedDomain: backend.domainInfo
        )

        return (accountPage, user)
    }

    /// testniy: https://app.testiny.io/IOS/testcases/tcf/1287/tc/8797
    @MainActor
    func test_Add_MultiBackend_Accounts() async throws {

        defer { BackendContext.current = .staging }

        var (accountPageBackend1, userBackend1) = try await testLoginToBackend(.staging)

        _ = try accountPageBackend1
            .backToSettings()
            .switchToConversationsTab()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()

        try switchBackend(target: .anta)

        let (accountPageBackend2, userBackend2) = try await testLoginToBackend(.anta)

        accountPageBackend1 = try accountPageBackend2
            .backToSettings()
            .switchToConversationsTab()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: userBackend1.name)
            .openSettings()
            .openAccountSettings()

        // Verify switching account
        try verifySwitchingAccount(
            accountPage: accountPageBackend1,
            expectedUser: userBackend1,
            expectedDomain: BackendTarget.staging.domainInfo
        )
    }

    private func verifySwitchingAccount(
        accountPage: AccountSettingsPage,
        expectedUser: UserInfo,
        expectedDomain: String
    ) throws {

        let accountName = try XCTUnwrap(accountPage.getAccountName())
        let domainInfo = try XCTUnwrap(accountPage.getDomainInfo())
        let username = accountPage.getUsername()
        let email = accountPage.getEmail()

        XCTAssertEqual(accountName, expectedUser.name, "Account name didn't match \(expectedUser.name)")
        XCTAssertTrue(
            username.contains(expectedUser.username),
            "Username didn't contain \(expectedUser.username)"
        )
        XCTAssertEqual(email, expectedUser.email, "Email didn't match \(expectedUser.email)")
        XCTAssertEqual(domainInfo, expectedDomain, "Domain info \(domainInfo) mismatched on account page")
    }

}

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

import WireFoundation
import XCTest

final class AccountManagementTests: WireUITestCase {

    var teamMember: UserInfo!

    @MainActor
    func testCritical_Account_Management_Lock_With_Passcode() async throws {
        let passcode = UserGenerator.generateAppPasscode()

        do {
            let (_, teamOwner) = try await userHelper.registerUserAsTeamOwner()
            let ownerAccessToken = try await userHelper.fetchAccessToken(
                email: teamOwner.email,
                password: teamOwner.password
            )
            let teamID = try XCTUnwrap(teamOwner.teamID)

            let (_, userInfo) = try await userHelper.registerUsersAsTeamMember(
                ownerAccessToken: ownerAccessToken,
                teamID: teamID
            )
            teamMember = userInfo
        } catch {
            throw XCTSkip("error in setup of test: \(error)")
        }

        let page = try await app.loginUser(email: teamMember.email, password: teamMember.password)
            .acceptPopupOnTeamMemberSetup(with: self)
            .setUsername(teamMember.username)
            .openSettings()
            .openOptionsMenu()
            .enableLockWithPasscode()
            .SetPasscode(passcode)
            .backgroundAndResume(app: app, forDelay: 2)

        XCTAssertFalse(
            page.conversationsButton.exists,
            "App incorrectly showing conversations page without app passcode"
        )

        _ = try page.enterPasscode(passcode)
    }

    @MainActor
    func testCritical_Account_Management_Update_Email_Reset_password() async throws {
        let updatedUserDetails = UserGenerator.generateUniqueUserInfo()

        do {
            let (_, teamOwner) = try await userHelper.registerUserAsTeamOwner()
            let ownerAccessToken = try await userHelper.fetchAccessToken(
                email: teamOwner.email,
                password: teamOwner.password
            )
            let teamID = try XCTUnwrap(teamOwner.teamID)

            let (_, userInfo) = try await userHelper.registerUsersAsTeamMember(
                ownerAccessToken: ownerAccessToken,
                teamID: teamID
            )
            teamMember = userInfo
        } catch {
            throw XCTSkip("error in setup of test: \(error)")
        }

        let verifyEmailPage = try app.loginUser(email: teamMember.email, password: teamMember.password)
            .acceptPopupOnTeamMemberSetup(with: self)
            .setUsername(teamMember.username)
            .openSettings()
            .openAccountSettings()
            .tapEmailField()
            .updateEmailAndSave(with: updatedUserDetails.email)

        XCTAssertTrue(
            app.staticTexts["Resend to \(updatedUserDetails.email)"].exists,
            "Expected static text label 'Resend to \(updatedUserDetails.email)' to be visible, but it was missing."
        )

        let webViewPage = try verifyEmailPage.goBacktoAccountSetting()
            .tapOnResetPasswordButton()

        XCTAssertTrue(webViewPage.webViewOpened(), "WebView didn't open")

    }
}

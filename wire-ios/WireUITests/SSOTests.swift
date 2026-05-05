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

    @MainActor
    func testSSOLoginWithSSOCode_TC_8966() async throws {
        let (_, teamOwner) = try await UserHelper.default.registerUserAsTeamOwner()
        guard let teamID = teamOwner.teamID else {
            throw RuntimeError("teamOwner.teamID is nil")
        }
        try await ssoHelper.enableSSOFeature(teamID: teamID)

        let ssoMember = UserGenerator.generateUniqueUserInfo()
        let ssoUser = try await ssoHelper.createSSOUser(owner: teamOwner, ssoUser: ssoMember)
        let ssoCode = try ssoHelper.getSSOCode()

        _ = try await WelcomePage()
            .enterSSOCode(ssoCode)
            .oktaLogin(email: ssoUser.email, password: ssoUser.password)
            .acceptFirstTimeAlert()
            .acceptPopupOnTeamMemberSetup()
            .setUsername(ssoUser.username)
    }
}

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

final class TeamManageTests: WireUITestCase {

    @MainActor
    func test_MigrateToTeam_FromPersonalUser() async throws {
        let user = try await userManager.createPersonalUser()
        let userAccountPage = WelcomePage()
            .enterEmailOrSSO(user.email)
            .enterPassword(user.password)
            .acceptFirstTimeAlert()
            .acceptPopup()
            .openUserAccount()
            .tapCreateTeamButtonAndContinue()
            .typeTeamNameAndContinue(user.teamName)
            .acceptTheConfirmationAndContinue()
            .tapBackToWireButton()
            .openUserAccount()

        let teamName = try XCTUnwrap(userAccountPage.getTeamName())
        XCTAssertEqual(teamName, user.teamName, "Team name didn't match \(user.teamName)")
        XCTAssertTrue(userAccountPage.manageTeamButton.exists, "Manage team button doesn't exist")

        /// ISSUE: Not able to delete user due to team so teardown is failing  FailureResponse(code: 403, label:
        /// "no-self-delete-for-team-owner", message: "Team owners are not allowed to delete themselves; ask a fellow
        /// owner")"
    }

}

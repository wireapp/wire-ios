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

import WireFoundation
import XCTest

final class WireDriveTests: WireUITestCase {

    private func verifyDriveEnabledConversation(on activeConversationPage: ActiveConversationPage) {
        XCTAssertTrue(activeConversationPage.labelSharedDriveIsOn.exists)
        XCTAssertTrue(activeConversationPage.labelSelfDeletingMessageIsOFF.exists)
        XCTAssertFalse(activeConversationPage.selfDeletingMessageButton.isHittable)

        activeConversationPage.conversationTitleButton.tap()

        XCTAssertTrue(activeConversationPage.sharedDriveButton.exists)
    }

    /// testiny: https://app.testiny.io/IOS/testcases/tcf/1389/tc/8955/
    @MainActor
    func test_CreateGroupConversationWithDrive() async throws {

        let groupName = UserGenerator.generateRandomGroupName()

        let (teamOwner, teamMembers, _, _) = try await userHelper.registerTeam(withMemberCount: 2)

        try await userHelper.unlockAndEnableDriveFeature(teamID: teamOwner.teamID!)

        let activeConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .tapPlusButtonToCreateGroup()
            .tapNewGroupButton()
            .enableShareDriveSwitch()
            .enterGroupName(groupName)
            .tapMemberCells(withLabelPrefixes: [teamMembers[0].name, teamMembers[1].name])
            .doneSelectingMembers()

        verifyDriveEnabledConversation(on: activeConversationPage)
    }

}

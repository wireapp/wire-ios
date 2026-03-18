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

    @MainActor
    func test_CreateGroupConversationWithDrive_TC_8955() async throws {

        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()

        let (teamOwner, teamMembers, _, _) = try await userHelper.registerTeam(withMemberCount: 2)

        try await userHelper.unlockAndEnableDriveFeature(teamID: teamOwner.teamID!)

        // WHEN
        let activeConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup(with: self)
            .tapPlusButtonToCreateGroup()
            .tapNewGroupButton()
            .enableShareDriveSwitch()
            .enterGroupName(groupName)
            .tapMemberCells(withLabelPrefixes: [teamMembers[0].name, teamMembers[1].name])
            .doneSelectingMembers()

        // THEN
        verifyDriveEnabledConversation(on: activeConversationPage)
    }

    @MainActor
    func test_CreateChannelConversationWithDrive_TC_8954() async throws {

        // GIVEN
        let channelName = UserGenerator.generateRandomConversationName()

        let (teamOwner, teamMembers, _, _) = try await userHelper.registerTeam(withMemberCount: 2)
        try await userHelper.unlockAndEnableChannelFeature(teamID: teamOwner.teamID!)
        try await userHelper.unlockAndEnableDriveFeature(teamID: teamOwner.teamID!)

        // WHEN
        let activeConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup(with: self)
            .tapPlusButtonToCreateGroup()
            .tapNewChannelButton()
            .enableShareDriveSwitch()
            .enterChannelName(channelName)
            .tapMemberCells(withLabelPrefixes: [teamMembers[0].name, teamMembers[1].name])
            .doneSelectingMembers()

        // THEN
        verifyDriveEnabledConversation(on: activeConversationPage)
    }

}

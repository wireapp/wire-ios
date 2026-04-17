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

    private func createDriveEnabledConversation(
        _ conversation: CreateConversationOption,
        memberCount: Int = 2
    ) async throws -> UserInfo {
        let (teamOwner, _, _, _) = try await userHelper.registerTeam(
            withMemberCount: memberCount,
            conversation: conversation,
            driveEnabled: true
        )
        return teamOwner
    }

    private func loginAndOpenConversation(for user: UserInfo) throws -> ActiveConversationPage {
        try app
            .loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openConversation()
    }

    private func verifyDriveEnabledConversation(on activeConversationPage: ActiveConversationPage) {
        XCTAssertTrue(activeConversationPage.labelSharedDriveIsOn.exists)
        XCTAssertTrue(activeConversationPage.labelSelfDeletingMessageIsOFF.exists)
        XCTAssertFalse(activeConversationPage.selfDeletingMessageButton.isHittable)

        activeConversationPage.conversationTitleButton.waitAndTap()

        XCTAssertTrue(activeConversationPage.sharedDriveButton.exists)
    }

    @MainActor
    func testCreateGroupConversationWithDrive_TC_8955() async throws {

        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let (teamOwner, teamMembers, _, _) = try await userHelper.registerTeam(withMemberCount: 2)
        let teamID = try XCTUnwrap(teamOwner.teamID)
        try await userHelper.unlockAndEnableDriveFeature(teamID: teamID)

        // WHEN
        let activeConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
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
    func testCreateChannelConversationWithDrive_TC_8954() async throws {

        // GIVEN
        let channelName = UserGenerator.generateRandomConversationName()
        let (teamOwner, teamMembers, _, _) = try await userHelper.registerTeam(withMemberCount: 2)
        let teamID = try XCTUnwrap(teamOwner.teamID)
        try await userHelper.unlockAndEnableChannelFeature(teamID: teamID)
        try await userHelper.unlockAndEnableDriveFeature(teamID: teamID)

        // WHEN
        let activeConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .tapPlusButtonToCreateGroup()
            .tapNewChannelButton()
            .enableShareDriveSwitch()
            .enterChannelName(channelName)
            .tapMemberCells(withLabelPrefixes: [teamMembers[0].name, teamMembers[1].name])
            .doneSelectingMembers()

        // THEN
        verifyDriveEnabledConversation(on: activeConversationPage)
    }

    @MainActor
    func testShareSketchImageWithTextMessageInDriveEnabledGroup_TC_8956() async throws {

        // GIVEN
        let message = "Attachment with Text"
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        // WHEN
        let activeConversationPage = try loginAndOpenConversation(for: teamOwner)
            .typeMessageAndAttachSketch(message)

        // THEN
        XCTAssertTrue(activeConversationPage.attachmentImagePreview.waitForExistence(timeout: 2))
        XCTAssertEqual(activeConversationPage.inputMessageField.value as? String, message)
    }

    @MainActor
    func testAccessImageSharedInDriveEnabledGroup_TC_8957() async throws {

        // GIVEN
        let message = "Attachment with Text"
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        // WHEN
        let activeConversationPage = try loginAndOpenConversation(for: teamOwner)
            .typeMessageAndAttachSketch(message)

        activeConversationPage.waitToUploadToFinishAndSend()

        // THEN
        try activeConversationPage
            .openSharedDrive()
            .verifyFileTypeAndMetadata(username: teamOwner.username)
    }

    @MainActor
    func testDeletingFileFromDriveMovesFileToRecycleBin_TC_8958() async throws {

        // GIVEN
        let message = "Attachment with Text"
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        // WHEN
        let activeConversationPage = try loginAndOpenConversation(for: teamOwner)
            .typeMessageAndAttachSketch(message)

        activeConversationPage.waitToUploadToFinishAndSend()

        let sharedDrivePage = try activeConversationPage
            .openSharedDrive()

        let sharedFileName = sharedDrivePage.fileNameText

        let recycleBinPage = try sharedDrivePage
            .openMoreOptionsOnFileAndDelete()
            .openRecycleBin()

        // THEN
        XCTAssertTrue(recycleBinPage.verifyFileMovedToRecycleBin(fileName: sharedFileName))

    }
    
    @MainActor
    func testRestoringFileFromRecycleBinToDrive_TC_8959() async throws {

        // GIVEN
        let message = "Attachment with Text"
        let teamOwner = try await createDriveEnabledConversation(
            .group(UserGenerator.generateRandomConversationName())
        )

        // WHEN
        let activeConversationPage = try loginAndOpenConversation(for: teamOwner)
            .typeMessageAndAttachSketch(message)

        activeConversationPage.waitToUploadToFinishAndSend()

        let sharedDrivePage = try activeConversationPage
            .openSharedDrive()

        let sharedFileName = sharedDrivePage.fileNameText

        let recycleBinPage = try sharedDrivePage
            .openMoreOptionsOnFileAndDelete()
            .openRecycleBin()

    }
}

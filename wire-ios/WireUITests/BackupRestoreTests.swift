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

final class BackupRestoreTests: WireUITestCase {

    @MainActor
    func test_CreateBackupAndRestore() async throws {
        //        let user = try await userHelper.createPersonalUser()
        //
        //        var firstTimePage = try app.loginUser(email: user.email, password: user.password)
        //        let creatingBackupPage = try  firstTimePage.acceptPopup()

        // TEMP - START

        let groupName = UserGenerator.generateRandomGroupName()
        let messageFromOwner = UserGenerator.generateRandomMessage()

        let teamOwner = try await userHelper.registerUserAsTeamOwner()
        let teamMember1 = UserGenerator.generateUniqueUserInfo()
        let teamMember2 = UserGenerator.generateUniqueUserInfo()

        let accessToken = try await userHelper.fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )

        let teamMember1Id = try await userHelper.registerUsersAsTeamMember(
            accessToken: accessToken,
            teamID: teamOwner.teamID!,
            member: teamMember1
        )

        let teamMember2Id = try await userHelper.registerUsersAsTeamMember(
            accessToken: accessToken,
            teamID: teamOwner.teamID!,
            member: teamMember2
        )

        let firstTimePage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
        let conversationPage = try firstTimePage.acceptPopupOnTeamMemberSetup()
            .setUsername(teamOwner.username)

        var activeConversationPage = try conversationPage.tapPlusButtonToCreateGroup()
            .tapNewGroupButton()
            .enterGroupName(groupName)
            .tapMemberCells(withLabelPrefixes: [teamMember1.name, teamMember2.name])
            .doneSelectingMembers()
            .sendMessage(messageFromOwner)

        var sentMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertFalse(
            sentMessages.contains(messageFromOwner),
            "Expected message '\(messageFromOwner)' not found in sent messages: \(sentMessages)"
        )

        //  TEMP - END

        let creatingBackupPage = try activeConversationPage.goBackToConversationPage()
            .openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapBackupNow()
            .enterBackupPasswordAndBackup(teamOwner.password)

        XCTAssertTrue(creatingBackupPage.backupSuccessfullyCreatedLabel.exists, "Backup is unsuccessful")
        let getProgressValue = try XCTUnwrap(creatingBackupPage.getBackupProgressValue())
        XCTAssertEqual(getProgressValue, "100%", "Progress is not 100%")

        let saveBackupFileBottomSheetPage = try creatingBackupPage.tapSaveFile()

        let backupFileName = try XCTUnwrap(saveBackupFileBottomSheetPage.getBackupFileName())

        _ = try saveBackupFileBottomSheetPage.tapSaveToFilesOnBottomSheet()
            .tapSaveButtonOnMyiPhonePage()
            .goBackToAccountPage()
            .logout()
            .enterPassword(teamOwner.password)

        activeConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .openConversation()

        sentMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertFalse(
            sentMessages.contains(messageFromOwner),
            "Expected message '\(messageFromOwner)' found in sent messages: \(sentMessages)"
        )

        let setPasswordPage = try activeConversationPage.goBackToConversationPage()
            .openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapRestoreFromBackupButton()
            .searchAndSelectBackupFile(withName: backupFileName)
            .enterBackupPasswordAndRestore(teamOwner.password)

        XCTAssertTrue(
            setPasswordPage.historyRestoredAlert.waitForExistence(timeout: 3),
            "History restored alert missing"
        )

        _ = try setPasswordPage.acceptHistoryrestoredAlert()
            .goBackToAccountPage()
            .goBackToSettingsPage()
            .switchToConversationsTab()
            .openConversation()

        sentMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertTrue(
            sentMessages.contains(messageFromOwner),
            "Expected message '\(messageFromOwner)' not found in sent messages: \(sentMessages)"
        )
    }
}

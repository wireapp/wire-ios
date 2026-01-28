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

final class BackupRestoreHistoryTests: WireUITestCase {

    /// testiny: https://app.testiny.io/IOS/testcases/tcf/1287/tc/8582
    @MainActor
    func test_CreateBackupAndRestoreHistory() async throws {
        let groupName = UserGenerator.generateRandomGroupName()
        let messageFromOwner = UserGenerator.generateRandomMessage()
        let (_, teamOwner) = try await userHelper.registerUserAsTeamOwner()
        let ownerAccessToken = try await userHelper.fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )
        let teamID = try XCTUnwrap(teamOwner.teamID)
        let countOfMembers = 2

        var qualifiedIds: [QualifiedID] = []
        var teamMembers: [UserInfo] = []

        for _ in 0 ..< countOfMembers {
            let (qualifiedId, teamMember) = try await userHelper.registerUsersAsTeamMember(
                ownerAccessToken: ownerAccessToken.token,
                teamID: teamID
            )
            qualifiedIds.append(qualifiedId)
            teamMembers.append(teamMember)
        }

        try await userHelper.createGroupConversations(
            qualifiedIds: qualifiedIds,
            owner: teamOwner,
            groupName: groupName
        )

        var activeConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup(with: self)
            .openConversation()
            .sendMessage(messageFromOwner)

        var sentMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertTrue(
            sentMessages.contains(messageFromOwner),
            "Expected message '\(messageFromOwner)' not found in sent messages: \(sentMessages)"
        )

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
            .acceptPopup(with: self)
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
            .selectBackupFile(withName: backupFileName)
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

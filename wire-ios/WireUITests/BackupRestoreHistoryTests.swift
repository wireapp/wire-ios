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

/// [core-messenger]
final class BackupRestoreHistoryTests: WireUITestCase {

    /// [critical]
    @MainActor
    func testCreateBackupAndRestoreHistoryWithPassword_TC_8928_8930_8805() async throws {
        var (messageFromOwner, teamOwner, activeConversationPage) = try await createTeamConversationAndSendMessage()

        let creatingBackupPage = try activeConversationPage.goBackToConversationPage()
            .openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapBackupNow()
            .enterBackupPasswordAndBackup(teamOwner.password)

        creatingBackupPage.verifyBackupIsCreatedSuccessfully()

        let saveBackupFileBottomSheetPage = try creatingBackupPage.tapSaveFile()
        let backupFileName = try XCTUnwrap(saveBackupFileBottomSheetPage.getBackupFileName())

        _ = try saveBackupFileBottomSheetPage.tapSaveToFilesOnBottomSheet()
            .tapSaveButtonOnMyiPhonePage()
            .goBackToAccountPage()
            .logout()
            .enterPassword(teamOwner.password)

        activeConversationPage = try loginAndVerifyPreviousMessageIsNotShown(
            email: teamOwner.email,
            password: teamOwner.password,
            message: messageFromOwner
        )

        let setPasswordPage = try activeConversationPage.goBackToConversationPage()
            .openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapRestoreFromBackupButton()
            .selectBackupFileWithPassword(withName: backupFileName)
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

        let restoredMessages = activeConversationPage.fetchMessages()
        XCTAssertTrue(
            restoredMessages.contains(messageFromOwner),
            "Expected message '\(messageFromOwner)' not found in restored messages: \(restoredMessages)"
        )
    }

    @MainActor
    func testCreateBackupAndRestoreHistoryWithoutPassword_TC_8927_8929() async throws {
        var (messageFromOwner, teamOwner, activeConversationPage) = try await createTeamConversationAndSendMessage()

        let backupOrRestorePage = try activeConversationPage.goBackToConversationPage()
            .openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapBackupNow()

        let creatingBackupPage = try backupOrRestorePage.backupWithoutPassword()

        creatingBackupPage.verifyBackupIsCreatedSuccessfully()

        let saveBackupFileBottomSheetPage = try creatingBackupPage.tapSaveFile()
        let backupFileName = try XCTUnwrap(saveBackupFileBottomSheetPage.getBackupFileName())

        _ = try saveBackupFileBottomSheetPage.tapSaveToFilesOnBottomSheet()
            .tapSaveButtonOnMyiPhonePage()
            .goBackToAccountPage()
            .logout()
            .enterPassword(teamOwner.password)

        activeConversationPage = try loginAndVerifyPreviousMessageIsNotShown(
            email: teamOwner.email,
            password: teamOwner.password,
            message: messageFromOwner
        )

        let backupOrRestorePageAfterRestore = try activeConversationPage.goBackToConversationPage()
            .openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapRestoreFromBackupButton()
            .selectBackupFileWithoutPassword(withName: backupFileName)

        XCTAssertTrue(
            backupOrRestorePageAfterRestore.historyRestoredAlert.waitForExistence(timeout: 3),
            "History restored alert missing"
        )

        _ = try backupOrRestorePageAfterRestore.acceptHistoryrestoredAlert()
            .goBackToAccountPage()
            .goBackToSettingsPage()
            .switchToConversationsTab()
            .openConversation()

        let restoredMessages = activeConversationPage.fetchMessages()
        XCTAssertTrue(
            restoredMessages.contains(messageFromOwner),
            "Expected message '\(messageFromOwner)' not found in restored messages: \(restoredMessages)"
        )
    }

    @MainActor
    private func createTeamConversationAndSendMessage() async throws -> (
        messageFromOwner: String,
        teamOwner: UserInfo,
        activeConversationPage: ActiveConversationPage
    ) {
        let groupName = UserGenerator.generateRandomConversationName()
        let messageFromOwner = UserGenerator.generateRandomMessage()
        let (teamOwner, _, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 2,
            conversation: .group(groupName)
        )

        let activeConversationPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()
            .openConversation()
            .sendMessage(messageFromOwner)

        XCTAssertTrue(
            activeConversationPage.messageLabels.firstMatch.waitForExistence(timeout: 2),
            "Sent message did not appear"
        )

        return (
            messageFromOwner: messageFromOwner,
            teamOwner: teamOwner,
            activeConversationPage: activeConversationPage
        )
    }

    @MainActor
    private func loginAndVerifyPreviousMessageIsNotShown(
        email: String,
        password: String,
        message: String
    ) throws -> ActiveConversationPage {
        let activeConversationPage = try app.loginUser(
            email: email,
            password: password
        )
        .acceptPopup()
        .openConversation()

        let sentMessages = activeConversationPage.fetchMessages()
        XCTAssertFalse(
            sentMessages.contains(message),
            "Expected message '\(message)' found in sent messages: \(sentMessages)"
        )

        return activeConversationPage
    }
}

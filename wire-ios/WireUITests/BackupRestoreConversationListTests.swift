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

final class BackupRestoreConversationListTests: WireUITestCase {

    /// Verifies that backing up, logging out, logging back in and restoring keeps the
    /// conversation list in the same order, and that the restored conversations are read
    /// (no stale unread badges broadcast by the import) so that a freshly received message
    /// shows exactly one unread message.
    ///
    /// Scenario (team owner is the user under test, `member` drives received messages):
    /// 1. Create conversations A, B, C in this order.
    /// 2. Owner sends a message in A, then in B.
    /// 3. Owner receives a message in A.
    ///    -> list order becomes A, B, C and A has 1 unread message.
    /// 4. Backup, logout, login, restore.
    ///    -> list order is still A, B, C and no conversation is unread.
    /// 5. Owner receives a message in A.
    ///    -> A shows exactly 1 unread message.
    @MainActor
    func testConversationListOrderAndUnreadAfterBackupRestore_TC_11583() async throws {

        // GIVEN a team with one owner and one member who shares three conversations.
        let nameA = "Conversation A"
        let nameB = "Conversation B"
        let nameC = "Conversation C"

        let messageInA = UserGenerator.generateRandomMessage()
        let messageInB = UserGenerator.generateRandomMessage()
        let receivedInABeforeBackup = UserGenerator.generateRandomMessage()
        let receivedInAAfterRestore = UserGenerator.generateRandomMessage()

        let (_, teamOwner) = try await UserHelper.default.registerUserAsTeamOwner()
        let ownerAccessToken = try await UserHelper.default.fetchAccessToken(
            email: teamOwner.email,
            password: teamOwner.password
        )
        let teamID = try XCTUnwrap(teamOwner.teamID)

        let (memberQualifiedID, member) = try await UserHelper.default.registerUsersAsTeamMemberWithUserHandleSet(
            ownerAccessToken: ownerAccessToken.token,
            teamID: teamID
        )

        // Create A, B, C in this order so the initial list order is C, B, A (newest first).
        for name in [nameA, nameB, nameC] {
            try await UserHelper.default.createGroupConversations(
                qualifiedIds: [memberQualifiedID],
                owner: teamOwner,
                groupName: name
            )
        }

        let (conversationIdA, _) = try await UserHelper.default.getConversationId(
            matching: .conversationName(nameA)
        )
        let conversationDomain = UserHelper.default.backend.domainInfo

        // WHEN the owner logs in and sends a message in A, then in B.
        var conversationsPage = try app.loginUser(email: teamOwner.email, password: teamOwner.password)
            .acceptPopup()

        conversationsPage = try conversationsPage
            .openConversation(named: nameA)
            .sendMessage(messageInA)
            .goBackToConversationPage()

        conversationsPage = try conversationsPage
            .openConversation(named: nameB)
            .sendMessage(messageInB)
            .goBackToConversationPage()

        // AND the member sends a message in A, which the owner receives.
        try await testServicesClient.sendText(
            user: member,
            text: receivedInABeforeBackup,
            conversationId: conversationIdA,
            domain: conversationDomain
        )

        XCTAssertTrue(
            conversationsPage.unreadMessagesCount.waitForExistence(timeout: 5),
            "Unread badge did not appear after receiving a message in A"
        )

        // THEN the list shows A, B, C and A has one unread message.
        XCTAssertEqual(
            try conversationsPage.conversationNamesInOrder(),
            [nameA, nameB, nameC],
            "Unexpected conversation order before backup"
        )
        XCTAssertEqual(
            try conversationsPage.getUnreadMessageCountValue(),
            "1",
            "Expected exactly one unread message in A before backup"
        )

        // WHEN backing up, logging out, logging back in and restoring.
        let backupFileName = try createBackupAndLogout(user: teamOwner)

        conversationsPage = try restoreBackup(fileName: backupFileName, user: teamOwner)

        // THEN the list order is preserved as A, B, C ...
        XCTAssertEqual(
            try conversationsPage.conversationNamesInOrder(),
            [nameA, nameB, nameC],
            "Unexpected conversation order after restore"
        )

        // ... and no conversation is unread (the import advanced lastRead).
        XCTAssertFalse(
            conversationsPage.unreadMessagesCount.waitForExistence(timeout: 3),
            "No conversation should be unread right after restoring the backup"
        )

        // WHEN the member sends another message in A.
        try await testServicesClient.sendText(
            user: member,
            text: receivedInAAfterRestore,
            conversationId: conversationIdA,
            domain: conversationDomain
        )

        // THEN A shows exactly one unread message.
        XCTAssertTrue(
            conversationsPage.unreadMessagesCount.waitForExistence(timeout: 5),
            "Unread badge did not appear after receiving a message in A post-restore"
        )
        XCTAssertEqual(
            try conversationsPage.getUnreadMessageCountValue(),
            "1",
            "Expected exactly one unread message in A after restore"
        )
        XCTAssertEqual(
            try conversationsPage.conversationNamesInOrder(),
            [nameA, nameB, nameC],
            "Unexpected conversation order after receiving a message post-restore"
        )
    }

    /// Creates a password-protected backup, saves it to Files, then logs out.
    /// - Returns: the name of the saved backup file.
    @MainActor
    private func createBackupAndLogout(user: UserInfo) throws -> String {
        let creatingBackupPage = try ConversationsPage()
            .openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapBackupNow()
            .enterBackupPasswordAndBackup(user.password)

        XCTAssertTrue(creatingBackupPage.backupSuccessfullyCreatedLabel.exists, "Backup was not created")

        let saveBackupFileBottomSheetPage = try creatingBackupPage.tapSaveFile()
        let backupFileName = try XCTUnwrap(saveBackupFileBottomSheetPage.getBackupFileName())

        _ = try saveBackupFileBottomSheetPage.tapSaveToFilesOnBottomSheet()
            .tapSaveButtonOnMyiPhonePage()
            .goBackToAccountPage()
            .logout()
            .enterPassword(user.password)

        return backupFileName
    }

    /// Logs the user back in and restores history from the given backup file.
    /// - Returns: the conversation list shown after the restore completes.
    @MainActor
    private func restoreBackup(fileName: String, user: UserInfo) throws -> ConversationsPage {
        let setPasswordPage = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapRestoreFromBackupButton()
            .selectBackupFileWithPassword(withName: fileName)
            .enterBackupPasswordAndRestore(user.password)

        XCTAssertTrue(
            setPasswordPage.historyRestoredAlert.waitForExistence(timeout: 5),
            "History restored alert did not appear"
        )

        return try setPasswordPage.acceptHistoryrestoredAlert()
            .goBackToAccountPage()
            .goBackToSettingsPage()
            .switchToConversationsTab()
    }
}

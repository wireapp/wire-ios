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

    private typealias Backup = (
        owner: UserInfo,
        teamMember: UserInfo,
        conversationName: String,
        conversationNames: [String],
        conversationId: UUID,
        domain: String,
        messages: [String],
        fileName: String
    )

    /// [critical]
    @MainActor
    func testCreateBackupAndRestoreHistoryWithPassword_TC_8928_8930_8805() async throws {
        var (messageFromOwner, teamOwner, activeConversationPage) = try await createTeamConversationAndSendMessage()

        let (backupFileName, accountSettingsPage) = try createBackupWithPassword(
            from: activeConversationPage.goBackToConversationPage(),
            password: teamOwner.password
        )
        _ = try accountSettingsPage.logout().enterPassword(teamOwner.password)

        activeConversationPage = try loginAndVerifyPreviousMessageIsNotShown(
            email: teamOwner.email,
            password: teamOwner.password,
            message: messageFromOwner
        )

        let conversationsPageAfterRestore = try restoreBackupWithPassword(
            from: activeConversationPage.goBackToConversationPage(),
            fileName: backupFileName,
            password: teamOwner.password
        )
        activeConversationPage = try conversationsPageAfterRestore.openConversation()

        let restoredMessages = activeConversationPage.fetchMessages()
        XCTAssertTrue(
            restoredMessages.contains(messageFromOwner),
            "Expected message '\(messageFromOwner)' not found in restored messages: \(restoredMessages)"
        )
    }

    @MainActor
    func testCreateBackupAndRestoreHistoryWithoutPassword_TC_8927_8929() async throws {
        var (messageFromOwner, teamOwner, activeConversationPage) = try await createTeamConversationAndSendMessage()

        let (backupFileName, accountSettingsPage) = try createBackupWithoutPassword(
            from: activeConversationPage.goBackToConversationPage()
        )
        _ = try accountSettingsPage.logout().enterPassword(teamOwner.password)

        activeConversationPage = try loginAndVerifyPreviousMessageIsNotShown(
            email: teamOwner.email,
            password: teamOwner.password,
            message: messageFromOwner
        )

        let conversationsPageAfterRestore = try restoreBackupWithoutPassword(
            from: activeConversationPage.goBackToConversationPage(),
            fileName: backupFileName
        )
        activeConversationPage = try conversationsPageAfterRestore.openConversation()

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
        try loginAndVerifyPreviousMessageIsNotShown(
            email: email,
            password: password,
            messages: [message]
        )
    }

    @MainActor
    private func loginAndVerifyPreviousMessageIsNotShown(
        email: String,
        password: String,
        messages: [String]
    ) throws -> ActiveConversationPage {
        let activeConversationPage = try app.loginUser(
            email: email,
            password: password
        )
        .acceptPopup()
        .openConversation()

        verifyMessagesAreNotVisible(messages, in: activeConversationPage)

        return activeConversationPage
    }

    @MainActor
    private func loginAndVerifyPreviousMessageIsNotShown(
        email: String,
        password: String,
        conversationName: String,
        messages: [String]
    ) throws -> ActiveConversationPage {
        let conversationsPage = try app.loginUser(
            email: email,
            password: password
        )
        .acceptPopup()
        let activeConversationPage = try openConversation(named: conversationName, from: conversationsPage)

        verifyMessagesAreNotVisible(messages, in: activeConversationPage)

        return activeConversationPage
    }

    @MainActor
    func testRestoringBackupKeepsConversationOrderAndMessagesAsRead_TC_11583() async throws {
        let backup = try await createBackupWithReadIncomingMessages()

        let activeConversationPage = try loginAndVerifyPreviousMessageIsNotShown(
            email: backup.owner.email,
            password: backup.owner.password,
            conversationName: backup.conversationName,
            messages: backup.messages
        )

        let conversationsPage = try restoreBackupWithoutPassword(
            from: activeConversationPage.goBackToConversationPage(),
            fileName: backup.fileName
        )
        verifyRestoredConversationOrder(backup.conversationNames, in: conversationsPage)

        try await sendMessages(
            [UserGenerator.generateRandomMessage()],
            from: backup.teamMember,
            conversationId: backup.conversationId,
            domain: backup.domain
        )
        try verifyUnreadCount(in: conversationsPage)
    }

    @MainActor
    private func createBackupWithReadIncomingMessages() async throws -> Backup {
        let oldestGroupName = UserGenerator.generateRandomConversationName()
        let middleChannelName = UserGenerator.generateRandomConversationName()
        let latestGroupName = UserGenerator.generateRandomConversationName()
        let messagesForLatestGroup = (0 ..< 3).map { _ in UserGenerator.generateRandomMessage() }

        let (owner, members, qualifiedIDs, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .channel(middleChannelName)
        )
        let teamMember = try XCTUnwrap(members.first)
        let domain = UserHelper.default.backend.domainInfo

        try await UserHelper.default.createGroupConversations(
            qualifiedIds: qualifiedIDs,
            owner: owner,
            groupName: oldestGroupName
        )
        try await UserHelper.default.createGroupConversations(
            qualifiedIds: qualifiedIDs,
            owner: owner,
            groupName: latestGroupName
        )
        let (oldestGroupId, _) = try await UserHelper.default.getConversationId(
            matching: .conversationName(oldestGroupName)
        )
        let (latestGroupId, _) = try await UserHelper.default.getConversationId(
            matching: .conversationName(latestGroupName)
        )

        let conversationsPage = try await loginToBackend(user: owner)

        try await sendMessages(
            [UserGenerator.generateRandomMessage()],
            from: teamMember,
            conversationId: oldestGroupId,
            domain: domain
        )
        try await sendMessages(
            messagesForLatestGroup,
            from: teamMember,
            conversationId: latestGroupId,
            domain: domain
        )

        let activeConversationPage = try openConversation(named: latestGroupName, from: conversationsPage)
        verifyMessages(messagesForLatestGroup, in: activeConversationPage)

        let conversationsPageBeforeBackup = try activeConversationPage.goBackToConversationPage()
        let conversationNames = firstConversationNames(limit: 3, in: conversationsPageBeforeBackup)

        let (fileName, accountSettingsPage) = try createBackupWithoutPassword(from: conversationsPageBeforeBackup)
        _ = try accountSettingsPage.logout().enterPassword(owner.password)

        return (
            owner: owner,
            teamMember: teamMember,
            conversationName: latestGroupName,
            conversationNames: conversationNames,
            conversationId: latestGroupId,
            domain: domain,
            messages: messagesForLatestGroup,
            fileName: fileName
        )
    }

    @MainActor
    private func createBackupWithPassword(
        from conversationsPage: ConversationsPage,
        password: String
    ) throws -> (backupFileName: String, accountSettingsPage: AccountSettingsPage) {
        let creatingBackupPage = try conversationsPage.openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapBackupNow()
            .enterBackupPasswordAndBackup(password)

        creatingBackupPage.verifyBackupIsCreatedSuccessfully()

        let saveBackupFileBottomSheetPage = try creatingBackupPage.tapSaveFile()
        let backupFileName = try XCTUnwrap(saveBackupFileBottomSheetPage.getBackupFileName())

        let accountSettingsPage = try saveBackupFileBottomSheetPage.tapSaveToFilesOnBottomSheet()
            .tapSaveButtonOnMyiPhonePage()
            .goBackToAccountPage()

        return (backupFileName, accountSettingsPage)
    }

    @MainActor
    private func createBackupWithoutPassword(
        from conversationsPage: ConversationsPage
    ) throws -> (backupFileName: String, accountSettingsPage: AccountSettingsPage) {
        let creatingBackupPage = try conversationsPage.openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapBackupNow()
            .backupWithoutPassword()

        creatingBackupPage.verifyBackupIsCreatedSuccessfully()

        let saveBackupFileBottomSheetPage = try creatingBackupPage.tapSaveFile()
        let backupFileName = try XCTUnwrap(saveBackupFileBottomSheetPage.getBackupFileName())

        let accountSettingsPage = try saveBackupFileBottomSheetPage.tapSaveToFilesOnBottomSheet()
            .tapSaveButtonOnMyiPhonePage()
            .goBackToAccountPage()

        return (backupFileName, accountSettingsPage)
    }

    @MainActor
    private func restoreBackupWithPassword(
        from conversationsPage: ConversationsPage,
        fileName: String,
        password: String
    ) throws -> ConversationsPage {
        let setPasswordPage = try conversationsPage
            .openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapRestoreFromBackupButton()
            .selectBackupFileWithPassword(withName: fileName)
            .enterBackupPasswordAndRestore(password)

        XCTAssertTrue(
            setPasswordPage.historyRestoredAlert.waitForExistence(timeout: 5),
            "History restored alert missing"
        )

        return try setPasswordPage.acceptHistoryrestoredAlert()
            .goBackToAccountPage()
            .goBackToSettingsPage()
            .switchToConversationsTab()
    }

    @MainActor
    private func restoreBackupWithoutPassword(
        from conversationsPage: ConversationsPage,
        fileName: String
    ) throws -> ConversationsPage {
        let backupOrRestorePage = try conversationsPage
            .openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapRestoreFromBackupButton()
            .selectBackupFileWithoutPassword(withName: fileName)

        XCTAssertTrue(
            backupOrRestorePage.historyRestoredAlert.waitForExistence(timeout: 5),
            "History restored alert missing"
        )

        return try backupOrRestorePage.acceptHistoryrestoredAlert()
            .goBackToAccountPage()
            .goBackToSettingsPage()
            .switchToConversationsTab()
    }

    private func verifyMessages(
        _ messages: [String],
        in activeConversationPage: ActiveConversationPage
    ) {
        for message in messages {
            activeConversationPage.verifyMessageSent(message)
        }
    }

    private func verifyMessagesAreNotVisible(
        _ messages: [String],
        in activeConversationPage: ActiveConversationPage
    ) {
        let actualMessages = activeConversationPage.fetchMessages()
        for message in messages {
            XCTAssertFalse(
                actualMessages.contains(message),
                "Message '\(message)' should not be visible yet: \(actualMessages)"
            )
        }
    }

    private func verifyRestoredConversationOrder(
        _ expectedNames: [String],
        in conversationsPage: ConversationsPage
    ) {
        XCTAssertEqual(
            firstConversationNames(limit: expectedNames.count, in: conversationsPage),
            expectedNames,
            "Restored conversation order changed"
        )
    }

    private func firstConversationNames(
        limit: Int,
        in conversationsPage: ConversationsPage
    ) -> [String] {
        XCTAssertTrue(
            conversationsPage.conversationCells.element(boundBy: limit - 1).waitForExistence(timeout: 10),
            "Conversation cell did not appear"
        )
        return conversationsPage.conversationCells.allElementsBoundByIndex
            .prefix(limit)
            .map(\.label)
    }

    @MainActor
    private func openConversation(
        named name: String,
        from conversationsPage: ConversationsPage
    ) throws -> ActiveConversationPage {
        try conversationsPage.letTheSyncFinish()
        let conversationCell = conversationsPage.conversationCell(named: name)
        XCTAssertTrue(
            conversationCell.waitAndTap(timeout: 10),
            "Conversation '\(name)' did not appear"
        )
        return try ActiveConversationPage()
    }

    private func sendMessages(
        _ messages: [String],
        from user: UserInfo,
        conversationId: UUID,
        domain: String
    ) async throws {
        for message in messages {
            try await testServicesClient.sendText(
                user: user,
                text: message,
                conversationId: conversationId,
                domain: domain
            )
        }
    }

    private func verifyUnreadCount(in conversationsPage: ConversationsPage) throws {
        XCTAssertTrue(
            conversationsPage.unreadMessagesCount.waitForExistence(timeout: 5),
            "Unread messages count element did not appear"
        )
        let unreadCount = try conversationsPage.getUnreadMessageCountValue()
        XCTAssertEqual(
            unreadCount,
            "1",
            "Expected unread count to be 1 for the new message only, was \(unreadCount)"
        )
    }
}

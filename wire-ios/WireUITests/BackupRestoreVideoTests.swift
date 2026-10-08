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
final class BackupRestoreVideoTests: WireUITestCase {

    /// A video received from another device and never played before the backup
    /// must play on the first tap after the backup is restored, in a freshly launched app.
    ///
    /// Requires the local Kalium test service, see `wire-ios/WireUITests/README`.
    @MainActor
    func testRestoredBackupAfterKillingAppPlaysVideoFromOtherDeviceOnFirstTap_TC_12157() async throws {

        // GIVEN user A received a video from another device (the test service) and did not play it
        let groupName = UserGenerator.generateRandomConversationName()
        let (userA, members, _, conversationID) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .group(groupName)
        )

        let conversationsPage = try app.loginUser(email: userA.email, password: userA.password)
            .acceptPopup()

        try await testServicesClient.sendFile(
            type: "video/mp4",
            user: members[0],
            fileName: "testVideo.mp4",
            filepath: TestServiceMediaFixtures.mediaURLs(relativeTo: #filePath).videoURL.path,
            convoId: try XCTUnwrap(conversationID, "conversationId is nil"),
            domain: UserHelper.default.backend.domainInfo
        )

        let receivedConversationPage = try conversationsPage.openConversation()
        XCTAssertTrue(
            receivedConversationPage.videoCell.waitForExistence(timeout: 30),
            "Video was not received by user A"
        )

        // AND user A created a backup
        let creatingBackupPage = try receivedConversationPage
            .goBackToConversationPage()
            .openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapBackupNow()
            .enterBackupPasswordAndBackup(userA.password)

        creatingBackupPage.verifyBackupIsCreatedSuccessfully()

        let saveBackupFileBottomSheetPage = try creatingBackupPage.tapSaveFile()
        let backupFileName = try XCTUnwrap(saveBackupFileBottomSheetPage.getBackupFileName())

        // WHEN user A logs out, the app is killed and relaunched, and user A logs in and restores the backup
        try saveBackupFileBottomSheetPage.tapSaveToFilesOnBottomSheet()
            .tapSaveButtonOnMyiPhonePage()
            .goBackToAccountPage()
            .logout()
            .enterPassword(userA.password)

        app.terminate()
        // relaunch without wiping the data of the previous launch
        app.launchArguments.removeAll { $0 == "-resetData" }
        app.launch()

        let setPasswordPage = try app.loginUser(email: userA.email, password: userA.password)
            .acceptPopup()
            .openSettings()
            .openAccountSettings()
            .tapBackupOrRestore()
            .tapRestoreFromBackupButton()
            .selectBackupFileWithPassword(withName: backupFileName)
            .enterBackupPasswordAndRestore(userA.password)

        XCTAssertTrue(
            setPasswordPage.historyRestoredAlert.waitForExistence(timeout: 3),
            "History restored alert missing"
        )

        let restoredConversationPage = try setPasswordPage.acceptHistoryrestoredAlert()
            .goBackToAccountPage()
            .goBackToSettingsPage()
            .switchToConversationsTab()
            .openConversation()

        // THEN user A can play the video on the first tap
        XCTAssertTrue(
            restoredConversationPage.videoPlayButton.waitForExistence(timeout: 10),
            "No Video play button found after restoring the backup"
        )
        restoredConversationPage.videoPlayButton.tap()

        XCTAssertTrue(
            restoredConversationPage.videoPlayer.waitForExistence(timeout: 15),
            "Video did not play on first tap after restoring the backup"
        )
    }
}

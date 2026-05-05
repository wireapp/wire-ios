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

import XCTest

final class ShareDebugReportOnLoginTests: WireUITestCase {

    @MainActor
    override func setUpWithError() throws {
        uiTestConfig[.shakeToReport] = true
        try super.setUpWithError()
    }

    /// On the login screen there is no user session and no mail client (simulator),
    /// so only "Share" and "Cancel" should appear — 2 options total.
    func testShakeGesture_onLoginScreen_presentsShareDebugActionSheet() throws {
        // GIVEN
        _ = try WelcomePage()

        // WHEN
        simulateShakeGesture()
        let shareDebugPage = try ShareDebugReportPage()

        // THEN
        XCTAssertTrue(shareDebugPage.shareButton.exists, "Share button should be present")
        XCTAssertTrue(shareDebugPage.cancelButton.exists, "Cancel button should be present")
        XCTAssertFalse(shareDebugPage.shareViaWireButton.exists, "Share via Wire should not be available without a session")
        XCTAssertFalse(shareDebugPage.sendEmailButton.exists, "Send email should not be available on simulator")

        shareDebugPage.selectShare()

        // Native share sheet should appear after the report is created
        let shareSheet = app.otherElements["ActivityListView"].firstMatch
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 10), "Native share sheet should be presented")
    }

    /// Once logged in, "Share via Wire" is also available — 3 options total.
    /// "Send email to Support" is still absent because the simulator has no mail client.
    @MainActor
    func testShakeGesture_onConversationScreen_presentsShareDebugActionSheet() async throws {
        // GIVEN
        let user = try await userHelper.createPersonalUser()
        _ = try await loginToBackend(user: user)

        // WHEN
        simulateShakeGesture()
        let shareDebugPage = try ShareDebugReportPage()

        // THEN
        XCTAssertTrue(shareDebugPage.shareViaWireButton.exists, "Share via Wire should be available when logged in")
        XCTAssertTrue(shareDebugPage.shareButton.exists, "Share button should be present")
        XCTAssertTrue(shareDebugPage.cancelButton.exists, "Cancel button should be present")
        XCTAssertFalse(shareDebugPage.sendEmailButton.exists, "Send email should not be available on simulator")
    }

    /// The debug report banner in Settings should also trigger the action sheet,
    /// and the report can be shared to a group conversation via Wire.
    @MainActor
    func testShareDebugReportBanner() async throws {
        // GIVEN
        let groupName = UserGenerator.generateRandomConversationName()
        let (_, owner) = try await userHelper.registerUserAsTeamOwner()
        let ownerToken = try await userHelper.fetchAccessToken(email: owner.email, password: owner.password)
        let teamID = try XCTUnwrap(owner.teamID)
        let (memberQualifiedID, _) = try await userHelper.registerUsersAsTeamMember(
            ownerAccessToken: ownerToken.token,
            teamID: teamID
        )
        try await userHelper.createGroupConversations(
            qualifiedIds: [memberQualifiedID],
            owner: owner,
            groupName: groupName
        )

        let conversationsPage = try await loginToBackend(user: owner)
        let settingsPage = try conversationsPage.openSettings()
        XCTAssertTrue(settingsPage.shareDebugBanner.waitForExistence(timeout: 10),
                      "Share debug banner should be visible on Settings page")

        // WHEN
        settingsPage.tapShareDebugBanner()
        try ShareDebugReportPage()
            .selectShareViaWire()

        // Select the group in the share picker and send
        try ShareViaWirePage()
            .selectConversation(name: groupName)
            .send()

        // THEN: app navigates to the conversation; the ZIP should arrive as a file message
        let activeConversation = try ActiveConversationPage()
        XCTAssertTrue(
            activeConversation.fileLabels.firstMatch.waitForExistence(timeout: 30),
            "File message should appear in '\(groupName)' after sharing the debug report"
        )
    }
}

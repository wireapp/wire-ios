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

final class ShareDebugReportTests: WireUITestCase {

    // MARK: - Tests

    /// TC: Navigate to Settings, tap the debug banner, then share via the share sheet.
    @MainActor
    func testShareDebugReport_viaNativeShare() async throws {
        let user = try await userHelper.createPersonalUser()

        let conversationsPage = try await loginToBackend(user: user)
        let settingsPage = try conversationsPage.openSettings()

        XCTAssertTrue(settingsPage.shareDebugBanner.waitForExistence(timeout: 10),
                      "Share debug banner should be visible on Settings page")

        settingsPage.tapShareDebugBanner()

        // Loading overlay appears, then action sheet
        let shareButton = app.buttons["Share"].firstMatch
        XCTAssertTrue(shareButton.waitForExistence(timeout: 15),
                      "Share action sheet should appear after tapping banner")

        shareButton.tap()

        // Native share sheet should appear
        let shareSheet = app.otherElements["ActivityListView"].firstMatch
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 10),
                      "Native share sheet should be presented")

        // Dismiss
        app.buttons["Close"].firstMatch.tap()
    }

    /// TC: Navigate to Settings, tap the debug banner, then share via Wire.
    @MainActor
    func testShareDebugReport_viaWire() async throws {
        let user = try await userHelper.createPersonalUser()

        let conversationsPage = try await loginToBackend(user: user)
        let settingsPage = try conversationsPage.openSettings()

        XCTAssertTrue(settingsPage.shareDebugBanner.waitForExistence(timeout: 10),
                      "Share debug banner should be visible on Settings page")

        settingsPage.tapShareDebugBanner()

        let shareViaWireButton = app.buttons["Share via Wire"].firstMatch
        XCTAssertTrue(shareViaWireButton.waitForExistence(timeout: 15),
                      "Share via Wire action should appear in action sheet")

        shareViaWireButton.tap()

        // Share via Wire sheet should appear
        let shareViaWireSheet = app.navigationBars["Share"].firstMatch
        XCTAssertTrue(shareViaWireSheet.waitForExistence(timeout: 10),
                      "Share via Wire sheet should be presented")

        // Dismiss
        app.buttons["Cancel"].firstMatch.tap()
    }
}

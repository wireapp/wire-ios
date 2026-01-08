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
import WireLocators
import XCTest

final class ShareExtensionTests: WireUITestCase {

    private let photosAppBundleId = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
    private let timeout: TimeInterval = 2

    @MainActor
    private func launchPhotosApp() async throws {
        photosAppBundleId.launch()
        XCTAssertTrue(photosAppBundleId.wait(for: .runningForeground, timeout: timeout))
    }

    @MainActor
    private func shareFirstPhotoToWire(name: String) async throws {
        let photosApp = try PhotosAppPage(photosApp: photosAppBundleId)
        try photosApp
            .openFirstImage()
            .shareImageToWire()
            .chooseConversationAndSend(name: name)
    }

    @MainActor
    private func switchBackToWireApp() async throws {
        app.activate()
        if !app.wait(for: .runningForeground, timeout: timeout) {
            app.launch()
            _ = app.wait(for: .runningForeground, timeout: timeout)
        }
    }

    @MainActor
    func test_ShareImageOnetoOne() async throws {

        let user1 = try await userHelper.createPersonalUser()
        let user2 = try await userHelper.createPersonalUser()
        let domain = BackendTarget.staging.domainInfo

        try await userHelper.sendConnectionRequestToUser(domain: domain, userId: user1.id)
        try await userHelper.acceptConnectionRequestFromUser(domain: domain, user1: user1, userId: user2.id)
        let firstTimePage = try app.loginUser(email: user1.email, password: user1.password)
        let conversationsPage = try  firstTimePage.acceptPopup(with: self)

        try await launchPhotosApp()
        try await shareFirstPhotoToWire(name: user2.name)
        try await switchBackToWireApp()

        let activeConversationPage = try conversationsPage.openConversation()

        XCTAssertTrue(
            activeConversationPage.imageCell.exists, "No Image cell found"
        )
    }
}

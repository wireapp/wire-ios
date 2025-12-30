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

import WireFoundation
import XCTest

final class ShareExtensionTests: WireUITestCase {

    private let photosApp = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")

    @MainActor
    func testCritical_ShareImageOnetoOne() async throws {

        let user1 = try await userHelper.createPersonalUser()
        let user2 = try await userHelper.createPersonalUser()
        let domain = BackendTarget.staging.domainInfo

        try await userHelper.sendConnectionRequestToUser(domain: domain, userId: user1.id)

        try await userHelper.acceptConnectionRequestFromUser(domain: domain, user1: user1, userId: user2.id)
        let firstTimePage = try app.loginUser(email: user1.email, password: user1.password)
        _ = try  firstTimePage.acceptPopup(with: self)

        _ = try await launchPhotosAppAndOpenFirstImage()

        try await shareToWireApp()

        try await chooseConversationAndSend(name: user2.name)
        try await switchBackToWireApp()

        // verify shared via Wire app - pending

    }

    @MainActor
    private func launchPhotosAppAndOpenFirstImage() async throws -> String {
        photosApp.launch()
        XCTAssertTrue(photosApp.wait(for: .runningForeground, timeout: 10))

        let firstImage = photosApp.images
            .matching(identifier: "PXGGridLayout-Info")
            .element(boundBy: 0)

        let imageLabel = firstImage.label
        // NOTE: Use a coordinate tap on center because Photos grid cells are not always directly hittable in UI
        // tests.
        firstImage
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .tap()

        return imageLabel
    }

    @MainActor
    private func shareToWireApp() async throws {
        let shareButton = photosApp.buttons
            .matching(identifier: "PUOneUpBarButtonItemIdentifierShare")
            .firstMatch

        shareButton.tap()
        let shareToWireApp = photosApp.cells["Wire"].firstMatch
        shareToWireApp.tap()
    }

    @MainActor
    private func chooseConversationAndSend(name: String) async throws {
        let chooseConversationButton = photosApp.buttons["chevron"]

        let selectConversation = photosApp.staticTexts[name]
        let sendButton = photosApp.buttons["sendButtonOnShareExtension"].firstMatch

        chooseConversationButton.tap()
        selectConversation.tap()
        sendButton.tap()
    }

    @MainActor
    private func switchBackToWireApp() async throws {
        app.activate()
        if app.state != .runningForeground {
            app.launch()
        }
    }
}

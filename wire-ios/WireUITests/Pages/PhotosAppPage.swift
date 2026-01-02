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

import WireLocators
import XCTest

class PhotosAppPage: PageModel {
    private let photosApp: XCUIApplication

    override var pageMainElement: XCUIElement {
        photosApp.windows.firstMatch
    }

    init(photosApp: XCUIApplication) throws {
        self.photosApp = photosApp
        try super.init()
    }

    var continueButtonOnWhatsNewPhotosApp: XCUIElement {
        photosApp.buttons[Locators.ShareExtensionPage.continueButton.rawValue].firstMatch
    }

    var firstImageTile: XCUIElement {
        photosApp.images
            .matching(identifier: Locators.ShareExtensionPage.imageTile.rawValue)
            .element(boundBy: 0)
    }

    var shareButton: XCUIElement {
        photosApp.buttons
            .matching(identifier: Locators.ShareExtensionPage.shareButton.rawValue)
            .firstMatch
    }

    var shareToWireApp: XCUIElement {
        photosApp.cells["Wire"].firstMatch
    }

    var chooseConversationButton: XCUIElement {
        photosApp.buttons[Locators.ShareExtensionPage.chooseConversations.rawValue].firstMatch
    }

    var sendButton: XCUIElement {
        photosApp.buttons[Locators.ShareExtensionPage.sendButtonOnShareExtension.rawValue].firstMatch
    }

    func selectConversation(name: String) -> XCUIElement {
        photosApp.staticTexts[name].firstMatch
    }

    @discardableResult
    func continueWhatsNewIfPresent() throws -> PhotosAppPage {
        if continueButtonOnWhatsNewPhotosApp.waitForExistence(timeout: 3) {
            continueButtonOnWhatsNewPhotosApp.tap()
        }
        return self
    }

    @discardableResult
    func openFirstImage() throws -> PhotosAppPage {
        try continueWhatsNewIfPresent()
        XCTAssertTrue(firstImageTile.waitForExistence(timeout: 10))
        // NOTE: Use a coordinate tap on center because Photos grid cells are not always directly hittable in UITests
        firstImageTile
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .tap()
        return self
    }

    @discardableResult
    func shareImageToWire() throws -> PhotosAppPage {
        XCTAssertTrue(shareButton.waitForExistence(timeout: 10))
        shareButton.tap()
        XCTAssertTrue(shareToWireApp.waitForExistence(timeout: 10))
        shareToWireApp.tap()
        return self
    }

    func chooseConversationAndSend(name: String) throws {
        XCTAssertTrue(chooseConversationButton.waitForExistence(timeout: 10))
        chooseConversationButton.tap()

        let conversationToSend = selectConversation(name: name)
        XCTAssertTrue(conversationToSend.waitForExistence(timeout: 10))
        conversationToSend.tap()

        XCTAssertTrue(sendButton.waitForExistence(timeout: 10))
        sendButton.tap()
    }

}

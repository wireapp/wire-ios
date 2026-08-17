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

import WireLocators
import XCTest

class PhotosAppPage: PageModel {
    private let photosApp: XCUIApplication
    private let timeout: TimeInterval = 5

    override var pageMainElement: XCUIElement {
        photosApp.windows.firstMatch
    }

    init(photosApp: XCUIApplication) throws {
        self.photosApp = photosApp
        try super.init()
    }

    var continueButtonOnWhatsNewPhotosApp: XCUIElement {
        photosApp.buttons[Locators.PhotosAppPage.continueButton.rawValue].firstMatch
    }

    var imageTile: XCUIElement {
        photosApp.images[Locators.PhotosAppPage.imageTile.rawValue].firstMatch
    }

    var shareButton: XCUIElement {
        photosApp.buttons
            .matching(identifier: Locators.PhotosAppPage.shareButton.rawValue)
            .firstMatch
    }

    var shareToWireApp: XCUIElement {
        photosApp.cells[Locators.ShareExtensionPage.wire.rawValue].firstMatch
    }

    var chooseConversation: XCUIElement {
        photosApp.descendants(matching: .any)[Locators.ShareExtensionPage.chooseConversations.rawValue].firstMatch
    }

    var sendButton: XCUIElement {
        photosApp.buttons[Locators.ShareExtensionPage.sendButtonOnShareExtension.rawValue].firstMatch
    }

    var messageField: XCUIElement {
        let textView = photosApp.textViews[Locators.ShareExtensionPage.messageField.rawValue].firstMatch
        if textView.exists {
            return textView
        }

        return photosApp.textViews.firstMatch
    }

    var shareExtensionSearchField: XCUIElement {
        photosApp.searchFields.allElementsBoundByIndex.first(where: \.isHittable)
            ?? photosApp.searchFields.firstMatch
    }

    var selectImage: XCUIElement {
        photosApp.buttons[Locators.PhotosAppPage.select.rawValue].firstMatch
    }

    func accountCell(named name: String) -> XCUIElement {
        let accountName = photosApp.staticTexts[name].firstMatch
        if accountName.exists {
            return accountName
        }

        return photosApp.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ OR identifier == %@", name, name))
            .firstMatch
    }

    func conversationCell(named name: String) -> XCUIElement {
        let exactCell = photosApp.cells.matching(NSPredicate(format: "label == %@", name)).firstMatch
        if exactCell.exists {
            return exactCell
        }

        let exactText = photosApp.staticTexts[name].firstMatch
        if exactText.exists {
            return exactText
        }

        return photosApp.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ OR identifier == %@", name, name))
            .firstMatch
    }

    func visibleShareExtensionLabels() -> [String] {
        let labels = photosApp.staticTexts.allElementsBoundByIndex + photosApp.cells.allElementsBoundByIndex
        return Array(labels.map(\.label).filter { !$0.isEmpty }.prefix(20))
    }

    @discardableResult
    func selectConversation(name: String) -> XCUIElement {
        let conversationCell = photosApp.staticTexts[name]
        XCTAssertTrue(conversationCell.waitForExistence(timeout: timeout))
        return conversationCell.firstMatch
    }

    @discardableResult
    func continueWhatsNewIfPresent() throws -> PhotosAppPage {
        if continueButtonOnWhatsNewPhotosApp.waitForExistence(timeout: timeout) {
            continueButtonOnWhatsNewPhotosApp.tap()
        }
        return self
    }

    @discardableResult
    func selectImageFromPhotos() throws -> PhotosAppPage {
        try continueWhatsNewIfPresent()
        XCTAssertTrue(imageTile.waitForExistence(timeout: 10))
        selectImage.tap()
        // NOTE: Tap the center via coordinates because Photos grid cells are often not directly hittable in UITests
        imageTile
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .tap()

        return self
    }

    @discardableResult
    func shareImageToWire() throws -> PhotosAppPage {
        shareButton.waitAndTap()
        XCTAssertTrue(shareToWireApp.waitForExistence(timeout: timeout))
        shareToWireApp.tap()
        return self
    }

    @discardableResult
    func addMessage(_ message: String) throws -> PhotosAppPage {
        XCTAssertTrue(
            messageField.waitForExistence(timeout: timeout),
            "Share extension message field didn't show up"
        )
        try messageField.tapIfKeyboardNotFocused().typeText(message)
        return self
    }

    func chooseConversationAndSend(name: String, message: String) throws {

        XCTAssertTrue(
            chooseConversation.waitForExistence(timeout: timeout),
            "chooseConversation, didn't show up"
        )
        chooseConversation.tap()

        let conversationToSend = selectConversation(name: name)
        XCTAssertTrue(
            conversationToSend.waitForExistence(timeout: timeout),
            "Tap to chooseConversation, didn't pass"
        )
        conversationToSend.waitAndTap()
        try addMessage(message)
        sendButton.waitAndTap()

        XCTAssertFalse(
            sendButton.waitForExistence(timeout: 5)
        )
    }
}

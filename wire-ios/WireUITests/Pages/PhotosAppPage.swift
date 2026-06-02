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
    private let timeout: TimeInterval = 2
    private let shareExtensionTimeout: TimeInterval = 5

    private enum Error: Swift.Error {
        case missingAccount
        case missingChooseConversation
        case missingConversation
        case missingSendButton
    }

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
        photosApp.images[Locators.ShareExtensionPage.imageTile.rawValue].firstMatch
    }

    var shareButton: XCUIElement {
        photosApp.buttons
            .matching(identifier: Locators.ShareExtensionPage.shareButton.rawValue)
            .firstMatch
    }

    var shareToWireApp: XCUIElement {
        photosApp.cells[Locators.ShareExtensionPage.wire.rawValue].firstMatch
    }

    var accountPicker: XCUIElement {
        photosApp.descendants(matching: .any)[Locators.ShareExtensionPage.account.rawValue].firstMatch
    }

    var chooseConversation: XCUIElement {
        photosApp.descendants(matching: .any)[Locators.ShareExtensionPage.chooseConversations.rawValue].firstMatch
    }

    var sendButton: XCUIElement {
        photosApp.buttons[Locators.ShareExtensionPage.sendButtonOnShareExtension.rawValue].firstMatch
    }

    var shareExtensionSearchField: XCUIElement {
        photosApp.searchFields.allElementsBoundByIndex.first(where: \.isHittable)
            ?? photosApp.searchFields.firstMatch
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

    func selectAccountIfNeeded(name: String) throws {
        guard accountPicker.waitForExistence(timeout: 1) else {
            return
        }

        if accountCell(named: name).exists {
            return
        }

        accountPicker.tap()
        let account = accountCell(named: name)
        guard account.waitForExistence(timeout: shareExtensionTimeout) else {
            XCTFail("Account '\(name)' was not available in the Wire share extension. " +
                "Visible labels: \(visibleShareExtensionLabels())")
            throw Error.missingAccount
        }
        account.tap()
        _ = chooseConversation.waitForExistence(timeout: shareExtensionTimeout)
    }

    func selectConversation(name: String) throws {
        var conversation = conversationCell(named: name)
        if !conversation.waitForExistence(timeout: 1),
           shareExtensionSearchField.waitForExistence(timeout: shareExtensionTimeout) {
            _ = try? shareExtensionSearchField.tapIfKeyboardNotFocused()
            shareExtensionSearchField.typeText(name)
            conversation = conversationCell(named: name)
        }

        guard conversation.waitForExistence(timeout: shareExtensionTimeout) else {
            XCTFail("Conversation '\(name)' was not available in the Wire share extension. " +
                "Visible labels: \(visibleShareExtensionLabels())")
            throw Error.missingConversation
        }
        conversation.tap()
    }

    @discardableResult
    func continueWhatsNewIfPresent() throws -> PhotosAppPage {
        if continueButtonOnWhatsNewPhotosApp.waitForExistence(timeout: timeout) {
            continueButtonOnWhatsNewPhotosApp.tap()
        }
        return self
    }

    @discardableResult
    func openFirstImage() throws -> PhotosAppPage {
        try continueWhatsNewIfPresent()
        XCTAssertTrue(firstImageTile.waitForExistence(timeout: 10))
        firstImageTile.tap()
        return self
    }

    @discardableResult
    func shareImageToWire() throws -> PhotosAppPage {
        shareButton.waitAndTap()
        XCTAssertTrue(shareToWireApp.waitForExistence(timeout: timeout))
        shareToWireApp.tap()
        return self
    }

    func chooseConversationAndSend(name: String, accountName: String? = nil) throws {
        defer { photosApp.terminate() }

        if let accountName {
            try selectAccountIfNeeded(name: accountName)
        }

        guard chooseConversation.waitForExistence(timeout: shareExtensionTimeout) else {
            XCTFail("Choose conversation control was not available in the Wire share extension")
            throw Error.missingChooseConversation
        }
        chooseConversation.tap()

        try selectConversation(name: name)

        guard sendButton.waitForExistence(timeout: shareExtensionTimeout) else {
            XCTFail("Send button was not available in the Wire share extension")
            throw Error.missingSendButton
        }
        sendButton.waitAndTap()

        XCTAssertTrue(shareButton.waitForExistence(timeout: timeout))
    }
}

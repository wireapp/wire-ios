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

class FilesAppPage: PageModel {

    private let filesApp: XCUIApplication
    private let timeout: TimeInterval = 5

    override var pageMainElement: XCUIElement {
        filesApp.windows.firstMatch
    }

    init(filesApp: XCUIApplication) throws {
        self.filesApp = filesApp
        try super.init()
    }

    var browseButton: XCUIElement {
        filesApp.buttons[Locators.FilesAppPage.browse.rawValue].firstMatch
    }

    var moreOptionsOnFilesPage: XCUIElement {
        filesApp.buttons[Locators.FilesAppPage.moreOptions.rawValue].firstMatch
    }

    var selectOptionOnFile: XCUIElement {
        filesApp.buttons[Locators.FilesAppPage.select.rawValue].firstMatch
    }

    var shareButton: XCUIElement {
        filesApp.buttons[Locators.FilesAppPage.share.rawValue].firstMatch
    }

    var shareToWireApp: XCUIElement {
        filesApp.descendants(matching: .any)[Locators.ShareExtensionPage.wire.rawValue].firstMatch
    }

    var chooseConversation: XCUIElement {
        filesApp.descendants(matching: .any)[Locators.ShareExtensionPage.chooseConversations.rawValue].firstMatch
    }

    var sendButton: XCUIElement {
        filesApp.buttons[Locators.ShareExtensionPage.sendButtonOnShareExtension.rawValue].firstMatch
    }

    var messageField: XCUIElement {
        let textView = filesApp.textViews[Locators.ShareExtensionPage.messageField.rawValue].firstMatch
        if textView.exists {
            return textView
        }

        return filesApp.textViews.firstMatch
    }

    private func displayedFileName(from fileName: String) -> String {
        (fileName as NSString).deletingPathExtension
    }

    private func fileExtension(from fileName: String) -> String {
        (fileName as NSString).pathExtension
    }

    func fileCell(named fileName: String) -> XCUIElement {
        let displayedFileName = displayedFileName(from: fileName)
        let fileExtension = fileExtension(from: fileName)

        return filesApp.cells["\(displayedFileName), \(fileExtension)"].firstMatch
    }

    func accountCell(named name: String) -> XCUIElement {
        let accountName = filesApp.staticTexts[name].firstMatch
        if accountName.exists {
            return accountName
        }

        return filesApp.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ OR identifier == %@", name, name))
            .firstMatch
    }

    func conversationCell(named name: String) -> XCUIElement {
        let exactCell = filesApp.cells.matching(NSPredicate(format: "label == %@", name)).firstMatch
        if exactCell.exists {
            return exactCell
        }

        let exactText = filesApp.staticTexts[name].firstMatch
        if exactText.exists {
            return exactText
        }

        return filesApp.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ OR identifier == %@", name, name))
            .firstMatch
    }

    func selectConversation(name: String) -> XCUIElement {
        let conversationCell = filesApp.staticTexts[name]
        XCTAssertTrue(conversationCell.waitForExistence(timeout: timeout))
        return conversationCell.firstMatch
    }

    @discardableResult
    func selectAndShareFileToWire(named fileName: String) throws -> Self {

        if browseButton.waitForExistence(timeout: timeout), !browseButton.isSelected {
            browseButton.tap()
        }

        moreOptionsOnFilesPage.tap()
        selectOptionOnFile.tap()

        let file = fileCell(named: fileName)
        XCTAssertTrue(
            file.waitForExistence(timeout: timeout),
            "Seeded file '\(fileName)' didn't show up"
        )
        file.tap()

        XCTAssertTrue(
            shareButton.waitForExistence(timeout: timeout),
            "Share button didn't show up"
        )
        shareButton.tap()

        if shareToWireApp.waitForExistence(timeout: timeout) {
            shareToWireApp.tap()
        }

        return self
    }

    @discardableResult
    func addMessage(_ message: String) throws -> Self {
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
        XCTAssertTrue(sendButton.waitForExistence(timeout: timeout), "Send button didn't show up")
        sendButton.waitAndTap()
        XCTAssertFalse(
            sendButton.waitForExistence(timeout: timeout)
        )
    }
}

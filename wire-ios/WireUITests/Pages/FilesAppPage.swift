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

    var doneButton: XCUIElement {
        filesApp.buttons[Locators.FilesAppPage.done.rawValue].firstMatch
    }

    var onMyIPhoneLocation: XCUIElement {
        filesApp.staticTexts[Locators.FilesAppPage.onMyIPhone.rawValue].firstMatch
    }

    var searchField: XCUIElement {
        filesApp.searchFields.allElementsBoundByIndex.first(where: \.isHittable)
            ?? filesApp.searchFields[Locators.FilesAppPage.search.rawValue].firstMatch
    }

    var shareButton: XCUIElement {
        filesApp.buttons[Locators.FilesAppPage.share.rawValue].firstMatch
    }

    var shareToWireApp: XCUIElement {
        filesApp.descendants(matching: .any)[Locators.ShareExtensionPage.wire.rawValue].firstMatch
    }

    var accountPicker: XCUIElement {
        filesApp.descendants(matching: .any)[Locators.ShareExtensionPage.account.rawValue].firstMatch
    }

    var chooseConversation: XCUIElement {
        filesApp.descendants(matching: .any)[Locators.ShareExtensionPage.chooseConversations.rawValue].firstMatch
    }

    var sendButton: XCUIElement {
        filesApp.buttons[Locators.ShareExtensionPage.sendButtonOnShareExtension.rawValue].firstMatch
    }

    var shareExtensionSearchField: XCUIElement {
        filesApp.searchFields.allElementsBoundByIndex.first(where: \.isHittable)
            ?? filesApp.searchFields.firstMatch
    }

    private func displayedFileName(from fileName: String) -> String {
        (fileName as NSString).deletingPathExtension
    }

    private func fileExtension(from fileName: String) -> String {
        (fileName as NSString).pathExtension
    }

    func fileCell(named fileName: String) -> XCUIElement {
        let displayedFileName = displayedFileName(from: fileName)
        let fileNameText = filesApp.staticTexts[displayedFileName].firstMatch
        if fileNameText.exists {
            return fileNameText
        }

        let fileTile = filesApp.cells["\(displayedFileName), \(fileExtension(from: fileName))"].firstMatch
        if fileTile.exists {
            return fileTile
        }

        return filesApp.descendants(matching: .any)
            .matching(
                NSPredicate(
                    format: "(label CONTAINS[c] %@ OR label CONTAINS[c] %@) AND NOT label BEGINSWITH[c] %@",
                    fileName,
                    displayedFileName,
                    Locators.FilesAppPage.nameContainsSearchToken.rawValue
                )
            )
            .firstMatch
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

    func visibleShareExtensionLabels() -> [String] {
        let labels = filesApp.staticTexts.allElementsBoundByIndex + filesApp.cells.allElementsBoundByIndex
        return Array(labels.map(\.label).filter { !$0.isEmpty }.prefix(20))
    }

    func selectConversation(name: String) -> XCUIElement {
        let conversationCell = filesApp.staticTexts[name]
        XCTAssertTrue(conversationCell.waitForExistence(timeout: timeout))
        return conversationCell.firstMatch
    }

    @discardableResult
    func openSeededFilesLocationIfNeeded(fileName: String) -> Self {
        if doneButton.waitForExistence(timeout: 1) {
            doneButton.tap()
        }

        if fileCell(named: fileName).waitForExistence(timeout: 2) {
            return self
        }

        if browseButton.waitForExistence(timeout: 2) {
            browseButton.tap()
        }

        if onMyIPhoneLocation.waitForExistence(timeout: 2) {
            onMyIPhoneLocation.tap()
        }

        if fileCell(named: fileName).waitForExistence(timeout: 2) {
            return self
        }

        if searchField.waitForExistence(timeout: 2) {
            _ = try? searchField.tapIfKeyboardNotFocused()
            searchField.typeText(fileName)
        }

        return self
    }

    @discardableResult
    func shareFileToWire(named fileName: String) throws -> Self {
        openSeededFilesLocationIfNeeded(fileName: fileName)

        let file = fileCell(named: fileName)
        if file.waitForExistence(timeout: timeout) {
            file.press(forDuration: 1.0)
        }

        if shareButton.waitForExistence(timeout: timeout) {
            shareButton.tap()
        }

        if shareToWireApp.waitForExistence(timeout: timeout) {
            shareToWireApp.tap()
        }
        return self
    }

    func chooseConversationAndSend(name: String) throws {
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

        XCTAssertTrue(sendButton.waitForExistence(timeout: timeout), "Send button didn't show up")
        sendButton.tap()
    }
}

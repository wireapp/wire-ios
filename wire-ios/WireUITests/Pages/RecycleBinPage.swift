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

class RecycleBinPage: PageModel {

    override var pageMainElement: XCUIElement {
        recycleBinPageheader
    }

    var recycleBinPageheader: XCUIElement {
        app.staticTexts[Locators.WireDrive.FilesPage.recycleBinPageheader.rawValue]
    }

    var moreButton: XCUIElement {
        app.buttons
            .matching(identifier: Locators.WireDrive.FilesContentPage.fileItem(0))
            .firstMatch
    }

    var restoreOnMenuContext: XCUIElement {
        app.buttons[Locators.WireDrive.FileMenu.restore.identifier]
    }

    var restoreOptionOnBottomSheet: XCUIElement {
        app.buttons[Locators.WireDrive.FilesItemPage.confirmRestoreButton.rawValue].firstMatch
    }

    var closeRecycleBinButton: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: Locators.WireDrive.FilesPage.close.rawValue)
            .firstMatch
    }

    private var fileTexts: XCUIElementQuery {
        app.staticTexts
            .matching(identifier: Locators.WireDrive.FilesContentPage.fileItem(0))
    }

    var fileName: XCUIElement {
        fileTexts.element(boundBy: 0)
    }

    func verifyFileMovedToRecycleBin(fileName: String) -> Bool {
        self.fileName.label == fileName
    }

    func openMoreOptionsOnFileAndRestoreFile() throws -> RecycleBinPage {
        moreButton.tap()
        restoreOnMenuContext.tap()
        restoreOptionOnBottomSheet.tap()
        return self
    }

    func closeRecycleBin() throws -> SharedDriveFilesPage {
        closeRecycleBinButton.tap()
        return try SharedDriveFilesPage()
    }

    var deletePermanentlyOnMenuContext: XCUIElement {
        app.buttons[Locators.WireDrive.FileMenu.deletePermanently.identifier]
    }

    var deletePermanentlyOptionOnBottomSheet: XCUIElement {
        app.buttons[Locators.WireDrive.FilesItemPage.confirmDeleteButton.rawValue].firstMatch
    }

    func deleteFilePermanently() -> Self {
        moreButton.tap()
        deletePermanentlyOnMenuContext.tap()
        deletePermanentlyOptionOnBottomSheet.tap()
        return self
    }

    func verifyRecycleBinIsEmpty() -> Bool {
        let file = app.staticTexts[Locators.WireDrive.FilesContentPage.fileItem(0)]
        return !file.waitForExistence(timeout: 3)
    }

    // MARK: - Multiple selection

    func fileRow(named name: String) -> XCUIElement {
        app.staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH %@", name))
            .firstMatch
    }

    func selectItems(named names: [String], isRecycleBin: Bool = false) {
        let moreButton = app.buttons[isRecycleBin ? Locators.WireDrive.FilesPage.moreOptionRecycleBin.rawValue : Locators.WireDrive.FilesPage.moreOptions.rawValue]
        XCTAssertTrue(moreButton.waitAndTap(timeout: 3))
        XCTAssertTrue(app.buttons[Locators.WireDrive.FilesPage.selectItems.rawValue].waitAndTap(timeout: 3))

        for name in names {
            XCTAssertTrue(fileRow(named: name).waitAndTap(timeout: 5), "Item '\(name)' couldn't be selected")
        }
    }

    func deleteSelectedItemsPermanently() {
        let deleteButton = app.buttons[Locators.WireDrive.FilesPage.deleteFloatingButton.rawValue]
        XCTAssertTrue(deleteButton.waitAndTap(timeout: 3), "Delete permanently button wasn't tappable")
        XCTAssertTrue(deletePermanentlyOptionOnBottomSheet.waitAndTap(timeout: 3))
        XCTAssertTrue(deletePermanentlyOptionOnBottomSheet.waitForNonExistence(timeout: 10))
    }

    func restoreSelectedItems() {
        let restoreButton = app.buttons[Locators.WireDrive.FilesPage.restoreFloatingButton.rawValue]
        XCTAssertTrue(restoreButton.waitAndTap(timeout: 3), "Restore button wasn't tappable")
        XCTAssertTrue(restoreOptionOnBottomSheet.waitAndTap(timeout: 3), "Restore confirmation wasn't tappable")
        XCTAssertTrue(restoreOptionOnBottomSheet.waitForNonExistence(timeout: 10), "Restore sheet wasn't dismissed")
    }

}

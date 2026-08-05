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

class SharedDriveFilesPage: PageModel {

    override var pageMainElement: XCUIElement {
        sharedDrivePageHeader
    }

    var sharedDrivePageHeader: XCUIElement {
        app.staticTexts[Locators.WireDrive.FilesPage.sharedDrivePageHeader.rawValue]
    }

    private var fileTexts: XCUIElementQuery {
        app.staticTexts
            .matching(identifier: Locators.WireDrive.FilesContentPage.fileItem(0))
    }

    var fileIcon: XCUIElement {
        app.images.matching(identifier: Locators.WireDrive.FilesContentPage.fileItem(0)).firstMatch
    }

    private var fileMetadataText: XCUIElement {
        fileTexts.firstMatch
    }

    var deleteOnMenuContext: XCUIElement {
        app.buttons[Locators.WireDrive.FileMenu.deleteToRecycleBin.identifier]
    }

    var deleteOptionOnBottomSheet: XCUIElement {
        app.buttons[Locators.WireDrive.FilesItemPage.confirmDeleteButton.rawValue].firstMatch
    }

    var moreOptionOnSharedDrive: XCUIElement {
        app.buttons[Locators.WireDrive.FilesPage.moreOptions.rawValue]
    }

    var openRecycleBinButton: XCUIElement {
        app.buttons[Locators.WireDrive.FilesPage.recycleBin.rawValue]
    }

    var createFolderButton: XCUIElement {
        app.buttons[Locators.WireDrive.FilesPage.createFolder.rawValue]
    }

    var moreButton: XCUIElement {
        app.buttons
            .matching(identifier: Locators.WireDrive.FilesContentPage.fileItem(0))
            .firstMatch
    }

    var numberOfFilesInList: Int {
        fileTexts.count
    }

    @discardableResult
    func verifyFileTypeAndMetadata(
        name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> SharedDriveFilesPage {
        XCTAssertTrue(fileIcon.waitForExistence(timeout: 3))
        XCTAssertTrue(fileIcon.exists, file: file, line: line)
        XCTAssertTrue(fileMetadataText.label.contains(".png"), file: file, line: line)
        XCTAssertTrue(fileMetadataText.label.contains(name), file: file, line: line)
        return try SharedDriveFilesPage()
    }

    var fileNameText: String {
        fileMetadataText.label
    }

    func openMoreOptionsOnFileAndDelete()  throws -> SharedDriveFilesPage {
        moreButton.tap()
        deleteOnMenuContext.tap()
        deleteOptionOnBottomSheet.tap()
        return try SharedDriveFilesPage()
    }

    func openRecycleBin() throws -> RecycleBinPage {
        moreOptionOnSharedDrive.tap()
        openRecycleBinButton.tap()
        return try RecycleBinPage()

    }

    func verifyFileMovedToSharedDrive(fileName: String) -> Bool {
        while !fileMetadataText.exists {
            pullToRefresh()
        }

        return fileMetadataText.label.contains(fileName)
    }

    private func pullToRefresh() {
        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 3))

        let start = table.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = table.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))

        start.press(forDuration: 0.1, thenDragTo: end)
    }

    func createFolder() throws -> FolderPage {
        moreOptionOnSharedDrive.tap()
        createFolderButton.tap()
        return try FolderPage()
    }

    func verifyFolderIsCreated(folderName: String) -> Bool {
        app.staticTexts
            .matching(identifier: folderName)
            .element
            .waitForExistence(timeout: 2)
    }

    var searchTextField: XCUIElement {
        app.searchFields.firstMatch
    }
}

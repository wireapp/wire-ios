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
            .firstMatch
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

    @discardableResult
    func openNavigationBarMenu() throws -> SharedDriveFilesPage {
        moreOptionOnSharedDrive.waitAndTap(timeout: 3)
        return try SharedDriveFilesPage()
    }

    /// Closes an open context menu by tapping outside of it.
    func dismissMenu() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5)).tap()
    }

    /// All the actions listed in the file's "more" menu.
    var fileMenuActions: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'fileMenu.'"))
    }

    var openFileMenuAction: XCUIElement {
        app.buttons["fileMenu.primaryAction"]
    }

    @discardableResult
    func openMoreOptionsOnFile() throws -> SharedDriveFilesPage {
        XCTAssertTrue(fileIcon.waitForExistence(timeout: 10))
        moreButton.waitAndTap(timeout: 5)
        return try SharedDriveFilesPage()
    }

    var makeAvailableOfflineButton: XCUIElement {
        app.buttons[Locators.WireDrive.FileMenu.makeAvailableOffline.identifier]
    }

    var availableOfflineIcon: XCUIElement {
        app.images["Available offline"].firstMatch
    }

    @discardableResult
    func makeFileAvailableOffline() throws -> SharedDriveFilesPage {
        moreButton.waitAndTap(timeout: 5)
        makeAvailableOfflineButton.waitAndTap(timeout: 3)
        return try SharedDriveFilesPage()
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
        moreOptionOnSharedDrive.waitAndTap(timeout: 3)
        createFolderButton.waitAndTap(timeout: 3)
        return try FolderPage()
    }

    var createFileButton: XCUIElement {
        app.buttons[Locators.WireDrive.FilesPage.createFile.rawValue]
    }

    func createFile(template: CreateFilePage.Template) throws -> CreateFilePage {
        moreOptionOnSharedDrive.waitAndTap(timeout: 3)
        createFileButton.waitAndTap(timeout: 3)
        app.buttons[Locators.WireDrive.FilesPage.createFileTemplate(template.rawValue)].waitAndTap(timeout: 3)
        return try CreateFilePage()
    }

    func verifyFileIsCreated(fileName: String, fileExtension: String) -> Bool {
        app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS %@", "\(fileName).\(fileExtension)"))
            .firstMatch
            .waitForExistence(timeout: 5)
    }

    func verifyFolderIsCreated(folderName: String) -> Bool {
        app.staticTexts
            .matching(identifier: folderName)
            .element
            .waitForExistence(timeout: 2)
    }

    // MARK: - Sort and filter

    var sortMenuButton: XCUIElement {
        app.buttons[Locators.WireDrive.FilesSortingPage.menuButton.rawValue]
    }

    var typeFilterButton: XCUIElement {
        app.buttons[Locators.WireDrive.FilesFilteringPage.filter("type")]
    }

    var saveFilterButton: XCUIElement {
        app.buttons[Locators.WireDrive.FilesFilterPage.saveButton.rawValue]
    }

    func sort(by key: String) {
        sortMenuButton.waitAndTap(timeout: 3)
        app.buttons[Locators.WireDrive.FilesSortingPage.sortKey(key)].waitAndTap(timeout: 3)
    }

    func sort(order: String) {
        sortMenuButton.waitAndTap(timeout: 3)
        app.buttons[Locators.WireDrive.FilesSortingPage.sortOrder(order)].waitAndTap(timeout: 3)
    }

    /// Focuses the search field, which reveals the filters bar, then filters by the given file type.
    func filter(byType type: String) {
        searchTextField.waitAndTap(timeout: 3)
        typeFilterButton.waitAndTap(timeout: 3)
        app.buttons[Locators.WireDrive.FilesFilterPage.typeItem(type)].waitAndTap(timeout: 3)
        saveFilterButton.waitAndTap(timeout: 3)
    }

    func waitForFirstFile(startingWith name: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "label BEGINSWITH %@", name)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: fileTexts.firstMatch)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    func fileRow(named name: String) -> XCUIElement {
        app.staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH %@", name))
            .firstMatch
    }

    var searchTextField: XCUIElement {
        app.searchFields.firstMatch
    }
}

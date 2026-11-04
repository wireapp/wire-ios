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

    private let headerName: String

    override var pageMainElement: XCUIElement {
        sharedDrivePageHeader
    }

    var sharedDrivePageHeader: XCUIElement {
        app.staticTexts[headerName]
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

    var filePreviewDoneButton: XCUIElement {
        app.navigationBars.buttons["Done"].firstMatch
    }

    /// Taps the first file of the list, which opens it in the QuickLook previewer.
    func openFile() {
        fileMetadataText.waitAndTap(timeout: 5)
    }

    /// The QuickLook controls, like the "Done" button, are hidden until the previewer is tapped.
    func tapFilePreview() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// Closes the QuickLook previewer, going back to the list.
    func closeFilePreview() {
        filePreviewDoneButton.waitAndTap(timeout: 3)
    }

    /// The "No internet" bar shown at the top of the list when Drive is offline.
    var offlineBar: XCUIElement {
        app.staticTexts
            .matching(NSPredicate(format: "label ==[c] 'No internet'"))
            .firstMatch
    }

    var availableOfflineIcon: XCUIElement {
        fileTexts
            .matching(NSPredicate(format: "label CONTAINS %@", "Available offline"))
            .firstMatch
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

    init(headerName: String? = nil) throws {
        self.headerName = headerName ?? Locators.WireDrive.FilesPage.sharedDrivePageHeader.rawValue
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

    // MARK: - Multiple selection

    func selectItems(named names: [String]) {
        XCTAssertTrue(moreOptionOnSharedDrive.waitAndTap(timeout: 3))
        XCTAssertTrue(app.buttons[Locators.WireDrive.FilesPage.selectItems.rawValue].waitAndTap(timeout: 3))

        for name in names {
            XCTAssertTrue(fileRow(named: name).waitAndTap(timeout: 5), "Item '\(name)' couldn't be selected")
        }
    }

    func moveSelectedItems(toFolder folderName: String) {
        let moveToFolderButton = app.buttons[Locators.WireDrive.FilesPage.moveToFolderFloatingButton.rawValue]
        XCTAssertTrue(moveToFolderButton.waitAndTap(timeout: 3), "Move to folder button wasn't tappable")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == %@", folderName)).element(boundBy: 1)
            .waitAndTap(timeout: 5))

        let moveHereButton = app.buttons[Locators.WireDrive.MoveToFolderPage.moveHere.rawValue]
        XCTAssertTrue(moveHereButton.waitAndTap(timeout: 5), "Move confirmation button wasn't tappable")
        XCTAssertTrue(moveHereButton.waitForNonExistence(timeout: 10), "Move sheet wasn't dismissed")
    }

    func tapDeleteFloatingButton() {
        let deleteButton = app.buttons[Locators.WireDrive.FilesPage.deleteFloatingButton.rawValue]
        XCTAssertTrue(deleteButton.waitAndTap(timeout: 3), "Delete button wasn't tappable")
    }

    func confirmDeleteOnBottomSheet() {
        XCTAssertTrue(deleteOptionOnBottomSheet.waitAndTap(timeout: 3), "Delete confirmation wasn't tappable")
        XCTAssertTrue(deleteOptionOnBottomSheet.waitForNonExistence(timeout: 10), "Delete sheet wasn't dismissed")
    }

    // MARK: - Direct uploads

    private var uploadMenuButton: XCUIElement {
        app.buttons["Upload"].firstMatch
    }

    private var uploadMediaButton: XCUIElement {
        app.buttons[Locators.WireDrive.UploadsPage.uploadMedia.rawValue].firstMatch
    }

    private var listedItems: XCUIElementQuery {
        app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "fileItem"))
    }

    var numberOfListedItems: Int {
        listedItems.count
    }

    /// Uploads a randomly chosen image from the native photo picker into the folder currently displayed.
    @discardableResult
    func uploadRandomMedia(folderName: String? = nil) throws -> SharedDriveFilesPage {
        app.buttons[Locators.WireDrive.FilesPage.moreOptions.rawValue]
            .firstMatch
            .waitAndTap(timeout: 10)

        XCTAssertTrue(
            uploadMenuButton.waitAndTap(timeout: 3),
            "Upload menu didn't show up"
        )

        XCTAssertTrue(
            uploadMediaButton.waitAndTap(timeout: 3),
            "Upload media button didn't show up"
        )

        // Handle the Photos permission prompt.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        for label in ["Allow Full Access", "Allow"] {
            let button = springboard.buttons[label].firstMatch

            if button.waitForExistence(timeout: 2) {
                button.tap()
                break
            }
        }

        // PHPickerViewController exposes the actual photo/video cells
        // with the PXGGridLayout-Info accessibility identifier.
        let mediaItems = app.images.matching(
            NSPredicate(format: "identifier == %@", Locators.PhotosAppPage.imageTile.rawValue)
        )

        XCTAssertTrue(
            mediaItems.firstMatch.waitForExistence(timeout: 10),
            "No media found in the photo picker"
        )

        let mediaCount = mediaItems.count

        XCTAssertGreaterThan(
            mediaCount,
            0,
            "Photo picker contains no media items"
        )

        let randomIndex = Int.random(in: 0 ..< mediaCount)
        let mediaItem = mediaItems.element(boundBy: randomIndex)

        // iOS 26 workaround:
        // PXGGridLayout-Info exists but is not reported as hittable,
        // so tap its screen coordinate instead of calling mediaItem.tap().
        let frame = mediaItem.frame

        XCTAssertFalse(
            frame.isEmpty,
            "Selected media item has an invalid frame"
        )

        let center = CGVector(
            dx: frame.midX / app.frame.width,
            dy: frame.midY / app.frame.height
        )

        app.coordinate(withNormalizedOffset: center).tap()

        // Selecting media should enable the trailing checkmark button.
        let navigationBar = app.navigationBars.matching(identifier: "Photos").element

        XCTAssertTrue(
            navigationBar.waitForExistence(timeout: 5),
            "Photo picker navigation bar didn't appear"
        )

        let addButton = navigationBar.buttons.matching(identifier: "Add").element

        XCTAssertTrue(
            addButton.waitAndTap(timeout: 5),
            "Trailing checkmark button wasn't tappable"
        )

        // Verify that the picker was dismissed.
        XCTAssertTrue(
            app.buttons[Locators.WireDrive.FilesPage.moreOptions.rawValue]
                .firstMatch
                .waitForExistence(timeout: 10),
            "Photos picker didn't return to the app"
        )

        return try SharedDriveFilesPage(headerName: folderName)
    }

    /// The list grows once the upload has finished and the folder has reloaded.
    func verifyMediaIsUploaded(previousItemCount: Int, timeout: TimeInterval = 60) -> Bool {
        let predicate = NSPredicate { [weak self] _, _ in
            (self?.numberOfListedItems ?? 0) > previousItemCount
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    func openFolder(named folderName: String) throws -> SharedDriveFilesPage {
        let folder = app.staticTexts[folderName].firstMatch
        XCTAssertTrue(folder.waitAndTap(timeout: 5), "Folder '\(folderName)' didn't show up")
        return try SharedDriveFilesPage(headerName: folderName)
    }

    var searchTextField: XCUIElement {
        app.searchFields.firstMatch
    }
}

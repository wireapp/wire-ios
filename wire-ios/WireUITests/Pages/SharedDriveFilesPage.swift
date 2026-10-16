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

    func verifyFolderIsCreated(folderName: String) -> Bool {
        app.staticTexts
            .matching(identifier: folderName)
            .element
            .waitForExistence(timeout: 2)
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
            NSPredicate(format: "identifier == %@", Locators.PhotosAppPage.raw)
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

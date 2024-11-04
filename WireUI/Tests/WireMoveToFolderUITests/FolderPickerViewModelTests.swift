//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import XCTest
import WireMoveToFolderUISupport

@testable import WireMoveToFolderUI


final class FolderPickerViewModelTests: XCTestCase {

    private var sut: FolderPickerViewModel!
    private var mockDirectory: MockFolderDirectoryType!

    override func setUp() {
        super.setUp()
        mockDirectory = MockFolderDirectoryType()
    }

    override func tearDown() {
        sut = nil
        mockDirectory = nil
        super.tearDown()
    }

    // MARK: - Initialization & Folder Loading

    func test_init_loadsFoldersFromDirectory() {
        // Given
        let folders = createTestFolders()
        mockDirectory.allFolders = folders

        // When
        createSUT()

        // Then
        XCTAssertEqual(sut.folders, folders)
    }

    // MARK: - Selection State

    func test_isSelected_returnsTrue_whenFolderMatchesCurrentFolder() {
        // Given
        let folderID = UUID().uuidString
        let conversation = Conversation(
            identifier: UUID().uuidString,
            currentFolderIdentifier: folderID
        )
        let folder = Folder(
            identifier: folderID,
            name: "Test Folder",
            kind: .folder
        )
        createSUT(conversation: conversation)

        // When
        let isSelected = sut.isSelected(folder)

        // Then
        XCTAssertTrue(isSelected)
    }

    func test_isSelected_returnsFalse_whenFolderDoesNotMatchCurrentFolder() {
        // Given
        let conversation = Conversation(
            identifier: UUID().uuidString,
            currentFolderIdentifier: UUID().uuidString
        )
        let folder = Folder(
            identifier: UUID().uuidString,
            name: "Test Folder",
            kind: .folder
        )
        createSUT(conversation: conversation)

        // When
        let isSelected = sut.isSelected(folder)

        // Then
        XCTAssertFalse(isSelected)
    }

    func test_isSelected_returnsFalse_whenFolderIdentifierIsNil() {
        // Given
        let conversation = Conversation(
            identifier: UUID().uuidString,
            currentFolderIdentifier: UUID().uuidString
        )
        let folder = Folder(
            identifier: nil,
            name: "Test Folder",
            kind: .folder
        )
        createSUT(conversation: conversation)

        // When
        let isSelected = sut.isSelected(folder)

        // Then
        XCTAssertFalse(isSelected)
    }
}

// MARK: - Test Helpers

private extension FolderPickerViewModelTests {
    func createSUT(
        conversation: Conversation = Conversation(
            identifier: UUID().uuidString,
            currentFolderIdentifier: nil
        )
    ) {
        sut = FolderPickerViewModel(
            conversation: conversation,
            directory: mockDirectory
        )
    }

    func createTestFolders() -> [Folder] {
        [
            Folder(identifier: UUID().uuidString, name: "Work", kind: .folder),
            Folder(identifier: UUID().uuidString, name: "Personal", kind: .folder),
            Folder(identifier: UUID().uuidString, name: "Favorites", kind: .favorite)
        ]
    }
}

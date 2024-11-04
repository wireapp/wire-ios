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

    // MARK: - Properties

    private var sut: FolderPickerViewModel!
    private var mockDirectory: MockFolderDirectoryType!
    private var mockSelectionUseCase: MockFolderSelectionUseCaseType!

    // MARK: - setUp

    override func setUp() {
        mockDirectory = MockFolderDirectoryType()
        mockSelectionUseCase = MockFolderSelectionUseCaseType()
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockDirectory = nil
        mockSelectionUseCase = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func test_init_loadsFoldersFromDirectory() {
        // GIVEN
        let folders = [
            Folder(identifier: "1", name: "Work", kind: .folder),
            Folder(identifier: "2", name: "Personal", kind: .folder)
        ]
        mockDirectory.allFolders = folders

        // WHEN
        createSUT()

        // THEN
        XCTAssertEqual(sut.folders, folders)
    }

    // MARK: - Folder Selection

    func test_select_invokesUseCase() {
        // GIVEN
        let folder = Folder(identifier: "1", name: "Work", kind: .folder)
        let conversation = Conversation(identifier: "conv1", currentFolderIdentifier: nil)
        mockSelectionUseCase.invokeFolderConversation_MockMethod = { _, _ in }
        createSUT(conversation: conversation)

        // WHEN
        sut.select(folder)

        // THEN
        XCTAssertEqual(mockSelectionUseCase.invokeFolderConversation_Invocations.count, 1)
        XCTAssertEqual(mockSelectionUseCase.invokeFolderConversation_Invocations.first?.folder, folder)
    }

    // MARK: - Selection State

    func test_isSelected_returnsTrue_whenFolderMatchesCurrentFolder() {
        // GIVEN
        let folderID = "folder1"
        let conversation = Conversation(identifier: "conv1", currentFolderIdentifier: folderID)
        let folder = Folder(identifier: folderID, name: "Work", kind: .folder)
        createSUT(conversation: conversation)

        // WHEN
        let isSelected = sut.isSelected(folder)

        // THEN
        XCTAssertTrue(isSelected)
    }

    func test_isSelected_returnsFalse_whenFolderDoesNotMatchCurrentFolder() {
        // GIVEN
        let conversation = Conversation(identifier: "conv1", currentFolderIdentifier: "folder1")
        let folder = Folder(identifier: "folder2", name: "Work", kind: .folder)
        createSUT(conversation: conversation)

        // WHEN
        let isSelected = sut.isSelected(folder)

        // THEN
        XCTAssertFalse(isSelected)
    }

    func test_isSelected_returnsFalse_whenFolderIdentifierIsNil() {
        // GIVEN
        let conversation = Conversation(identifier: "conv1", currentFolderIdentifier: "folder1")
        let folder = Folder(identifier: nil, name: "Work", kind: .folder)
        createSUT(conversation: conversation)

        // WHEN
        let isSelected = sut.isSelected(folder)

        // THEN
        XCTAssertFalse(isSelected)
    }

    // MARK: - Helpers

    private func createSUT(
        conversation: Conversation = Conversation(identifier: "test", currentFolderIdentifier: nil),
        directory: MockFolderDirectoryType? = nil,
        selectionUseCase: MockFolderSelectionUseCaseType? = nil
    ) {
        sut = FolderPickerViewModel(
            conversation: conversation,
            directory: directory ?? mockDirectory,
            selectionUseCase: selectionUseCase ?? mockSelectionUseCase
        )
    }
}

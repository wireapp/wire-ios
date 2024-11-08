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

import WireMoveToFolderUISupport
import XCTest

@testable import WireMoveToFolderUI

final class FolderPickerViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: FolderPickerViewModel!
    private var mockDirectory: MockFolderDirectoryTypeProtocol!
    private var mockSelectionUseCase: MockMoveConversationToFolderUseCaseType!

    // MARK: - setUp

    @MainActor
    override func setUp() async throws {
        mockDirectory = MockFolderDirectoryTypeProtocol()
        mockSelectionUseCase = MockMoveConversationToFolderUseCaseType()
    }

    // MARK: - tearDown

    @MainActor
    override func tearDown() async throws {
        sut = nil
        mockDirectory = nil
        mockSelectionUseCase = nil
    }

    // MARK: - Initialization

    func test_init_loadsFoldersFromDirectory() {
        // GIVEN
        let folders = [
            Folder(identifier: UUID(), name: "Work"),
            Folder(identifier: UUID(), name: "Personal")
        ]
        mockDirectory.allFolders = folders

        // WHEN
        createSUT()

        // THEN
        XCTAssertEqual(sut.folders, folders)
    }

    // MARK: - Folder Selection

    func test_select_invokesUseCase() async throws {
        // GIVEN
        let folder = Folder(identifier: UUID(), name: "Work")
        let conversation = Conversation(identifier: UUID(), currentFolderIdentifier: nil)
        mockSelectionUseCase.invokeFolderConversation_MockMethod = { _, _ in }
        createSUT(conversation: conversation)

        // WHEN
        try await sut.select(folder)

        // THEN
        XCTAssertEqual(mockSelectionUseCase.invokeFolderConversation_Invocations.count, 1)
        XCTAssertEqual(mockSelectionUseCase.invokeFolderConversation_Invocations.first?.folder, folder)
    }

    // MARK: - Selection State

    func test_isSelected_returnsTrue_whenFolderMatchesCurrentFolder() {
        // GIVEN
        let folderID = UUID()
        let conversation = Conversation(identifier: UUID(), currentFolderIdentifier: folderID)
        let folder = Folder(identifier: folderID, name: "Work")
        createSUT(conversation: conversation)

        // WHEN
        let isSelected = sut.isSelected(folder)

        // THEN
        XCTAssertTrue(isSelected)
    }

    func test_isSelected_returnsFalse_whenFolderDoesNotMatchCurrentFolder() {
        // GIVEN
        let conversation = Conversation(identifier: UUID(), currentFolderIdentifier: UUID())
        let folder = Folder(identifier: UUID(), name: "Work")
        createSUT(conversation: conversation)

        // WHEN
        let isSelected = sut.isSelected(folder)

        // THEN
        XCTAssertFalse(isSelected)
    }

    func test_isSelected_returnsFalse_whenFolderIdentifierIsNil() {
        // GIVEN
        let conversation = Conversation(identifier: UUID(), currentFolderIdentifier: UUID())
        let folder = Folder(identifier: nil, name: "Work")
        createSUT(conversation: conversation)

        // WHEN
        let isSelected = sut.isSelected(folder)

        // THEN
        XCTAssertFalse(isSelected)
    }

    // MARK: - Helpers

    private func createSUT(conversation: Conversation = Conversation(
        identifier: UUID(),
        currentFolderIdentifier: nil
    )) {
        sut = FolderPickerViewModel(
            conversation: conversation,
            directory: mockDirectory,
            selectionUseCase: mockSelectionUseCase
        )
    }
}

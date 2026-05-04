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

import WireMoveToFolderUISupport
import XCTest
@testable import WireMoveToFolderUI

final class FolderPickerViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: FolderPickerViewModel!
    private var mockDirectory: MockFolderDirectoryTypeProtocol!
    private var mockUpdateFolderUseCase: MockUpdateConversationFolderUseCase!
    private var mockCreateFolderUseCase: MockCreateConversationFolderUseCase!

    // MARK: - setUp

    @MainActor
    override func setUp() async throws {
        mockDirectory = MockFolderDirectoryTypeProtocol()
        mockUpdateFolderUseCase = MockUpdateConversationFolderUseCase()
        mockCreateFolderUseCase = MockCreateConversationFolderUseCase()
    }

    // MARK: - tearDown

    @MainActor
    override func tearDown() async throws {
        sut = nil
        mockDirectory = nil
        mockUpdateFolderUseCase = nil
        mockCreateFolderUseCase = nil
    }

    // MARK: - Initialization

    @MainActor
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

    @MainActor
    func test_select_invokesUseCase() async throws {
        // GIVEN
        let folder = Folder(identifier: UUID(), name: "Work")
        let conversation = Conversation(identifier: UUID(), currentFolderIdentifier: nil)
        mockUpdateFolderUseCase.invoke_MockMethod = { _, _ in }
        createSUT(conversation: conversation)

        // WHEN
        try await sut.select(folder)

        // THEN
        XCTAssertEqual(mockUpdateFolderUseCase.invoke_Invocations.count, 1)
        XCTAssertEqual(mockUpdateFolderUseCase.invoke_Invocations.first?.conversationID, conversation.identifier)
        XCTAssertEqual(mockUpdateFolderUseCase.invoke_Invocations.first?.folderID, folder.identifier)
    }

    @MainActor
    func test_select_throwsError_whenUseCaseThrows() async {
        // GIVEN
        let folder = Folder(identifier: UUID(), name: "Work")
        let conversation = Conversation(identifier: UUID(), currentFolderIdentifier: nil)
        let expectedError = NSError(domain: "test", code: 1)
        mockUpdateFolderUseCase.invoke_MockError = expectedError
        createSUT(conversation: conversation)

        // WHEN/THEN
        do {
            try await sut.select(folder)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as NSError, expectedError)
        }
    }

    // MARK: - Selection State

    @MainActor
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

    @MainActor
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

    @MainActor
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

    @MainActor
    private func createSUT(conversation: Conversation = Conversation(
        identifier: UUID(),
        currentFolderIdentifier: nil
    )) {
        sut = FolderPickerViewModel(
            conversation: conversation,
            directory: mockDirectory,
            updateConversationFolderUseCase: mockUpdateFolderUseCase,
            createFolderUseCase: mockCreateFolderUseCase
        )
    }
}

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

import WireDesign
import WireMoveToFolderUISupport
import WireTestingPackage
import XCTest
import SwiftUI

@testable import WireMoveToFolderUI

final class FolderPickerSnapshotTests: XCTestCase {

    // MARK: - Properties

    private var sut: FolderPicker!
    private var viewModel: FolderPickerViewModel!
    private var mockDirectory: MockFolderDirectoryTypeProtocol!
    private var mockSelectionUseCase: MockMoveConversationToFolderUseCaseType!
    private var snapshotHelper: SnapshotHelper!

    // MARK: - Setup & Teardown

    @MainActor
    override func setUp() async throws {
        mockDirectory = MockFolderDirectoryTypeProtocol()
        mockSelectionUseCase = MockMoveConversationToFolderUseCaseType()
        snapshotHelper = .init()
            .withSnapshotDirectory(SnapshotTestReferenceImageDirectory)
    }

    @MainActor
    override func tearDown() async throws {
        sut = nil
        viewModel = nil
        mockDirectory = nil
        mockSelectionUseCase = nil
        snapshotHelper = nil
    }

    // MARK: - Test Cases

    @MainActor
    func testEmptyState() {
        // Given
        mockDirectory.allFolders = []
        createSUT()

        // Then
        verify(testName: "empty_state")
    }

    @MainActor
    func testWithFolders() {
        // Given
        let folders = [
            Folder(identifier: UUID(), name: "Work"),
            Folder(identifier: UUID(), name: "Personal"),
            Folder(identifier: UUID(), name: "Archive")
        ]
        mockDirectory.allFolders = folders
        createSUT()

        // Then
        verify(testName: "with_folders")
    }

    @MainActor
    func testWithSelectedFolder() {
        // Given
        let selectedFolderId = UUID()
        let folders = [
            Folder(identifier: selectedFolderId, name: "Work"),
            Folder(identifier: UUID(), name: "Personal")
        ]
        mockDirectory.allFolders = folders
        let conversation = Conversation(
            identifier: UUID(),
            currentFolderIdentifier: selectedFolderId
        )
        createSUT(conversation: conversation)

        // Then
        verify(testName: "selected_folder")
    }

    @MainActor
    func testLongFolderNames() {
        // Given
        let folders = [
            Folder(identifier: UUID(), name: "Very Long Folder Name That Might Need Truncation"),
            Folder(identifier: UUID(), name: "Another Extremely Long Folder Name To Test Layout")
        ]
        mockDirectory.allFolders = folders
        createSUT()

        // Then
        verify(testName: "long_names")
    }

    // MARK: - Helpers

    @MainActor
    private func createSUT(conversation: Conversation = Conversation(identifier: UUID(), currentFolderIdentifier: nil)) {
        viewModel = FolderPickerViewModel(
            conversation: conversation,
            directory: mockDirectory,
            selectionUseCase: mockSelectionUseCase
        )
        sut = FolderPicker(viewModel: viewModel)
    }

    @MainActor
    private func verify(testName: String) {
        let iPhone14Size = CGSize(width: 390, height: 844)
        let view = sut
            .frame(width: iPhone14Size.width, height: iPhone14Size.height)
            .background(Color(uiColor: ColorTheme.Backgrounds.surface))
            .environment(\.colorScheme, .light)

        snapshotHelper
            .withUserInterfaceStyle(.light)
            .verify(
                matching: UIHostingController(rootView: view),
                named: "light",
                testName: testName
            )

        let darkView = sut
            .frame(width: iPhone14Size.width, height: iPhone14Size.height)
            .background(Color(uiColor: ColorTheme.Backgrounds.surface))
            .environment(\.colorScheme, .dark)

        snapshotHelper
            .withUserInterfaceStyle(.dark)
            .verify(
                matching: UIHostingController(rootView: darkView),
                named: "dark",
                testName: testName
            )
    }
}

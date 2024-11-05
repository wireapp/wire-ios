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

import Foundation

@MainActor
public final class FolderPickerViewModel: ObservableObject {
    @Published private(set) var folders: [Folder] = []

    private let conversation: Conversation
    private let directory: any FolderDirectoryType
    private let selectionUseCase: any MoveConversationToFolderUseCaseType

    public init(
        conversation: Conversation,
        directory: any FolderDirectoryType,
        selectionUseCase: any MoveConversationToFolderUseCaseType
    ) {
        self.conversation = conversation
        self.directory = directory
        self.selectionUseCase = selectionUseCase
        loadFolders()
    }

    private func loadFolders() {
        folders = directory.allFolders
    }

    public func isSelected(_ folder: Folder) -> Bool {
        guard let folderID = folder.identifier else { return false }
        return conversation.currentFolderIdentifier == folderID
    }

    public func select(_ folder: Folder) async {
        await selectionUseCase.invoke(folder: folder, conversation: conversation)
    }
}

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

import SwiftUI
import WireDesign

public struct FolderPicker: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: FolderPickerViewModel

    public init(viewModel: FolderPickerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.folders.isEmpty {
                    EmptyState()
                } else {
                    FolderList(
                        viewModel: viewModel,
                        onSelect: { @MainActor folder in
                            try await viewModel.select(folder)
                            dismiss()
                        }
                    )
                }
            }
            .navigationTitle("Move To")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityIdentifier("button.folder.dismiss")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        // TODO: Implement folder creation view
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityIdentifier("button.newfolder.create")
                    }
                }
            }
        }
    }
}

#Preview {
    FolderPicker(
        viewModel: FolderPickerViewModel(
            conversation: Conversation(identifier: UUID(), currentFolderIdentifier: nil),
            directory: PreviewFolderDirectory(
                allFolders: [
                    Folder(identifier: UUID(), name: "Work"),
                    Folder(identifier: UUID(), name: "Personal")
                ]
            ),
            selectionUseCase: PreviewMoveConversationToFolderUseCase()
        )
    )
}

struct PreviewFolderDirectory: FolderDirectoryTypeProtocol {
    let allFolders: [Folder]
}

struct PreviewMoveConversationToFolderUseCase: MoveConversationToFolderUseCaseType {
    func invoke(folder: Folder, conversation: Conversation) async throws {}
}

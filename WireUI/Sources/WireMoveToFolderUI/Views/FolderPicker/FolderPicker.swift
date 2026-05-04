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

import SwiftUI
import WireDesign
import WireReusableUIComponents

public struct FolderPicker: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: FolderPickerViewModel
    private let isContextMenuAllowed: Bool
    let conversationName: String

    public init(
        viewModel: FolderPickerViewModel,
        isContextMenuAllowed: Bool,
        conversationName: String
    ) {
        self.viewModel = viewModel
        self.isContextMenuAllowed = isContextMenuAllowed
        self.conversationName = conversationName
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.folders.isEmpty {
                    EmptyState()
                } else {
                    folderList
                }
            }
            .background(Color.viewBackground)
            .navigationTitle(Text("folder.picker.title", tableName: "Localizable", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton(
                        action: didTapClose,
                        accessibilityLabel: String(
                            localized: "folderPicker.close.label",
                            table: "Accessibility",
                            bundle: .module
                        )
                    )
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        CreateFolder(
                            viewModel: viewModel.createFolderViewModel,
                            conversationName: conversationName,
                            onFolderCreated: { [weak viewModel] createdFolder in
                                guard let viewModel else { return }
                                Task {
                                    do {
                                        try await viewModel.select(createdFolder)
                                        dismiss()
                                    } catch {
                                        // TODO: [WPB-12173] Move WireLogger to a dedicated Swift Package Manager module for modular logging support
                                        assertionFailure(
                                            "Failed to move conversation to folder: \(error.localizedDescription)"
                                        )
                                    }
                                }
                            },
                            isContextMenuAllowed: isContextMenuAllowed
                        )
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityIdentifier("button.newfolder.create")
                    }
                }
            }
        }
    }

    private var folderList: some View {
        List(viewModel.folders, id: \.identifier) { folder in
            FolderRow(
                folder: folder,
                isSelected: viewModel.isSelected(folder),
                action: {
                    Task {
                        do {
                            try await viewModel.select(folder)
                            dismiss()
                        } catch {
                            // TODO: [WPB-12173] Move WireLogger to a dedicated Swift Package Manager module for modular logging support
                            assertionFailure("Failed to select folder: \(error.localizedDescription)")
                        }
                    }
                }
            )
            .listRowBackground(Color(ColorTheme.Backgrounds.surface))
        }
        .accessibilityIdentifier("list.folders")
    }

    private func didTapClose() {
        dismiss()
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
            updateConversationFolderUseCase: PreviewMoveConversationToFolderUseCase(),
            createFolderUseCase: PreviewCreateConversationFolderUseCase()
        ),
        isContextMenuAllowed: true,
        conversationName: "Test"
    )
}

struct PreviewFolderDirectory: FolderDirectoryTypeProtocol {
    let allFolders: [Folder]
}

struct PreviewMoveConversationToFolderUseCase: UpdateConversationFolderUseCaseProtocol {
    func invoke(conversationID: UUID, folderID: UUID) async throws {}

}

struct PreviewCreateConversationFolderUseCase: CreateConversationFolderUseCaseProtocol {
    func invoke(name: String) async throws -> Folder {
        Folder(identifier: UUID(), name: "Test")
    }
}

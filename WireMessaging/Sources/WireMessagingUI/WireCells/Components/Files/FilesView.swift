//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import Combine
import QuickLook
package import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

package struct FilesView: FilesViewProtocol {
    package var isBrowsing: Bool { false }
    @StateObject package var viewModel: FilesViewModel
    @Environment(\.dismiss) var dismiss

    package init(viewModel: @autoclosure @escaping () -> FilesViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    package var body: some View {
        ZStack {
            ColorTheme.Backgrounds.background.color
                .ignoresSafeArea(.all)

            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                        .progressViewStyle(.circular)
                case let .received(items):
                    VStack(spacing: 0) {
                        if items.isEmpty {
                            Spacer()
                            FilesInfoView(info: .noFilesFound(scope: .oneConversation))
                            Spacer()
                        } else {
                            filesList
                                .listStyle(.plain)
                                .refreshable { reloadTask(refreshing: true) }
                        }

                        if viewModel.isFoldersEnabled {
                            CreateFolderCTA {
                                viewModel.onCreateFolder()
                            }
                        }
                    }
                case .pending:
                    FilesInfoView(info: .preparingFiles)
                case .error:
                    FilesInfoView(info: .error, onReload: {
                        reloadTask()
                    })
                }
            }
            .quickLookPreview($viewModel.viewingURL) // TODO: [WPB-19395] Temporary implementation
            .navigationTitle(viewModel.title ?? Strings.Files.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar) // shows navigation bar divider
            .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
            .interactiveDismissDisabled()
            .toolbar { toolbarContent }
            .onAppear { reloadTask() }
            .alert(
                item: $viewModel.alert,
                title: { Text($0.title) },
                message: { Text($0.message) },
                actions: { _ in confirmButton }
            )
            .sheet(item: $viewModel.sheetNavigation) { navigationItem in
                switch navigationItem {
                case let .editTags(fileItem: fileItem):
                    TagsEditView(
                        fileItem: fileItem,
                        useCases: .init(
                            updateTags: viewModel.useCases.updateTags,
                            getSuggestions: viewModel.useCases.getTagSuggestions
                        ),
                        postSaveAction: {
                            await viewModel.reload()
                        }
                    )
                case let .moveToFolder(fileItem):
                    viewModel.moveToFolderView(item: fileItem)
                }
            }
            .sheet(
                item: $viewModel.fileRenameView,
                onDismiss: {
                    if viewModel.didRenameFile {
                        reloadTask()
                        viewModel.didRenameFile = false
                    }
                },
                content: { $0 }
            )
            .sheet(
                item: $viewModel.createFolderView,
                onDismiss: {
                    if viewModel.didCreateFolder {
                        reloadTask()
                        viewModel.didCreateFolder = false
                    }
                },
                content: { $0 }
            )
            .fullScreenCover(
                item: $viewModel.isEditing,
                onDismiss: {
                    Task { await viewModel.reload() }
                },
                content: { item in
                    viewModel.editFileView(item: item)
                }
            )
        }
    }

}

// MARK: - Toolbar

private extension FilesView {

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        if !viewModel.folderMenuOptions.isEmpty {
            ToolbarTitleMenu {
                toolBarTitleMenuContent()
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) { closeButton }
    }

    func toolBarTitleMenuContent() -> some View {
        ForEach(viewModel.folderMenuOptions, id: \.self) { option in
            Button(
                option.title,
                systemImage: option == .root ? "rectangle.stack" : "folder"
            ) {
                viewModel.selectFolderMenuOption(option)
            }
        }
    }

    var closeButton: some View {
        Button(
            action: { dismiss() },
            label: {
                Image(.close)
                    .foregroundStyle(SemanticColors.Icon.foregroundDefaultBlack.color)
                    .frame(width: 44, height: 44, alignment: .trailing)
            }
        )
        .accessibilityLabel(Accessibility.Files.close)
        .accessibilityIdentifier("close")
    }
}

private extension FilesViewModel.FolderMenuOption {

    var title: String {
        switch self {
        case let .folder(_, title):
            title
        case .root:
            Strings.Files.navigationTitle
        }
    }

}

#Preview {
    FilesView(viewModel: .preview(isFoldersEnabled: true))
}

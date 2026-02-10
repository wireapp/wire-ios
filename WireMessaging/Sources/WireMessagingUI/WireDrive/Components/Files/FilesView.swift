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
    @Environment(\.wireAccentColor) private var accentColor
    @State private var isSearchFocused = false

    let onOpenRecycleBin: () -> Void
    let onDismissContainer: () -> Void

    package init(
        viewModel: @autoclosure @escaping () -> FilesViewModel,
        onOpenRecycleBin: @escaping () -> Void = {},
        onDismissContainer: @escaping () -> Void = {}
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.onOpenRecycleBin = onOpenRecycleBin
        self.onDismissContainer = onDismissContainer
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
                case .received, .pending:
                    VStack {
                        if viewModel.connectionState == .offline {
                            Spacer()
                            offlineBar.id(UUID())
                            Spacer()
                        }

                        if isSearchFocused {
                            VStack(alignment: .leading, spacing: 15) {
                                FilesFilteringView(viewModel: viewModel.makeFilesFilteringViewModel())
                                FilesSortingView(viewModel: viewModel.makeFilesSortingViewModel())
                            }
                            .padding(.horizontal)
                        }
                        
                        filesList
                    }
                case let .error(isConnectionError):
                    FilesInfoView(info: .error(isConnectionError: isConnectionError), onRetry: {
                        reloadTask()
                    })
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.connectionState)
            .quickLookPreview($viewModel.viewingURL) // TODO: [WPB-19395] Temporary implementation
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar) // shows navigation bar divider
            .toolbarBackground(ColorTheme.Backgrounds.background.color, for: .navigationBar)
            .toolbar { toolbarContent }
            .if(viewModel.showSearchBar, transform: searchView(content:))
            .onAppear { reloadTask() }
            .onReceive(viewModel.triggerReload) { _ in
                Task {
                    await viewModel.reload()
                }
            }
            .alert(
                item: $viewModel.alert,
                title: { Text($0.title) },
                message: { Text($0.message) },
                actions: { _ in confirmButton }
            )
            .sheet(
                item: $viewModel.sheetNavigation,
                onDismiss: {
                    Task { await viewModel.onSheetDismissed() }
                },
                content: { navigationItem in
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
                    case let .shareLink(shareLinkView):
                        shareLinkView
                    case let .renameFile(fileRenameView):
                        fileRenameView
                    case let .create(folderView):
                        folderView
                    case let .versionHistory(versionHistoryView):
                        versionHistoryView
                    case let .moveToFolder(fileItem):
                        viewModel.moveToFolderView(item: fileItem)
                    case .filterByTagsOld:
                        EmptyView()
                    }
                }
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
    
    @ViewBuilder
    private func searchView(content: some View) -> some View {
        content.searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer,
            prompt: Strings.Files.Search.title
        )
        .onReceive(NotificationCenter.default.publisher(
            for: UISearchTextField.textDidBeginEditingNotification
        )) { _ in
            isSearchFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UISearchTextField.textDidEndEditingNotification
        )) { _ in
            isSearchFocused = false
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

        if !viewModel.isRecycleBin {
            ToolbarItem(placement: .navigationBarTrailing) {
                moreActionsButton
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            closeButton
        }
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
            action: { onDismissContainer() },
            label: {
                Image(systemName: "xmark")
            }
        )
        .accessibilityLabel(Accessibility.Files.close)
        .accessibilityIdentifier("close")
        .tint(ColorTheme.Base.primary(accentColor).color)
    }

    var moreActionsButton: some View {
        Menu {
            Button {
                viewModel.onCreate(target: .folder)
            } label: {
                Label {
                    Text(Strings.Files.List.createFolder)
                } icon: {
                    Image(systemName: "folder.badge.plus")
                        .tint(SemanticColors.Icon.foregroundDefaultBlack.color)
                }
            }

            Menu {
                ForEach(viewModel.templates, id: \.self) { template in
                    Button {
                        viewModel.onCreate(target: .file(template))
                    } label: {
                        Label {
                            Text(template.kind.title)
                        } icon: {
                            Image(systemName: template.kind.systemImage)
                                .tint(SemanticColors.Icon.foregroundDefaultBlack.color)
                        }
                    }
                }

            } label: {
                Label {
                    Text(Strings.Files.List.createFile)
                } icon: {
                    Image(systemName: "document.badge.plus")
                        .tint(SemanticColors.Icon.foregroundDefaultBlack.color)
                }
            }

            Button {
                onOpenRecycleBin()
            } label: {
                Label {
                    Text(Strings.Files.openRecycleBin)
                } icon: {
                    Image(systemName: "trash")
                        .tint(SemanticColors.Icon.foregroundDefaultBlack.color)
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .tint(ColorTheme.Base.primary(accentColor).color)
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
    NavigationStack {
        FilesView(viewModel: .preview())
    }
}

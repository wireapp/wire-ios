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
    @Environment(\.wireAccentColor) var accentColor

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
                case .received, .pending:
                    filesList
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
            .toolbar { toolbarContent }
            .onAppear { reloadTask() }
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
                }, content: { navigationItem in
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
                    case let .shareLink(fileItem: fileItem):
                        ShareLinkView(fileItem: fileItem)
                    case let .renameFile(fileRenameView):
                        fileRenameView
                    case let .createFolder(folderView):
                        folderView
                    case .filters(view: _):
                        EmptyView()
                    }
                }
            )
        }
    }

}

// MARK: - Toolbar

private extension FilesView {

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        if viewModel.showCloseButton {
            ToolbarItem(placement: .topBarLeading) { closeButton }
        }

        if !viewModel.folderMenuOptions.isEmpty {
            ToolbarTitleMenu {
                toolBarTitleMenuContent()
            }
        }

        if viewModel.isFoldersEnabled {
            ToolbarItem(placement: .topBarTrailing) {
                menuButton
            }
        }
    }

    var menuButton: some View {
        Menu {
            createFolderButton
        } label: {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(accentColor)
                .frame(width: 44, height: 44, alignment: .trailing)
        }
    }

    var createFolderButton: some View {
        HStack {
            Button {
                viewModel.onCreateFolder()
            } label: {
                HStack {
                    Text(Strings.Files.List.newFolder)
                    Image(systemName: "folder")
                }
            }
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
            action: { dismiss() },
            label: {
                Text(L10n.Localizable.General.close)
                    .foregroundStyle(accentColor)
                    .frame(width: 44, height: 44, alignment: .trailing)
            }
        )
        .accessibilityLabel(Accessibility.Files.close)
        .accessibilityIdentifier("close")
    }
}

private struct CreateFolderCTA: View {

    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: onTap) {
                HStack(alignment: .center, spacing: 20) {
                    Image(systemName: "plus")

                    Text(L10n.Localizable.Conversation.WireCells.Files.List.newFolder)
                        .font(for: .body2)
                    Spacer()
                }
            }
            .tint(ColorTheme.Backgrounds.onSurface.color)
            .padding()
        }
        .contentShape(Rectangle())
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
        FilesView(viewModel: .preview(isFoldersEnabled: true))
    }
}

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
import WireLocators
import WireMessagingDomain
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

package struct FilesView: View {
    package var isBrowsing: Bool { false }
    @StateObject package var viewModel: FilesViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.wireAccentColor) private var accentColor

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
        FilesContentView(
            viewModel: viewModel,
            isBrowsing: isBrowsing,
            backgroundColor: ColorTheme.Backgrounds.background.color,
            toolbarContent: { toolbarContent },
            sheetContent: { sheetContent($0) }
        )
        // FilesView-specific extras
        .onReceive(viewModel.triggerReload) { _ in
            Task {
                await viewModel.reload()
            }
        }
        .fullScreenCover(
            item: $viewModel.isEditing,
            onDismiss: {
                Task { await viewModel.reload() }
            },
            content: { item in
                EditFileView(viewModel: viewModel.editFileViewModel(item: item))
            }
        )
    }
}

// MARK: - Toolbar

private extension FilesView {

    @ToolbarContentBuilder var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            VStack(spacing: 0) {
                Text(viewModel.navigationTitle)
                    .font(for: .h3)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                if let navigationSubtitle = viewModel.navigationSubtitle {
                    Text(navigationSubtitle)
                        .font(for: .subline1)
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                }
            }
        }

        if !viewModel.folderMenuOptions.isEmpty {
            ToolbarTitleMenu {
                toolBarTitleMenuContent()
            }
        }

        if !viewModel.isRecycleBin, !viewModel.isOffline {
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
        .accessibilityIdentifier(Locators.WireDrive.FilesPage.close.rawValue)
        .tint(ColorTheme.Base.primary(accentColor).color)
    }

    var moreActionsButton: some View {
        Menu {
            switch viewModel.selfUserRole {
            case .editor:
                editorActions
            case .viewer:
                viewerActions
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .tint(ColorTheme.Base.primary(accentColor).color)
    }

    private var viewerActions: some View {
        Button {
            onOpenRecycleBin()
        } label: {
            Label {
                Text(Strings.Files.openRecycleBin)
            } icon: {
                Image(systemName: "trash")
                    .tint(ColorTheme.Backgrounds.onBackground.color)
            }
        }
        .accessibilityIdentifier(Locators.WireDrive.FilesPage.recycleBin.rawValue)
    }

    private var editorActions: some View {
        Group {
            Button {
                viewModel.onCreate(target: .folder)
            } label: {
                Label {
                    Text(Strings.Files.List.createFolder)
                } icon: {
                    Image(systemName: "folder.badge.plus")
                        .tint(ColorTheme.Backgrounds.onBackground.color)
                }
            }
            .accessibilityIdentifier(Locators.WireDrive.FilesPage.createFolder.rawValue)

            Menu {
                ForEach(viewModel.templates, id: \.self) { template in
                    Button {
                        viewModel.onCreate(target: .file(template))
                    } label: {
                        Label {
                            Text(template.kind.title)
                        } icon: {
                            Image(systemName: template.kind.systemImage)
                                .tint(ColorTheme.Backgrounds.onBackground.color)
                        }
                    }
                }

            } label: {
                Label {
                    Text(Strings.Files.List.createFile)
                } icon: {
                    Image(systemName: "document.badge.plus")
                        .tint(ColorTheme.Backgrounds.onBackground.color)
                }
            }
            .accessibilityIdentifier(Locators.WireDrive.FilesPage.createFile.rawValue)

            Button {
                onOpenRecycleBin()
            } label: {
                Label {
                    Text(Strings.Files.openRecycleBin)
                } icon: {
                    Image(systemName: "trash")
                        .tint(ColorTheme.Backgrounds.onBackground.color)
                }
            }
            .accessibilityIdentifier(Locators.WireDrive.FilesPage.recycleBin.rawValue)
        }
    }
}

// MARK: - Sheet Navigation

private extension FilesView {
    @ViewBuilder
    func sheetContent(_ navigationItem: FilesViewModel.SheetNavigation) -> some View {
        switch navigationItem {
        case let .create(target):
            CreateFileView(viewModel: viewModel.createFileViewModel(target: target))
        case let .editTags(fileItem: item):
            TagsEditView(
                fileItem: item,
                useCases: .init(
                    updateTags: viewModel.useCases.updateTags,
                    getSuggestions: viewModel.useCases.getTagSuggestions
                ),
                postSaveAction: {
                    await viewModel.reload()
                }
            )
        case let .shareLink(item):
            ShareLinkView(viewModel: viewModel.shareLinkViewModel(item: item))
        case let .renameFile(item):
            FileRenameView(viewModel: viewModel.fileRenameViewModel(item: item))
        case let .versionHistory(item):
            FileVersioningView(viewModel: viewModel.fileVersioningViewModel(item: item))
        case let .moveToFolder(item):
            MoveToFolderView(viewModel: viewModel.moveToFolderViewModel(item: item))
        }
    }
}

// MARK: - folder menu title

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

// MARK: - template / create file

private extension WireDriveFileTemplate.Kind {
    var title: String {
        switch self {
        case .document:
            Strings.Files.List.CreateFile.document
        case .spreadsheet:
            Strings.Files.List.CreateFile.spreadsheet
        case .presentation:
            Strings.Files.List.CreateFile.presentation
        }
    }

    var systemImage: String {
        switch self {
        case .document:
            "text.document"
        case .spreadsheet:
            "tablecells"
        case .presentation:
            "sparkles.tv"
        }
    }
}

// MARK: - Preview

#Preview("Editor mode") {
    NavigationStack {
        FilesView(viewModel: .preview())
    }
}

#Preview("Viewer mode") {
    NavigationStack {
        FilesView(viewModel: .preview(isBrowsing: false, selfUserRole: .viewer))
    }
}

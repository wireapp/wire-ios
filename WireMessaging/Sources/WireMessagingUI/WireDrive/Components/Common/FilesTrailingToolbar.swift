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
import WireFoundation
import WireLocators
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

/// Owns the trailing controls and menu availability for a conversation's files and recycle bin.
struct FilesTrailingToolbar: ToolbarContent {

    struct ActionHandlers {
        let onOpenRecycleBin: () -> Void
        let onDismissContainer: () -> Void
        let onUploadFiles: () -> Void
        let onUploadMedia: () -> Void
    }

    @ObservedObject var viewModel: FilesViewModel
    @Environment(\.wireAccentColor) private var accentColor

    let actionHandlers: ActionHandlers

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 5) {
                if canEmptyRecycleBin {
                    deleteAllButton
                }

                if !viewModel.isOffline {
                    if isSelecting {
                        doneActionButton
                    } else if showMoreButton {
                        moreButton
                    }
                }

                if !isSelecting {
                    closeButton
                }
            }
        }
    }
}

private extension FilesTrailingToolbar {

    var isSelecting: Bool {
        viewModel.multipleSelection == .active
    }

    var canEmptyRecycleBin: Bool {
        viewModel.selfUserRole == .editor && viewModel.isRecycleBin && !isSelecting && !viewModel.state.items
            .isEmpty && viewModel.isBulkActionsEnabled && !viewModel.isOffline
    }

    var canSelectItems: Bool {
        viewModel.selfUserRole == .editor && !viewModel.state.items.isEmpty && viewModel.isBulkActionsEnabled
    }

    var canCreateItems: Bool {
        viewModel.selfUserRole == .editor && !viewModel.isRecycleBin
    }

    var canUploadItems: Bool {
        viewModel.uploadDestinationPath != nil && viewModel.selfUserRole == .editor && !viewModel
            .isRecycleBin && viewModel.isDriveDirectUploadsEnabled
    }

    var showMoreButton: Bool {
        !viewModel.isRecycleBin || (viewModel.isRecycleBin && canSelectItems)
    }

    var deleteAllButton: some View {
        Button(
            action: {
                viewModel.selectAllItems()
                viewModel.isPresentingDeleteConfirmation = true
            },
            label: {
                Image(systemName: "trash")
            }
        )
        .accessibilityIdentifier(Locators.WireDrive.FilesPage.deleteAll.rawValue)
        .tint(ColorTheme.Base.primary(accentColor).color)
    }

    var closeButton: some View {
        Button(
            action: { actionHandlers.onDismissContainer() },
            label: {
                Image(systemName: "xmark")
            }
        )
        .accessibilityLabel(Accessibility.Files.close)
        .accessibilityIdentifier(Locators.WireDrive.FilesPage.close.rawValue)
        .tint(ColorTheme.Base.primary(accentColor).color)
    }

    var doneActionButton: some View {
        Button {
            viewModel.enableMultipleSelection(false)
        } label: {
            Text(L10n.Localizable.General.done)
        }
        .accessibilityIdentifier(Locators.WireDrive.FilesPage.done)
        .tint(ColorTheme.Base.primary(accentColor).color)
    }

    var moreButton: some View {
        Menu {
            if canSelectItems {
                selectItemsButton
            }

            if canCreateItems {
                createFolderButton
                createFileMenu
            }

            if canUploadItems {
                uploadActions
            }

            if !viewModel.isRecycleBin {
                recycleBinButton
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .tint(ColorTheme.Base.primary(accentColor).color)
        .accessibilityIdentifier(viewModel.isRecycleBin ? Locators.WireDrive.FilesPage.moreOptionRecycleBin
            .rawValue : Locators.WireDrive.FilesPage.moreOptions.rawValue)
    }

    var recycleBinButton: some View {
        Button {
            actionHandlers.onOpenRecycleBin()
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

    var selectItemsButton: some View {
        Button {
            viewModel.enableMultipleSelection(true)
        } label: {
            Label {
                Text(Strings.Files.List.selectItems)
            } icon: {
                Image(systemName: "checkmark.circle")
                    .tint(ColorTheme.Backgrounds.onBackground.color)
            }
        }
        .accessibilityIdentifier(Locators.WireDrive.FilesPage.selectItems.rawValue)
    }

    var createFolderButton: some View {
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
    }

    var createFileMenu: some View {
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
                .accessibilityIdentifier(Locators.WireDrive.FilesPage.createFileTemplate(template.kind.identifier))
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
    }

    var uploadActions: some View {
        Menu {
            Button {
                actionHandlers.onUploadFiles()
            } label: {
                Label {
                    Text(Strings.Files.Upload.Menu.file)
                } icon: {
                    Image(systemName: "document.badge.arrow.up")
                        .tint(ColorTheme.Backgrounds.onBackground.color)
                }
            }
            .accessibilityIdentifier(Locators.WireDrive.UploadsPage.uploadFile.rawValue)

            Button {
                actionHandlers.onUploadMedia()
            } label: {
                Label {
                    Text(Strings.Files.Upload.Menu.media)
                } icon: {
                    Image(systemName: "photo.badge.plus")
                        .tint(ColorTheme.Backgrounds.onBackground.color)
                }
            }
            .accessibilityIdentifier(Locators.WireDrive.UploadsPage.uploadMedia.rawValue)

        } label: {
            Label {
                Text(Strings.Files.Upload.Menu.upload)
            } icon: {
                Image(systemName: "arrow.up.folder")
                    .tint(ColorTheme.Backgrounds.onBackground.color)
            }
        }
        .accessibilityIdentifier(Locators.WireDrive.FilesPage.upload.rawValue)
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

    var identifier: String {
        switch self {
        case .document:
            "document"
        case .spreadsheet:
            "spreadsheet"
        case .presentation:
            "presentation"
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

// MARK: - Previews

private struct FilesTrailingToolbarPreview: View {
    @StateObject private var viewModel = FilesViewModel.preview()

    var isSelecting = false

    var body: some View {
        NavigationStack {
            ColorTheme.Backgrounds.surface.color
                .navigationTitle(Strings.Files.navigationTitle)
                .toolbar {
                    FilesTrailingToolbar(
                        viewModel: viewModel,
                        actionHandlers: .init(
                            onOpenRecycleBin: {},
                            onDismissContainer: {},
                            onUploadFiles: {},
                            onUploadMedia: {}
                        )
                    )
                }
                .task {
                    await viewModel.setup()
                    viewModel.enableMultipleSelection(isSelecting)
                }
        }
    }
}

#Preview("Files toolbar") {
    FilesTrailingToolbarPreview()
}

#Preview("Selecting files") {
    FilesTrailingToolbarPreview(isSelecting: true)
}

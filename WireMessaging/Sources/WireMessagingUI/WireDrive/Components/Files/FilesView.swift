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
import Photos
import PhotosUI
import QuickLook
package import SwiftUI
import WireDesign
import WireFoundation
import WireLogging
import WireMessagingDomain
import WireReusableUIComponents

private typealias Strings = L10n.Localizable.Conversation.WireCells

package struct FilesView: View {
    package var isBrowsing: Bool { false }
    @StateObject package var viewModel: FilesViewModel
    @Environment(\.dismiss) var dismiss

    let onOpenRecycleBin: () -> Void
    let onDismissContainer: () -> Void
    let trackerHeight: CGFloat

    @State private var isFileImporterPresented = false
    @State private var isMediaPickerPresented = false
    @State private var pickedMedia: [PhotosPickerItem] = []

    package init(
        viewModel: @autoclosure @escaping () -> FilesViewModel,
        trackerHeight: CGFloat = 0,
        onOpenRecycleBin: @escaping () -> Void = {},
        onDismissContainer: @escaping () -> Void = {}
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.trackerHeight = trackerHeight
        self.onOpenRecycleBin = onOpenRecycleBin
        self.onDismissContainer = onDismissContainer
    }

    package var body: some View {
        FilesContentView(
            viewModel: viewModel,
            isBrowsing: isBrowsing,
            backgroundColor: ColorTheme.Backgrounds.background.color,
            trackerHeight: trackerHeight,
            toolbarContent: { toolbarContent },
            sheetContent: { sheetContent($0) }
        )
        // FilesView-specific extras
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.data],
            allowsMultipleSelection: true,
            onCompletion: { result in
                Task { await handleFileImport(result) }
            }
        )
        .photosPicker(
            isPresented: $isMediaPickerPresented,
            selection: $pickedMedia,
            maxSelectionCount: WireDriveDirectUploadLimits.maxFilesPerBatch,
            matching: .any(of: [.images, .videos]),
            photoLibrary: .shared()
        )
        .onChange(of: pickedMedia) { _, newValue in
            guard !newValue.isEmpty else { return }
            Task { await handleMediaPick(newValue) }
        }
        .onReceive(viewModel.triggerReload) { _ in
            Task {
                await viewModel.reload(refreshing: true)
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
        .deletionConfirmationDialog(
            isPresented: $viewModel.isPresentingDeleteConfirmation,
            title: deleteConfirmationTitle,
            buttonText: deleteConfirmationButtonText,
            confirm: { viewModel.deleteSelectedItems() }
        )
        .restorationConfirmationDialog(
            isPresented: $viewModel.isPresentingRestoreConfirmation,
            title: restoreConfirmationTitle,
            buttonText: Strings.Files.Restore.confirmation,
            confirm: { viewModel.restoreSelectedItems() }
        )
    }

    private var restoreConfirmationTitle: String {
        if viewModel.selectedItems.count == 1 {
            let item = viewModel.selectedItems.first!
            if item.kind == .folder {
                return Strings.RecycleBin.Item.RestoreFolderConfirmation.title(item.name)
            } else {
                return Strings.RecycleBin.Item.RestoreFileConfirmation.title(item.name)
            }

        } else {
            return Strings.Files.Restore.title("\(viewModel.selectedItems.count)")
        }
    }

    private var deleteConfirmationTitle: String {
        if viewModel.selectedItems.count == 1 {
            let item = viewModel.selectedItems.first!
            if viewModel.isRecycleBin {
                if item.kind == .folder {
                    return Strings.RecycleBin.Item.DeleteFolderConfirmation.title(item.name)
                } else {
                    return Strings.RecycleBin.Item.DeleteFileConfirmation.title(item.name)
                }
            } else {
                if item.kind == .folder {
                    return Strings.Files.Item.DeleteFolderConfirmation.title(item.name)
                } else {
                    return Strings.Files.Item.DeleteFileConfirmation.title(item.name)
                }
            }

        } else {
            return viewModel.isRecycleBin ? Strings.Files.DeletePermanently
                .title("\(viewModel.selectedItems.count)") : Strings
                .Files.DeleteToRecycleBin.title("\(viewModel.selectedItems.count)")
        }
    }

    private var deleteConfirmationButtonText: String {
        viewModel.isRecycleBin ? Strings.Files.DeletePermanently.confirmation : Strings.Files.DeleteToRecycleBin
            .confirmation
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

        FilesTrailingToolbar(
            viewModel: viewModel,
            actionHandlers: toolbarTrailingActionHandlers
        )
    }

    var toolbarTrailingActionHandlers: FilesTrailingToolbar.ActionHandlers {
        .init(
            onOpenRecycleBin: onOpenRecycleBin,
            onDismissContainer: onDismissContainer,
            onUploadFiles: { isFileImporterPresented = true },
            onUploadMedia: {
                Task {
                    pickedMedia = []
                    guard await viewModel.requestPhotosPermissions() else { return }
                    isMediaPickerPresented = true
                }
            }
        )
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
        case let .moveToFolder(items):
            MoveToFolderView(viewModel: viewModel.moveToFolderViewModel(items: items))
        }
    }
}

// MARK: - Uploads

private extension FilesView {

    func handleFileImport(_ result: Result<[URL], any Error>) async {
        switch result {
        case let .success(urls):
            // Document picker URLs are security scoped, so the uploader must be told to open access
            // before reading them.
            let sources = urls.map { url in
                WireDriveDirectUploadSource(
                    url: url,
                    fileName: url.lastPathComponent,
                    fileType: UTType(filenameExtension: url.pathExtension),
                    isSecurityScoped: true
                )
            }
            await viewModel.enqueueUploads(sources: sources)

        case let .failure(error):
            WireLogger.wireDrive.error("drive upload file import failed: \(error)")
            viewModel.showImportFailedAlert()
        }
    }

    func handleMediaPick(_ items: [PhotosPickerItem]) async {
        await viewModel.enqueueUploads(mediaItems: items)
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

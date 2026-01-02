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

import SwiftUI
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireMessagingDomainSupport

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct FilesItemView: View {

    @StateObject private var viewModel: FilesItemViewModel
    @ScaledMetric private var imageHeight: CGFloat = 28

    @Environment(\.wireAccentColor) private var wireAccentColor

    private let menuActions: [FilesItemViewModel.ItemAction]

    init(
        viewModel: @autoclosure @escaping () -> FilesItemViewModel,
        menuActions: [FilesItemViewModel.ItemAction]
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.menuActions = menuActions
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {

                Image(viewModel.icon.resource)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: imageHeight)
                    .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.fileName)
                        .font(for: .body2)
                        .lineLimit(1)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                    HStack(spacing: 5) {
                        let tagsInfo = viewModel.tagsInfo

                        if let firstTag = tagsInfo.firstTag {
                            Text(firstTag)
                                .font(for: .subline1)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .foregroundStyle(ColorTheme.Base.primary(wireAccentColor).color)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 5)
                                .background {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(ColorTheme.Base.primaryVariant(wireAccentColor).color)
                                }
                        }

                        if let additionalTagsIndicator = tagsInfo.additionalTagsIndicator {
                            Text(additionalTagsIndicator)
                                .font(for: .subline1)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .foregroundStyle(ColorTheme.Base.primary(wireAccentColor).color)
                                .padding(.trailing, 2)
                        }

                        Text(viewModel.subtitle ?? "")
                            .font(for: .subline1)
                            .lineLimit(1)
                            .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    }
                }
                Spacer()

                Menu {
                    if menuActions.contains(.open) {
                        Button(action: open) {
                            Label(Strings.Files.Item.Menu.open, systemImage: "arrow.up.forward.square")
                        }
                        .disabled(viewModel.isDownloading)
                        
                        if viewModel.isDownloadOptionAvailable {
                            Button(action: download) {
                                Label(Strings.Files.Item.Menu.download, systemImage: "square.and.arrow.down")
                            }
                        }
                    }

                    if menuActions.contains(.showVersionHistory) {
                        Button(action: showVersionHistory) {
                            Label(
                                Strings.Files.Item.Menu.versionHistory,
                                systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
                            )
                        }
                    }

                    if menuActions.contains(.edit), viewModel.isEditable {
                        Button(action: editFile) {
                            Label(Strings.Files.Item.Menu.editFile, systemImage: "square.and.pencil")
                        }
                    }

                    Divider()

                    if menuActions.contains(.rename) {
                        Button(action: rename) {
                            Label(Strings.Files.Item.Menu.rename, systemImage: "pencil")
                        }
                    }

                    if menuActions.contains(.moveToFolder) {
                        Button(action: moveToFolder) {
                            Label(Strings.Files.Item.Menu.moveToFolder, systemImage: "folder")
                        }
                    }

                    if menuActions.contains(.editTags) {
                        Button(action: editTags) {
                            Label(Strings.Files.Item.Menu.addOrRemoveTags, systemImage: "tag")
                        }
                    }

                    if menuActions.contains(.restore) {
                        Button(action: restore) {
                            Label(Strings.RecycleBin.Item.Menu.restore, systemImage: "arrow.uturn.backward")
                        }
                    }

                    if menuActions.contains(.deletePermanently) {
                        Button(
                            role: .destructive,
                            action: { delete(permanently: true) },
                            label: { Label(Strings.RecycleBin.Item.Menu.delete, systemImage: "trash.fill") }
                        )
                    }
                    
                    if menuActions.contains(.deleteToRecycleBin) {
                        Button(
                            role: .destructive,
                            action: { delete(permanently: false) },
                            label: { Label(Strings.Files.Item.Menu.delete, systemImage: "trash.fill") }
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                        .frame(minHeight: 24)
                        .padding(.horizontal, 16)
                }
                .tint(nil)
                .menuOrder(.fixed)
                .deletionConfirmationDialog( // delete file to recycle bin
                    isPresented: $viewModel.isPresentingDeleteFileToRecycleBinConfirmation,
                    title: Strings.Files.Item.DeleteFileConfirmation.title(viewModel.fileName),
                    buttonText: Strings.Files.Item.DeleteConfirmation.button,
                    confirm: { confirmDelete(permanently: false) }
                )
                .deletionConfirmationDialog( // delete folder to recycle bin
                    isPresented: $viewModel.isPresentingDeleteFolderToRecycleBinConfirmation,
                    title: Strings.Files.Item.DeleteFolderConfirmation.title(viewModel.fileName),
                    buttonText: Strings.Files.Item.DeleteConfirmation.button,
                    confirm: { confirmDelete(permanently: false) }
                )
                .deletionConfirmationDialog( // delete file permanently
                    isPresented: $viewModel.isPresentingDeleteFilePermanentlyConfirmation,
                    title: Strings.RecycleBin.Item.DeleteFileConfirmation.title(viewModel.fileName),
                    buttonText: Strings.RecycleBin.Item.DeleteConfirmation.button,
                    confirm: { confirmDelete(permanently: true) }
                )
                .deletionConfirmationDialog( // delete folder permanently
                    isPresented: $viewModel.isPresentingDeleteFolderPermanentlyConfirmation,
                    title: Strings.RecycleBin.Item.DeleteFolderConfirmation.title(viewModel.fileName),
                    buttonText: Strings.RecycleBin.Item.DeleteConfirmation.button,
                    confirm: { confirmDelete(permanently: true) }
                )
                .restorationConfirmationDialog( // restore file
                    isPresented: $viewModel.isPresentingRestoreFileConfirmation,
                    title: Strings.RecycleBin.Item.RestoreFileConfirmation.title(viewModel.fileName),
                    buttonText: Strings.RecycleBin.Item.RestoreFileConfirmation.button,
                    confirm: { confirmRestore() }
                )
                .restorationConfirmationDialog( // restore folder
                    isPresented: $viewModel.isPresentingRestoreFolderConfirmation,
                    title: Strings.RecycleBin.Item.RestoreFolderConfirmation.title(viewModel.fileName),
                    buttonText: Strings.RecycleBin.Item.RestoreFolderConfirmation.button,
                    confirm: { confirmRestore() }
                )
                .restorationConfirmationDialog( // restore parent folder (topmost folder in recycle bin)
                    isPresented: $viewModel.isPresentingRestoreParentConfirmation,
                    title: Strings.RecycleBin.Item.RestoreParentConfirmation
                        .title(viewModel.nameOfTopmostFolderInRecycleBin),
                    buttonText: Strings.RecycleBin.Item.RestoreParentConfirmation.button,
                    confirm: { confirmRestore() }
                )
            }
            .padding(.top, 8)
            .padding(.bottom, 5) // Less padding to accommodate progress bar

            ProgressView(value: viewModel.progress, total: 1)
                .opacity(viewModel.progress == nil ? 0 : 1)
                .progressViewStyle(AssetProgressStyle(fillColor: progressColor))

            Divider()
        }
        .contentShape(Rectangle()) // Tap area
    }

    private func open() {
        Task { await viewModel.open() }
    }

    private func editFile() {
        Task { await viewModel.edit() }
    }

    private func download() {
        Task { await viewModel.download() }
    }

    private func showVersionHistory() {
        Task { await viewModel.showVersionHistory() }
    }

    private func rename() {
        Task { await viewModel.rename() }
    }

    private func moveToFolder() {
        Task { await viewModel.moveToFolder() }
    }

    private func editTags() {
        Task { await viewModel.onItemAction(.editTags, viewModel.item) }
    }

    private func restore() {
        viewModel.showRestoreConfirmation()
    }

    private func delete(permanently: Bool) {
        viewModel.showDeleteConfirmation(deletePermanently: permanently)
    }

    private func confirmDelete(permanently: Bool) {
        Task { await viewModel.confirmDelete(permanently: permanently) }
    }

    private func confirmRestore() {
        Task { await viewModel.confirmRestore() }
    }

    private var progressColor: Color {
        viewModel.showErrorState ? ColorTheme.Base.error.color : ColorTheme.Base.primary(wireAccentColor).color
    }

}

private extension View {
    @ViewBuilder
    func deletionConfirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        buttonText: String,
        confirm: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            title,
            isPresented: isPresented,
            titleVisibility: .visible,
            actions: {
                Button(
                    buttonText,
                    role: .destructive,
                    action: confirm
                )
            }
        )
    }

    @ViewBuilder
    func restorationConfirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        buttonText: String,
        confirm: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            title,
            isPresented: isPresented,
            titleVisibility: .visible,
            actions: {
                Button(
                    buttonText,
                    action: confirm
                )
            }
        )
    }
}

#Preview {
    VStack(spacing: 0) {
        FilesItemView(
            viewModel: .preview(),
            menuActions: .menuActions(browsing: true, recycleBin: false, foldersEnabled: true, collaboraEnabled: true)
        )
        
        FilesItemView(
            viewModel: .preview(),
            menuActions: .menuActions(browsing: false, recycleBin: false, foldersEnabled: true, collaboraEnabled: true)
        )
        
        FilesItemView(
            viewModel: .preview(tags: ["urgent"]),
            menuActions: .menuActions(browsing: false, recycleBin: false, foldersEnabled: true, collaboraEnabled: true)
        )
        
        FilesItemView(
            viewModel: .preview(tags: ["urgent", "funny", "important"]),
            menuActions: .menuActions(browsing: false, recycleBin: true, foldersEnabled: true, collaboraEnabled: true)
        )
    }
}

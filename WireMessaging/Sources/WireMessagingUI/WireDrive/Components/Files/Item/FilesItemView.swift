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
import WireMessagingDomainSupport

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct FilesItemView: View {

    @StateObject private var viewModel: FilesItemViewModel

    private let iconSpaceWidth: CGFloat = 56 // this is explicitly not supposed to scale.
    @ScaledMetric private var iconSpaceHeight: CGFloat = 28
    @ScaledMetric private var iconHorizontalPadding: CGFloat = 7
    @ScaledMetric private var scale: CGFloat = 1

    @Environment(\.wireAccentColor) private var wireAccentColor

    init(viewModel: @autoclosure @escaping () -> FilesItemViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                icon().accessibilitySortPriority(3)

                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.fileName)
                        .font(for: .body2)
                        .lineLimit(1)
                        .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                    infoRow()
                }
                .accessibilityElement(children: .combine)
                .accessibilitySortPriority(2)

                Spacer()

                Menu {
                    menuContent()
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                        .frame(minHeight: 24)
                        .padding(.horizontal, 16)
                }
                .tint(nil)
                .menuOrder(.fixed)
                .accessibilitySortPriority(1)
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
            .padding(.vertical, 8)

            Divider()

        }.contentShape(Rectangle()) // Tap area
    }

    @ViewBuilder
    private func icon() -> some View {
        switch viewModel.fileTracker.state {
        case .notLoaded,
             .loaded(showReadyToOpen: false),
             .loaded(showReadyToOpen: true) where viewModel.isAvailableOffline,
             .failed:
            fileTypeIcon()
        case .loaded(showReadyToOpen: true):
            progressIcon(progress: 1, readyToOpen: true)
        case let .loading(progress: progress, _):
            progressIcon(progress: progress, readyToOpen: false)
        }
    }

    @ViewBuilder
    private func fileTypeIcon() -> some View {
        Image(viewModel.icon.imageResource)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay(alignment: .bottomTrailing) {
                if viewModel.showReadOnlyIcon {
                    FileIconBadge(iconName: "eye", for: viewModel.item.icon)
                } else if viewModel.item.publicLinkID != nil {
                    FileIconBadge(iconName: "link", for: viewModel.item.icon)
                }
            }
            .padding(.horizontal, iconHorizontalPadding)
            .frame(minWidth: iconSpaceWidth)
            .frame(height: iconSpaceHeight)
            .accessibilityLabel(viewModel.icon.accessibilityIconLabel)
    }

    @ViewBuilder
    private func progressIcon(progress: Double, readyToOpen: Bool) -> some View {
        ProgressView(value: progress)
            .progressViewStyle(.wireDriveAsset())
            .padding(.horizontal, iconHorizontalPadding)
            .frame(minWidth: iconSpaceWidth)
            .frame(height: iconSpaceHeight + 3)
            .overlay {
                if viewModel.isDownloadingForOfflineUse {
                    Image(systemName: "arrow.down")
                        .foregroundStyle(wireAccentColor)
                } else if readyToOpen {
                    Image(systemName: "checkmark")
                        .fontWeight(.medium)
                }
            }
            .foregroundStyle(wireAccentColor)
    }

    @ViewBuilder
    private func availableOfflineIcon() -> some View {
        Image(systemName: "arrow.down.circle.fill")
            .resizable()
            .frame(width: 10 * scale, height: 10 * scale)
            .foregroundStyle(ColorTheme.Base.secondaryText.color)
            .accessibilityLabel(Accessibility.Files.availableOffline)
    }

    @ViewBuilder
    private func tagsInfo() -> some View {
        let tagsInfo = viewModel.tagsInfo

        if let firstTag = tagsInfo.firstTag {
            HStack(spacing: 5) {
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

                if let additionalTagsIndicator = tagsInfo.additionalTagsIndicator {
                    Text(additionalTagsIndicator)
                        .font(for: .subline1)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(ColorTheme.Base.primary(wireAccentColor).color)
                        .padding(.trailing, 2)
                }
            }
        }
    }

    @ViewBuilder
    private func infoRowTextLine(_ text: String, error: Bool = false) -> some View {
        let color = error ? ColorTheme.Base.error.color : ColorTheme.Base.secondaryText.color
        Text(text)
            .font(for: .subline1)
            .lineLimit(1)
            .foregroundStyle(color)
    }

    @ViewBuilder
    private func infoRow() -> some View {
        switch viewModel.fileTracker.state {
        case .notLoaded,
             .loaded(showReadyToOpen: false),
             .loaded(showReadyToOpen: true) where viewModel.isAvailableOffline:
            HStack(spacing: 5) {
                if viewModel.isAvailableOffline { availableOfflineIcon() }
                tagsInfo()
                infoRowTextLine(viewModel.subtitle ?? "")
            }
        case .loaded(showReadyToOpen: true):
            infoRowTextLine(Strings.Files.readyToOpenAfterDownload)
        case .loading:
            if viewModel.isDownloadingForOfflineUse {
                downloadingInfoRowTextLine()
            } else {
                infoRowTextLine(Strings.Files.tapToCancelDownload)
            }
        case .failed:
            infoRowTextLine(Strings.Files.downloadFailed, error: true)
        }
    }

    @ViewBuilder
    private func downloadingInfoRowTextLine() -> some View {
        Text(Strings.Files.downloadingFile)
            .font(for: .subline1)
            .lineLimit(1)
            .foregroundStyle(wireAccentColor)
    }

    @ViewBuilder
    private func menuContent() -> some View {
        menuItem(.primaryAction) { item in
            Button {
                viewModel.performAction(item)
            } label: {
                if viewModel.isDownloading {
                    Label(Strings.Files.Item.Menu.cancelDownload, systemImage: "xmark")
                } else {
                    Label(Strings.Files.Item.Menu.open, systemImage: "arrow.up.forward.square")
                }
            }
        }

        menuItem(.shareLink) { item in
            Button {
                viewModel.performAction(item)
            } label: {
                Label(
                    Strings.Files.Item.Menu.shareLink,
                    systemImage: "square.and.arrow.up"
                )
            }.disabled(viewModel.isActionDisabled(.shareLink))
        }

        menuItem(.makeAvailableOffline) { item in
            Button {
                viewModel.performAction(item)
            } label: {
                Label(
                    Strings.Files.Item.Menu.makeAvailableOffline,
                    systemImage: "arrow.down.circle"
                )
            }.disabled(viewModel.isActionDisabled(.makeAvailableOffline))
        }

        menuItem(.removeAvailableOffline) { item in
            Button {
                viewModel.performAction(item)
            } label: {
                Label(
                    Strings.Files.Item.Menu.removeAvailableOffline,
                    systemImage: "xmark.circle"
                )
            }.disabled(viewModel.isActionDisabled(.removeAvailableOffline))
        }

        menuItem(.showVersionHistory) { item in
            Button {
                viewModel.performAction(item)
            } label: {
                Label(
                    Strings.Files.Item.Menu.versionHistory,
                    systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
                )
            }
        }

        menuItem(.edit) { item in
            Button {
                viewModel.performAction(item)
            } label: {
                Label(Strings.Files.Item.Menu.editFile, systemImage: "square.and.pencil")
            }
        }

        Divider()

        menuItem(.rename) { item in
            Button {
                viewModel.performAction(item)
            } label: {
                Label(Strings.Files.Item.Menu.rename, systemImage: "pencil")
            }
        }

        menuItem(.moveToFolder) { item in
            Button {
                viewModel.performAction(item)
            } label: {
                Label(Strings.Files.Item.Menu.moveToFolder, systemImage: "folder")
            }
        }

        menuItem(.editTags) { item in
            Button {
                viewModel.performAction(item)
            } label: {
                Label(Strings.Files.Item.Menu.addOrRemoveTags, systemImage: "tag")
            }
        }

        menuItem(.restore) { item in
            Button {
                viewModel.performAction(item)
            } label: {
                Label(Strings.RecycleBin.Item.Menu.restore, systemImage: "arrow.uturn.backward")
            }
        }

        menuItem(.deletePermanently) { item in
            Button(
                role: .destructive,
                action: { viewModel.performAction(item) },
                label: { Label(Strings.RecycleBin.Item.Menu.delete, systemImage: "trash.fill") }
            )
        }

        menuItem(.deleteToRecycleBin) { item in
            Button(
                role: .destructive,
                action: { viewModel.performAction(item) },
                label: { Label(Strings.Files.Item.Menu.delete, systemImage: "trash.fill") }
            )
        }
    }

    @ViewBuilder
    private func menuItem(
        _ itemAction: FilesItemViewModel.ItemAction,
        @ViewBuilder menuItem: (FilesItemViewModel.ItemAction) -> some View
    ) -> some View {
        if viewModel.menuActions.contains(itemAction) {
            menuItem(itemAction)
                .accessibilityIdentifier("fileMenu.\(itemAction)")
        }
    }

    private func confirmDelete(permanently: Bool) {
        Task { await viewModel.confirmDelete(permanently: permanently) }
    }

    private func confirmRestore() {
        Task { await viewModel.confirmRestore() }
    }
}

extension FilesItemView {
    struct FileIconBadge: View {
        @ScaledMetric private var size: CGFloat = 10
        @ScaledMetric private var innerPadding: CGFloat = 2
        @ScaledMetric private var borderThickness: CGFloat = 1
        @ScaledMetric private var offsetX: CGFloat
        @ScaledMetric private var offsetY: CGFloat

        private let iconName: String

        init(iconName: String, for fileType: WireDriveFileType) {
            self.iconName = iconName

            switch fileType {
            case .folder:
                _offsetX = .init(wrappedValue: 5)
                _offsetY = .init(wrappedValue: 1)
            default:
                _offsetX = .init(wrappedValue: 5)
                _offsetY = .init(wrappedValue: 4)
            }
        }

        var body: some View {
            Image(systemName: iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .fontWeight(.semibold)
                .frame(width: size, height: size)
                .padding(innerPadding)
                .background {
                    Circle()
                        .stroke(lineWidth: borderThickness)
                        .foregroundStyle(ColorTheme.Strokes.outline.color)
                }
                .background {
                    Circle()
                        .foregroundStyle(ColorTheme.Backgrounds.backgroundVariant.color)
                }
                .offset(x: offsetX, y: offsetY)
        }
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
                .accessibilityIdentifier(Locators.WireDrive.FilesItemPage.confirmDeleteButton)
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
                .accessibilityIdentifier(Locators.WireDrive.FilesItemPage.confirmRestoreButton)
            }
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 0) {
            FilesItemView(viewModel: .preview())
            FilesItemView(viewModel: .preview(publicLinkID: "link"))
            FilesItemView(viewModel: .preview(icon: .audio, publicLinkID: "link"))
            FilesItemView(viewModel: .preview(kind: .folder, icon: .folder, publicLinkID: "link"))
            FilesItemView(viewModel: .preview(tags: ["urgent"]))
            FilesItemView(viewModel: .preview(tags: ["urgent", "funny", "important"]))
        }
    }
}

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

struct FilesViewItemView: View {

    @StateObject private var viewModel: FilesItemViewModel
    @ScaledMetric private var imageHeight: CGFloat = 28

    @Environment(\.wireAccentColor) private var wireAccentColor

    private var canRenameFile: Bool
    private var canEditTags: Bool

    init(
        viewModel: @autoclosure @escaping () -> FilesItemViewModel,
        canRenameFile: Bool = false,
        canEditTags: Bool = false,
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.canRenameFile = canRenameFile
        self.canEditTags = canEditTags
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
                    Button(action: open) {
                        Label(Strings.Files.Item.Menu.open, systemImage: "arrow.up.forward.square")
                    }.disabled(viewModel.isDownloading)
                    
                    Button(action: shareLink) {
                        Label(Strings.Files.Item.Menu.shareLink, systemImage: "square.and.arrow.up")
                    }

                    if viewModel.isDownloadOptionAvailable {
                        Button(action: download) {
                            Label(Strings.Files.Item.Menu.download, systemImage: "square.and.arrow.down")
                        }.disabled(viewModel.isDownloading)
                    }

                    if canRenameFile {
                        Button(action: rename) {
                            Label(Strings.Files.Item.Menu.rename, systemImage: "pencil")
                        }
                    }

                    if canEditTags {
                        Button(action: editTags) {
                            Label(Strings.Files.Item.Menu.addOrRemoveTags, systemImage: "tag")
                        }
                    }

                    Button(role: .destructive, action: delete) {
                        Label(Strings.Files.Item.Menu.delete, systemImage: "trash.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                        .frame(minHeight: 24)
                        .padding(.horizontal, 16)
                }
                .tint(nil)
                .menuOrder(.fixed)
                .confirmationDialog(
                    Strings.Files.Item.DeleteConfirmation.title(viewModel.fileName),
                    isPresented: $viewModel.isShowDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(
                        Strings.Files.Item.DeleteConfirmation.deletePermanently,
                        role: .destructive,
                        action: confirmDelete
                    )
                }
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
    
    private func shareLink() {
        //TODO: ...
    }

    private func download() {
        Task { await viewModel.download() }
    }

    private func rename() {
        Task { await viewModel.rename() }
    }

    private func editTags() {
        viewModel.onEditTagsSelected()
    }

    private func delete() {
        viewModel.showDeleteConfirmation()
    }

    private func confirmDelete() {
        Task { await viewModel.confirmDelete() }
    }

    private var progressColor: Color {
        viewModel.showErrorState ? ColorTheme.Base.error.color : ColorTheme.Base.primary(wireAccentColor).color
    }

}

#Preview {
    VStack(spacing: 0) {
        FilesViewItemView(viewModel: .preview())
        FilesViewItemView(viewModel: .preview(), canRenameFile: true, canEditTags: true)
        FilesViewItemView(viewModel: .preview(tags: ["urgent"]), canRenameFile: true, canEditTags: true)
        FilesViewItemView(viewModel: .preview(tags: ["urgent", "funny", "important"]))
    }
}

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

package import SwiftUI
import UniformTypeIdentifiers
import WireDesign
import WireLocators
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells.Files.Upload
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells.Files.Upload

/// The expanded uploads tracker: a header summarising the batch, and one row per file.
package struct WireDriveDirectUploadsSheetView: View {

    @ObservedObject private var viewModel: WireDriveDirectUploadsViewModel

    package init(viewModel: WireDriveDirectUploadsViewModel) {
        self.viewModel = viewModel
    }

    package var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            List {
                ForEach(viewModel.summary.items) { item in
                    WireDriveDirectUploadItemRow(
                        item: item,
                        destinationName: viewModel.currentFolderName,
                        onCancel: { await viewModel.cancel(uploadID: item.id) },
                        onRetry: { await viewModel.retry(uploadID: item.id) }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(ColorTheme.Backgrounds.surface.color)
                }
            }
            .listStyle(.plain)
            .background(ColorTheme.Backgrounds.surface.color)
        }
        .background(ColorTheme.Backgrounds.surface.color)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                viewModel.collapse()
            } label: {
                Image(systemName: "chevron.down")
                    .font(for: .body2)
                    .fontWeight(.semibold)
            }
            .accessibilityLabel(Accessibility.collapse)
            .accessibilityIdentifier(Locators.WireDrive.UploadsPage.collapse)

            Spacer(minLength: 0)

            VStack(spacing: 2) {
                Text(viewModel.title)
                    .font(for: .body2)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                Text(viewModel.subtitle)
                    .font(for: .subline1)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            headerAction
                .frame(minWidth: 24, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder private var headerAction: some View {
        if let action = viewModel.headerAction {
            AsyncButton(action.title) {
                await viewModel.perform(action)
            }
            .font(for: .body2)
            .accessibilityLabel(action.accessibilityLabel)
            .accessibilityIdentifier(
                action == .cancelAll
                    ? Locators.WireDrive.UploadsPage.cancelAll.rawValue
                    : Locators.WireDrive.UploadsPage.retryAll.rawValue
            )
        } else {
            Color.clear.frame(width: 24, height: 1)
        }
    }
}

struct WireDriveDirectUploadItemRow: View {

    let item: WireDriveDirectUploadItem
    let destinationName: String
    let onCancel: () async -> Void
    let onRetry: () async -> Void

    @Environment(\.wireAccentColor) private var accentColor

    @ScaledMetric private var iconSize: CGFloat = 24

    var body: some View {
        HStack(spacing: 12) {
            leadingIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName)
                    .font(for: .body2)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                    .lineLimit(1)
                    .truncationMode(.middle)

                statusLine
            }

            Spacer(minLength: 8)

            actions
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(Locators.WireDrive.UploadsPage.item(item.fileName))
    }

    @ViewBuilder private var leadingIcon: some View {
        switch item.status {
        case .queued, .uploading:
            WireDriveDirectUploadStatusIcon(status: .progress(item.status.progress))

        case .failed:
            WireDriveDirectUploadStatusIcon(status: .failure)

        case .uploaded, .cancelled:
            Image(fileType.imageResource)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
        }
    }

    private var fileType: WireDriveFileType {
        let fileExtension = (item.fileName as NSString).pathExtension
        return .make(type: UTType(filenameExtension: fileExtension), fileExtension: fileExtension)
    }

    @ViewBuilder private var statusLine: some View {
        switch item.status {
        case .queued, .uploading:
            Text(Strings.uploadingFile)
                .font(for: .subline1)
                .foregroundStyle(ColorTheme.Base.primary(accentColor).color)

        case .uploaded:
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .foregroundStyle(ColorTheme.Base.positive.color)
                Text(Strings.uploadedFile)
                    .foregroundStyle(ColorTheme.Base.positive.color)
                Text(formattedSize)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
            }
            .font(for: .subline1)

        case .failed:
            Text(Strings.failedFile)
                .font(for: .subline1)
                .foregroundStyle(ColorTheme.Base.error.color)

        case .cancelled:
            Text(Strings.destination(destinationName))
                .font(for: .subline1)
                .foregroundStyle(ColorTheme.Base.secondaryText.color)
        }
    }

    @ViewBuilder private var actions: some View {
        switch item.status {
        case .queued, .uploading:
            cancelButton

        case .failed:
            if item.isRetryable {
                AsyncButton {
                    await onRetry()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel(
                    Accessibility.retryFile.replacingOccurrences(of: "{0}", with: item.fileName)
                )
                .accessibilityIdentifier(Locators.WireDrive.UploadsPage.retry(item.fileName))
            }

            cancelButton

        case .uploaded, .cancelled:
            EmptyView()
        }
    }

    private var cancelButton: some View {
        AsyncButton {
            await onCancel()
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel(
            Accessibility.cancelFile.replacingOccurrences(of: "{0}", with: item.fileName)
        )
        .accessibilityIdentifier(Locators.WireDrive.UploadsPage.cancel(item.fileName))
    }

    private var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(item.fileSize), countStyle: .file)
    }
}

#Preview("mixed batch") {
    WireDriveDirectUploadsSheetView(viewModel: .preview())
}

#Preview("single file") {
    WireDriveDirectUploadsSheetView(
        viewModel: .preview(items: [.preview(fileName: "MOV_567823.mp4", status: .uploading(progress: 0.6))])
    )
}

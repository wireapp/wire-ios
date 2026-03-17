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
import WireMessagingDomain

struct WireDriveLargeDocumentPreviewView: View {
    private static let imageAspectRatio = CGFloat(8.0 / 3.0)
    private static let errorMessage = L10n.Localizable.Conversation.Message.Attachment.previewNotAvailable
    private static let downloadErrorMessage = L10n.Localizable.Conversation.Message.Attachment.unableToDownload
    private static let loadingMessage = L10n.Localizable.Conversation.Message.Attachment.loadingContent

    let headerIcon: Image
    let headerText: String
    let labelText: String
    let progress: Double?
    let downloadError: Bool
    let url: URL?

    @Environment(\.wireAccentColor) private var wireAccentColor

    var body: some View {
        WireDriveAttachmentPreview(
            progress: progress,
            progressColor: downloadError
                ? ColorTheme.Base.error.color : ColorTheme.Base.primary(wireAccentColor).color
        ) {
            VStack {
                WireDriveDocumentHeaderView(
                    headerIcon: headerIcon,
                    headerText: headerText,
                    labelText: labelText,
                    progress: progress,
                    isError: downloadError
                )
                .background(ColorTheme.Backgrounds.surfaceVariant.color)
                .frame(height: 74) // This might break the UI if text font is too big
                .frame(maxWidth: .infinity)

                previewContainer {
                    if downloadError {
                        errorView(text: Self.downloadErrorMessage)
                    } else {
                        if let url {
                            asyncImage(url: url)
                        } else {
                            errorView(text: Self.errorMessage)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func asyncImage(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                loadingView(text: Self.loadingMessage)
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                errorView(text: Self.errorMessage)
            @unknown default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func previewContainer(@ViewBuilder content: () -> some View)
        -> some View {
        Color.clear
            .aspectRatio(Self.imageAspectRatio, contentMode: .fit)
            .background(alignment: .top) {
                content()
            }
            .clipped()
    }

    @ViewBuilder
    private func loadingView(text: String) -> some View {
        ZStack {
            Color(ColorTheme.Backdrop.background)
            VStack {
                ProgressView()
                    .tint(ColorTheme.Backgrounds.onTransparentDark.color)
                Text(text)
                    .font(for: .subline2)
                    .foregroundColor(ColorTheme.Backgrounds.onTransparentDark.color)
            }
        }
    }

    @ViewBuilder
    private func errorView(text: String) -> some View {
        ZStack {
            Color(ColorTheme.Backdrop.background)
            Text(text)
                .font(for: .subline2)
                .foregroundColor(ColorTheme.Backgrounds.onTransparentDark.color)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

#Preview {
    WireDriveLargeDocumentPreviewView(
        headerIcon: Image(WireDriveFileType.pdf.imageResource),
        headerText: "PDF (336 KB)",
        labelText: "CDR_20220120 Accessibility Review Reviewed Final Plus",
        progress: 0.7,
        downloadError: false,
        url: URL(
            string:
            "https://i.kym-cdn.com/entries/icons/facebook/000/018/012/this_is_fine.jpg"
        )
    )
}

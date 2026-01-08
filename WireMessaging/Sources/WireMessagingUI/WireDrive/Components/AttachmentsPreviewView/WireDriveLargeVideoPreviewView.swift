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

struct WireDriveLargeVideoPreviewView: View {
    private static let errorMessage = L10n.Localizable.Conversation.Message
        .Attachment.previewNotAvailable
    private static let downloadErrorMessage = L10n.Localizable.Conversation
        .Message.Attachment.unableToDownload
    private static let loadingMessage = L10n.Localizable.Conversation.Message
        .Attachment.loadingContent
    private static let defaultAspectRatio = CGFloat(16.0 / 9.0)
    private static let previewCornerRadius = 10.0

    let headerIcon: Image
    let headerText: String
    let labelText: String
    let progress: Double?
    let downloadError: Bool
    let url: URL?
    var imageAspectRatio: CGFloat? = defaultAspectRatio
    let duration: String?

    @Environment(\.wireAccentColor) private var wireAccentColor

    var body: some View {
        WireCellsAttachmentPreview(
            progress: progress,
            progressColor: downloadError
                ? ColorTheme.Base.error.color : ColorTheme.Base.primary(wireAccentColor).color
        ) {
            VStack {
                WireCellsDocumentHeaderView(
                    headerIcon: headerIcon,
                    headerText: headerText,
                    labelText: labelText,
                    progress: progress,
                    isError: downloadError
                )
                .background(ColorTheme.Backgrounds.surfaceVariant.color)
                .frame(height: 74)  // This might break the UI if text font is too big
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
                .overlay(alignment: .bottom) {
                    if let duration {
                        durationView(duration: duration)
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
                    .overlay {
                        PlayIcon()
                            .disabled(false)
                    }
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
            .aspectRatio(imageAspectRatio ?? Self.defaultAspectRatio, contentMode: .fit)
            .background(alignment: .top) {
                content()
            }
            .clipShape(RoundedRectangle(cornerRadius: Self.previewCornerRadius))
    }

    @ViewBuilder
    private func loadingView(text: String) -> some View {
        ZStack {
            Color(ColorTheme.Backdrop.background)
            VStack {
                ProgressView()
                    .tint(ColorTheme.Backgrounds.onTransparentDark.color)
                Text(text)
                    .font(for: .body2)
                    .foregroundColor(ColorTheme.Backgrounds.onTransparentDark.color)
            }
        }
    }

    @ViewBuilder
    private func errorView(text: String) -> some View {
        ZStack {
            Color(ColorTheme.Backdrop.background)
            Text(text)
                .font(for: .body2)
                .foregroundColor(ColorTheme.Backgrounds.onTransparentDark.color)
                .multilineTextAlignment(.center)
                .padding()
        }
    }

    @ViewBuilder
    private func durationView(duration: String) -> some View {
        Text(duration)
            .font(for: .body2)
            .foregroundColor(ColorTheme.Backgrounds.onTransparentDark.color)
            .frame(maxWidth: .infinity)
            .background(ColorTheme.Backdrop.background.color)
            .clipShape(
                UnevenRoundedRectangle(
                    bottomLeadingRadius: Self.previewCornerRadius,
                    bottomTrailingRadius: Self.previewCornerRadius
                )
            )
    }
}

#Preview {
    WireCellsLargeVideoPreviewView(
        headerIcon: Image(FileIcon.pdf.resource),
        headerText: "PDF (336 KB)",
        labelText: "CDR_20220120 Accessibility Review Reviewed Final Plus",
        progress: 0.7,
        downloadError: false,
        url: URL(
            string:
            "https://i.kym-cdn.com/entries/icons/facebook/000/018/012/this_is_fine.jpg"
        ),
        imageAspectRatio: CGFloat(16.0 / 9.0),
        duration: "02:34",
    )
}

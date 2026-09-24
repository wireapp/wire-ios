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

struct WireDriveLargeVideoPreviewView: View {
    private static let errorMessage = L10n.Localizable.Conversation.Message
        .Attachment.previewNotAvailable
    private static let downloadErrorMessage = L10n.Localizable.Conversation
        .Message.Attachment.unableToDownload
    private static let loadingMessage = L10n.Localizable.Conversation.Message
        .Attachment.loadingContent
    private static let defaultAspectRatio = CGFloat(16.0 / 9.0)
    private static let previewCornerRadius = 10.0

    @ScaledMetric private var scale: CGFloat = 1

    let url: URL?
    var imageAspectRatio: CGFloat = defaultAspectRatio
    let duration: String?
    let state: WireDriveFileUITracker.State
    let isAvailableOffline: Bool

    @Environment(\.wireAccentColor) private var wireAccentColor

    var body: some View {
        WireDriveAttachmentPreview {
            previewContainer {
                if let url {
                    asyncImage(url: url)
                } else {
                    errorView(text: Self.errorMessage)
                }
            }
            .overlay(alignment: .bottom) {
                if let duration {
                    durationView(duration: duration)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isAvailableOffline {
                    availableOfflineIcon()
                }
            }
            .background(ColorTheme.Backgrounds.surfaceVariant.color)
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
                    .aspectRatio(imageAspectRatio, contentMode: .fit)
                    .accessibilityIdentifier(Locators.ActiveConversationPage.videoPreview.rawValue)
                    .overlay {
                        switch state {
                        case .notLoaded, .loaded:
                            PlayIcon()
                                .disabled(false)
                        case let .loading(progress, _):
                            darkBackgroundPlayIconView {
                                ProgressView(value: progress)
                                    .progressViewStyle(.wireDriveAsset(strokeColor: .white))
                                    .frame(height: 30)

                                Text(Strings.Files.tapToCancelDownload)
                                    .font(for: .subline1)
                                    .lineLimit(1)
                                    .foregroundStyle(.white)
                                    .padding(.top, 65) // workaround so text shows up below the play icon view
                            }
                        case .failed:
                            darkBackgroundPlayIconView {
                                Text(Strings.Files.downloadFailed)
                                    .font(for: .subline1)
                                    .lineLimit(1)
                                    .foregroundStyle(.white)
                                    .padding(.top, 65)
                            }
                        }
                    }
            case .failure:
                loadingView(text: Self.loadingMessage)
            @unknown default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func darkBackgroundPlayIconView(@ViewBuilder content: () -> some View) -> some View {
        ZStack {
            PlayIcon()
            Color.black.opacity(0.7)
            content()
        }
    }

    @ViewBuilder
    private func previewContainer(@ViewBuilder content: () -> some View)
        -> some View {
        Color.clear
            .aspectRatio(imageAspectRatio, contentMode: .fit)
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

    @ViewBuilder
    private func availableOfflineIcon() -> some View {
        Image(systemName: "arrow.down.circle.fill")
            .resizable()
            .frame(width: 12 * scale, height: 11 + scale)
            .foregroundStyle(ColorTheme.Base.secondaryText.color, .white)
            .accessibilityLabel(Accessibility.Files.availableOffline)
            .padding(6)
    }
}

#Preview {
    let previewCases: [(
        url: URL?,
        state: WireDriveFileUITracker.State
    )] = [
        (
            url: URL(string: "https://i.kym-cdn.com/entries/icons/facebook/000/018/012/this_is_fine.jpg"),
            state: .loading(progress: 0.7, isLargeFile: false)
        ),
        (
            url: URL(string: "https://i.kym-cdn.com/entries/icons/facebook/000/018/012/this_is_fine.jpg"),
            state: .loaded(showReadyToOpen: true)
        ),
        (
            url: URL(string: "https://i.kym-cdn.com/entries/icons/facebook/000/018/012/this_is_fine.jpg"),
            state: .loaded(showReadyToOpen: false)
        ),
        (
            url: URL(string: "https://i.kym-cdn.com/entries/icons/facebook/000/018/012/this_is_fine.jpg"),
            state: .notLoaded
        ),
        (
            url: URL(string: "https://i.kym-cdn.com/entries/icons/facebook/000/018/012/this_is_fine.jpg"),
            state: .failed
        ),
        (
            url: URL?.none,
            state: .loaded(showReadyToOpen: true)
        )
    ]
    ScrollView {
        VStack {
            ForEach(0 ..< previewCases.count, id: \.self) { index in
                let data = previewCases[index]

                WireDriveLargeVideoPreviewView(
                    url: data.url,
                    imageAspectRatio: CGFloat(16.0 / 9.0),
                    duration: "02:34",
                    state: data.state,
                    isAvailableOffline: true
                )
                .padding(.horizontal)
            }
        }
    }
}

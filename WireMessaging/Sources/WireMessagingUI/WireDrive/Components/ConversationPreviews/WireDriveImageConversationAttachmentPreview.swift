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

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct WireDriveImageConversationAttachmentPreview: View {

    let thumbnailURL: URL?
    let state: WireDriveFileUITracker.State
    let isLargePreview: Bool
    let isAvailableOffline: Bool

    @ScaledMetric private var scale: CGFloat = 1

    @Environment(\.wireAccentColor) private var wireAccentColor

    init(
        thumbnailURL: URL?,
        state: WireDriveFileUITracker.State,
        isLargePreview: Bool,
        isAvailableOffline: Bool
    ) {
        self.thumbnailURL = thumbnailURL
        self.state = state
        self.isLargePreview = isLargePreview
        self.isAvailableOffline = isAvailableOffline
    }

    var body: some View {
        WireDriveAttachmentPreview {
            ZStack {
                if let thumbnailURL {
                    AsyncImage(url: thumbnailURL, scale: UIScreen.main.scale) { phase in
                        switch phase {
                        case .empty where !isAssetDownloadError:
                            ProgressView()
                                .tint(ColorTheme.Backgrounds.surface.color)
                        case let .success(image):
                            GeometryReader { geometry in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .accessibilityIdentifier(Locators.ActiveConversationPage.imagePreview.rawValue)
                            }
                        case let .failure(error) where !error.isURLErrorCancelled && !isAssetDownloadError:
                            noPreviewMessageView
                        default:
                            EmptyView()
                        }
                    }
                } else {
                    noPreviewMessageView
                }

                switch state {
                case let .loading(progress, _):
                    Color.black.opacity(0.7)

                    VStack(spacing: 12) {
                        ProgressView(value: progress)
                            .progressViewStyle(.wireDriveAsset(strokeColor: .white))
                            .frame(height: 16)

                        if isLargePreview {
                            Text(Strings.Files.tapToCancelDownload)
                                .font(for: .subline1)
                                .foregroundStyle(.white)
                        }

                    }

                case .failed:
                    if isLargePreview {
                        Color.black.opacity(0.7)

                        Text(Strings.Files.downloadFailed)
                            .font(for: .subline1)
                            .foregroundStyle(.white)
                    } else {
                        WireDriveAttachmentPreviewErrorCircle()
                    }

                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorTheme.Backdrop.background.color)
            .overlay(alignment: .topTrailing) {
                if isAvailableOffline {
                    availableOfflineIcon(state: state)
                }
            }
        }
    }

    // MARK: Helpers

    private var isAssetDownloadError: Bool {
        switch state {
        case .failed:
            true
        default:
            false
        }
    }

    @ViewBuilder private var noPreviewMessageView: some View {
        if isLargePreview {
            Text(L10n.Localizable.Conversation.Message.Attachment.previewNotAvailable)
                .font(for: .subline1)
                .foregroundColor(ColorTheme.Backgrounds.surface.color)
                .multilineTextAlignment(.center)
                .padding()
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func availableOfflineIcon(state: WireDriveFileUITracker.State) -> some View {
        Image(systemName: "arrow.down.circle.fill")
            .resizable()
            .frame(width: 12 * scale, height: 11 + scale)
            .symbolRenderingMode(.palette)
            .foregroundStyle(ColorTheme.Base.secondaryText.color, .white)
            .accessibilityLabel(Accessibility.Files.availableOffline)
            .padding(6)
    }
}

// MARK: - Preview

#Preview {
    let previewCases: [(
        thumbnailURL: URL?,
        state: WireDriveFileUITracker.State,
        isLargePreview: Bool,
        isAvailableOffline: Bool
    )] = [
        (
            thumbnailURL: nil,
            state: .loading(progress: 0.5, isLargeFile: false),
            isLargePreview: true,
            isAvailableOffline: false
        ),
        (
            thumbnailURL: nil,
            state: .loading(progress: 0.5, isLargeFile: false),
            isLargePreview: false,
            isAvailableOffline: false
        ),
        (
            thumbnailURL: nil,
            state: .notLoaded,
            isLargePreview: true,
            isAvailableOffline: true
        ),
        (
            thumbnailURL: nil,
            state: .notLoaded,
            isLargePreview: false,
            isAvailableOffline: false
        ),
        (
            thumbnailURL: nil,
            state: .failed,
            isLargePreview: false,
            isAvailableOffline: false
        ),
        (
            thumbnailURL: nil,
            state: .loaded(showReadyToOpen: true),
            isLargePreview: false,
            isAvailableOffline: false
        ),
        (
            thumbnailURL: URL(string: "https://i.kym-cdn.com/entries/icons/facebook/000/018/012/this_is_fine.jpg"),
            state: .notLoaded,
            isLargePreview: true,
            isAvailableOffline: true
        )
    ]
    VStack {
        ForEach(0 ..< previewCases.count, id: \.self) { index in
            let data = previewCases[index]

            WireDriveImageConversationAttachmentPreview(
                thumbnailURL: data.thumbnailURL,
                state: data.state,
                isLargePreview: data.isLargePreview,
                isAvailableOffline: data.isAvailableOffline
            )
        }
    }
    .padding()
}

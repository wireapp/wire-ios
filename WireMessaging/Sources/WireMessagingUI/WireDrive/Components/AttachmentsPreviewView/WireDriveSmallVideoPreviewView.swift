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

private typealias Strings = L10n.Localizable.Conversation.WireCells
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct WireDriveSmallVideoPreviewView: View {

    @ScaledMetric private var scale: CGFloat = 1

    let url: URL?
    let state: WireDriveFileUITracker.State
    let duration: String?
    let isAvailableOffline: Bool

    @Environment(\.wireAccentColor) private var wireAccentColor

    var body: some View {
        WireDriveAttachmentPreview {
            ZStack(alignment: .center) {
                if let url {
                    asyncImage(url: url)
                }

                if url == nil, case .loading = state {
                    ProgressView()
                }

                if case .failed = state {
                    WireDriveAttachmentPreviewErrorCircle()
                }
            }
            .frame(
                width: WireDriveAttachmentsPreviewSizes.smallWidth,
                height: WireDriveAttachmentsPreviewSizes.smallHeight
            )
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
        }
    }

    @ViewBuilder
    private func asyncImage(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
                    .overlay {
                        switch state {
                        case .notLoaded, .loaded:
                            PlayIcon()
                                .disabled(false)
                        case let .loading(progress, _):
                            ZStack {
                                PlayIcon()

                                Color.black.opacity(0.7)

                                ProgressView(value: progress)
                                    .progressViewStyle(.wireDriveAsset(strokeColor: .white))
                                    .frame(height: 30)
                            }
                        case .failed:
                            EmptyView()
                        }
                    }
            case .failure:
                ProgressView()
            @unknown default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func durationView(duration: String) -> some View {
        Text(duration)
            .font(for: .body1)
            .foregroundColor(ColorTheme.Backgrounds.onTransparentDark.color)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 6)
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
    let url = URL(string: "https://i.kym-cdn.com/entries/icons/facebook/000/018/012/this_is_fine.jpg")
    let previewCases: [(
        url: URL?,
        state: WireDriveFileUITracker.State
    )] = [
        (
            url: url,
            state: .loading(progress: 0.7, isLargeFile: false)
        ),
        (
            url: url,
            state: .loaded(showReadyToOpen: true)
        ),
        (
            url: url,
            state: .loaded(showReadyToOpen: false)
        ),
        (
            url: url,
            state: .notLoaded
        ),
        (
            url: url,
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

                WireDriveSmallVideoPreviewView(
                    url: data.url,
                    state: data.state,
                    duration: "02:34",
                    isAvailableOffline: true
                )
                .padding(.horizontal)
            }
        }
    }
}

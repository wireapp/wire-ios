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

struct WireDriveSmallVideoPreviewView: View {

    let url: URL?
    let progress: Double?
    let downloadError: Bool
    let duration: String?

    @Environment(\.wireAccentColor) private var wireAccentColor

    var body: some View {
        WireDriveAttachmentPreview(
            progress: progress,
            progressColor: downloadError ? ColorTheme.Base.error.color : ColorTheme.Base.primary(wireAccentColor).color,
        ) {
            ZStack(alignment: .center) {
                if let url {
                    asyncImage(url: url)
                }

                if url == nil, !downloadError {
                    ProgressView()
                }

                if downloadError {
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
                        if !downloadError {
                            PlayIcon()
                                .disabled(false)
                        }
                    }
            case .failure:
                WireDriveAttachmentPreviewErrorCircle()
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
}

#Preview {
    WireDriveSmallVideoPreviewView(
        url: URL(
            string:
            "https://i.kym-cdn.com/entries/icons/facebook/000/018/012/this_is_fine.jpg"
        ),
        progress: 0.7,
        downloadError: false,
        duration: "2:22",
    )
}

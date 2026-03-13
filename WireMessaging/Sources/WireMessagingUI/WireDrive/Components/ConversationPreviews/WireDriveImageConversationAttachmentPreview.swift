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

struct WireDriveImageConversationAttachmentPreview: View {

    let thumbnailURL: URL?
    let state: WireDriveFileUITracker.State
    let canShowNoPreviewMessage: Bool

    @Environment(\.wireAccentColor) private var wireAccentColor

    init(thumbnailURL: URL?, state: WireDriveFileUITracker.State, canShowNoPreviewMessage: Bool) {
        self.thumbnailURL = thumbnailURL
        self.state = state
        self.canShowNoPreviewMessage = canShowNoPreviewMessage
    }

    var body: some View {
        WireDriveAttachmentPreview() {
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

                if isAssetDownloadError {
                    WireDriveAttachmentPreviewErrorCircle()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorTheme.Backdrop.background.color)
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
        if canShowNoPreviewMessage {
            Text(L10n.Localizable.Conversation.Message.Attachment.previewNotAvailable)
                .font(for: .subline1)
                .foregroundColor(ColorTheme.Backgrounds.surface.color)
                .multilineTextAlignment(.center)
                .padding()
        } else {
            EmptyView()
        }
    }

}

// MARK: - Preview

#Preview {
    WireDriveImageConversationAttachmentPreview(
        thumbnailURL: nil,
        state: .downloading(progress: 0.5, isLargeFile: false),
        canShowNoPreviewMessage: true
    )
}

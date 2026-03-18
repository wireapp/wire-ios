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

struct WireDriveImageConversationAttachmentPreview: View {

    let thumbnailURL: URL?
    let state: WireDriveFileUITracker.State
    let isLargePreview: Bool

    @Environment(\.wireAccentColor) private var wireAccentColor

    init(thumbnailURL: URL?, state: WireDriveFileUITracker.State, isLargePreview: Bool) {
        self.thumbnailURL = thumbnailURL
        self.state = state
        self.isLargePreview = isLargePreview
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
                
                switch state {
                case .loading(let progress, _):
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

}

// MARK: - Preview

#Preview {
    WireDriveImageConversationAttachmentPreview(
        thumbnailURL: nil,
        state: .loading(progress: 0.5, isLargeFile: false),
        isLargePreview: true
    )
}

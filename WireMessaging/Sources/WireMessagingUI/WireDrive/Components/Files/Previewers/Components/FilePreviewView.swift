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

import AVKit
import PDFKit
import SwiftUI
import WebKit
import WireDesign
import WireMessagingDomain

/// A read-only file preview screen used in Drive conversations.
///
/// This view displays file content using **custom previewers** instead of relying on
/// system Quick Look. This is intentional for guest users in Drive
/// conversations to restrict actions on these files.
///
/// Each supported file type is rendered using a dedicated preview component:
/// - PDF → `PDFKitView`
/// - Video → `VideoPlayer`
/// - Image → `ImageView`
/// - Audio → `AudioPlayerView`
/// - Archive → `ZipView`
/// - Other → `WebView`
struct FilePreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let url: URL
    let fileType: WireDriveFileType
    let name: String

    var body: some View {
        VStack(spacing: 0) {
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder private var contentView: some View {
        NavigationStack {
            Group {
                switch fileType {
                case .pdf:
                    PDFKitView(url: url)
                case .video:
                    VideoPlayer(player: AVPlayer(url: url))
                case .image:
                    ImageView(url: url)
                case .audio:
                    AudioPlayerView(url: url)
                case .archive:
                    ZipView(url: url)
                case .document, .presentation, .spreadsheet:
                    WebView(url: url)
                default:
                    WebView(url: url)
                }
            }
            .navigationTitle(name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(name)
                            .font(for: .h3)
                            .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)

                        Text(L10n.Localizable.Conversation.WireCells.Files.ViewerAccess.navigationSubtitle)
                            .font(for: .subline1)
                            .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Localizable.General.confirm) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

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
import WireMessagingDomain

struct FilePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

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
                case .document:
                    DocumentView(url: url)
                case .presentation:
                    PresentationView(url: url)
                default:
                    DocumentView(url: url)
                }
            }
            .navigationTitle(name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
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

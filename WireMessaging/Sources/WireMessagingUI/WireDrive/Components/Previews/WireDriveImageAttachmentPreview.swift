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

private typealias Strings = L10n.Localizable.Conversation.WireCells

struct WireDriveImageAttachmentPreview: View {

    let thumbnail: Image?
    let state: WireDriveFileUITracker.State

    @Environment(\.wireAccentColor) private var wireAccentColor

    var body: some View {
        WireDriveAttachmentPreview {
            ZStack(alignment: .center) {
                if let thumbnail {
                    GeometryReader { geometry in
                        thumbnail
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }

                stateView
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder private var stateView: some View {
        switch state {
        case let .loading(progress, _):
            Color.black.opacity(0.7)

            ProgressView(value: progress)
                .progressViewStyle(.wireDriveAsset(strokeColor: .white))
                .frame(height: 16)

        case .failed:
            WireDriveAttachmentPreviewErrorCircle()

        default:
            EmptyView()
        }
    }
}

#Preview {
    WireDriveImageAttachmentPreview(
        thumbnail: Image("rectangular-placeholder", bundle: .module),
        state: .loaded(showReadyToOpen: false)
    ).frame(width: 74, height: 74)
}

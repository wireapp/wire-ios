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

struct WireDriveImageAttachmentPreview: View {

    let thumbnail: Image?
    let progress: Double?
    let isError: Bool

    @Environment(\.wireAccentColor) private var wireAccentColor

    var body: some View {
        WireCellsAttachmentPreview(
            progress: progress,
            progressColor: isError ? ColorTheme.Base.error.color : ColorTheme.Base.primary(wireAccentColor).color
        ) {
            ZStack(alignment: .center) {
                if let thumbnail {
                    GeometryReader { geometry in
                        thumbnail
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }

                if thumbnail == nil, !isError {
                    ProgressView()
                }

                if isError {
                    WireCellsAttachmentPreviewErrorCircle()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    WireCellsImageAttachmentPreview(
        thumbnail: Image("rectangular-placeholder", bundle: .module),
        progress: 0.7,
        isError: true
    ).frame(width: 74, height: 74)
}

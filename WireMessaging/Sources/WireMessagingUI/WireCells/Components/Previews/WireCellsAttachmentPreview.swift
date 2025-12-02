//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// Wraps `content` providing a progress indicator and styling suitable for an attachment preview.

struct WireCellsAttachmentPreview<Content: View>: View {

    private let progress: Double?
    private let progressColor: Color
    private let content: Content

    init(
        progress: Double?,
        progressColor: Color,
        @ViewBuilder content: () -> Content,
    ) {
        self.progress = progress
        self.progressColor = progressColor
        self.content = content()
    }

    var body: some View {
        content
            .overlay(
                VStack {
                    Spacer()
                    ProgressView(value: progress, total: 1)
                        .tint(Color.blue)
                        .progressViewStyle(AssetProgressStyle(variant: .linear, fillColor: progressColor))
                        .padding(.bottom, Constants.borderWidth / 2)
                        .opacity(progress == nil ? 0 : 1)

                }
            )
            .clipShape(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(Constants.borderColor, lineWidth: Constants.borderWidth)
            )
            .padding(Constants.borderWidth / 2)
    }
}

/// Constants used in `WireCellsAttachmentPreview` for styling and layout. They need to be defined here because
/// `WireCellsAttachmentPreview` is generic.

private enum Constants {
    static let borderWidth: CGFloat = 1
    static let cornerRadius: CGFloat = 12
    static let borderColor = ColorTheme.Strokes.outline.color
}

#Preview {
    WireCellsAttachmentPreview(
        progress: 0.5,
        progressColor: .blue
    ) {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
    }
    .frame(width: 222, height: 74)
}

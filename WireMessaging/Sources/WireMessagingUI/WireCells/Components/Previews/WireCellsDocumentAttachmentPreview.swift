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

/// A wire cells attachment preview for document attachments.

struct WireCellsDocumentAttachmentPreview: View {

    enum Constants {
        static let errorColor = ColorTheme.Base.error.color
    }

    @ScaledMetric private var scale: CGFloat = 1

    let headerIcon: Image
    let headerText: String
    let labelText: String
    let progress: Double?
    let isError: Bool

    @Environment(\.wireAccentColor) private var wireAccentColor

    var body: some View {
        WireCellsAttachmentPreview(
            progress: progress,
            progressColor: isError ? Constants.errorColor : ColorTheme.Base.primary(wireAccentColor).color
        ) {
            WireCellsDocumentHeaderView(
                headerIcon: headerIcon,
                headerText: headerText,
                labelText: labelText,
                progress: progress,
                isError: isError,
            )
            .background(ColorTheme.Backgrounds.surfaceVariant.color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    WireCellsDocumentAttachmentPreview(
        headerIcon: Image(FileIcon.pdf.resource),
        headerText: "PDF (336 KB)",
        labelText: "CDR_20220120 Accessibility Review Reviewed Final Plus",
        progress: 0.7,
        isError: false
    )
    .frame(width: 222, height: 74)
}

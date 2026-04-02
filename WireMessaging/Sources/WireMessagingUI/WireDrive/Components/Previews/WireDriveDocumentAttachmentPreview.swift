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
import WireMessagingDomain

/// A wire drive attachment preview for document attachments.

struct WireDriveDocumentAttachmentPreview: View {

    enum Constants {
        static let errorColor = ColorTheme.Base.error.color
    }

    @ScaledMetric private var scale: CGFloat = 1

    let headerIcon: Image
    let headerText: String
    let labelText: String
<<<<<<< HEAD
    let state: WireDriveFileUITracker.State
    let isDraftPreview: Bool
=======
    let progress: Double?
    let isError: Bool
    var minHeight: CGFloat?
>>>>>>> 64c727e237 (fix: attachment preview header layout issues - WPB-23931 (#4491))

    @Environment(\.wireAccentColor) private var wireAccentColor

    var body: some View {
        WireDriveAttachmentPreview {
            WireDriveDocumentHeaderView(
                headerIcon: headerIcon,
                headerText: headerText,
                labelText: labelText,
<<<<<<< HEAD
                isDraftPreview: isDraftPreview,
                state: state
=======
                progress: progress,
                isError: isError,
                minHeight: minHeight
>>>>>>> 64c727e237 (fix: attachment preview header layout issues - WPB-23931 (#4491))
            )
            .background(ColorTheme.Backgrounds.surfaceVariant.color)
        }
    }
}

#Preview {
<<<<<<< HEAD
    WireDriveDocumentAttachmentPreview(
        headerIcon: Image(WireDriveFileType.pdf.imageResource),
        headerText: "PDF (336 KB)",
        labelText: "CDR_20220120 Accessibility Review Reviewed Final Plus",
        state: .loading(progress: 0.7, isLargeFile: false),
        isDraftPreview: false
    )
    .frame(width: 222, height: 74)
=======
    VStack {
        WireDriveDocumentAttachmentPreview(
            headerIcon: Image(WireDriveFileType.pdf.imageResource),
            headerText: "PDF (336 KB)",
            labelText: "CDR_20220120 Accessibility Review Reviewed Final Plus",
            progress: 0.7,
            isError: false,
            minHeight: nil
        )
        .frame(width: 222)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.gray)
>>>>>>> 64c727e237 (fix: attachment preview header layout issues - WPB-23931 (#4491))
}

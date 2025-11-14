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
import WireFoundation

struct WireCellsDocumentHeaderView: View {
    enum Constants {
        static let errorColor = ColorTheme.Base.error.color
    }

    @ScaledMetric private var scale: CGFloat = 1

    let headerIcon: Image
    let headerText: String
    let labelText: String
    let progress: Double?
    let isError: Bool

    var body: some View {
        header()
    }

    @ViewBuilder
    private func header() -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                if isError {
                    Image(systemName: "exclamationmark.triangle")
                        .fontWeight(.semibold)
                        .font(.system(size: 14 * scale))
                        .foregroundStyle(Constants.errorColor)
                } else {
                    headerIcon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 16 * scale)
                }

                Text(headerText)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    .font(for: .subline1)
                    .lineLimit(1)

                Spacer()
            }
            .padding([.horizontal, .top], 8)

            Spacer(minLength: 0)

            Text(labelText)
                .foregroundStyle(ColorTheme.Backgrounds.onSurfaceVariant.color)
                .font(for: .h5)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal, .bottom], 8)
        }
    }
}

#Preview {
    WireCellsDocumentHeaderView(
        headerIcon: Image(FileIcon.pdf.resource),
        headerText: "PDF (336 KB)",
        labelText: "CDR_20220120 Accessibility Review Reviewed Final Plus",
        progress: 0.7,
        isError: false
    )
    .frame(width: 222, height: 74)
    .environment(\.wireTextStyleMapping, WireTextStyleMapping())
}

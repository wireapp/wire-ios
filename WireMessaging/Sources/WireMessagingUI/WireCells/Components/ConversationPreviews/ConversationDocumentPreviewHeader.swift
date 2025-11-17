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

public import SwiftUI
import WireDesign
import WireFoundation

public struct ConversationDocumentPreviewHeader: View {

    enum Constants {
        static let maxHeaderLineLimit: Int = 2
        static let minHeaderLineLimit: Int = 1
        static let maxLabelLineLimit: Int = 3
        static let minLabelLineLimit: Int = 2
    }

    let headerIcon: Image
    let headerText: String
    let labelText: String

    @ScaledMetric(relativeTo: .body)
    private var headerLineHeight: CGFloat = 20
    @ScaledMetric(relativeTo: .body)
    private var headerScale: CGFloat = 1
    @ScaledMetric(relativeTo: .headline)
    private var labeLineHeight: CGFloat = 24
    @ScaledMetric(relativeTo: .headline)
    private var labelScale: CGFloat = 1

    var scalingHeaderLineLimit: Int {
        Int(round(headerScale)) > Constants.minHeaderLineLimit ? Constants.maxHeaderLineLimit : Constants
            .minHeaderLineLimit
    }

    var scalingLabelLineLimit: Int {
        Int(ceil(labelScale)) > Constants.minLabelLineLimit ? Constants.maxLabelLineLimit : Constants.minLabelLineLimit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                headerIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: headerLineHeight)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                Text(headerText)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    // If this font is changed
                    // remember to change the reference in the header @ScaledMetric
                    .wireTextStyle(.body1)
                    .lineLimit(scalingHeaderLineLimit)
                Spacer()
                Text(L10n.Localizable.Conversation.File.Preview.open)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    .wireTextStyle(.body1)
                    .lineLimit(scalingHeaderLineLimit)
            }
            Text(labelText)
                .foregroundStyle(ColorTheme.Backgrounds.onSurfaceVariant.color)
                .wireTextStyle(.h3)
                // If this font is changed
                // remember to change the reference in the label @ScaledMetric
                .lineLimit(max(3, scalingLabelLineLimit))
                .frame(height: labeLineHeight * CGFloat(scalingLabelLineLimit), alignment: .bottom)
        }
    }
}

package struct ConversationDocumentPreviewHeader_Preview: View {
    package var body: some View {
        ConversationDocumentPreviewHeader(
            headerIcon: Image("square-placeholder", bundle: .module),
            headerText: "Document (336 KB)",
            labelText: "Lorem ipsum"
        )
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())
    }
}

#Preview {
    VStack {
        ConversationDocumentPreviewHeader_Preview()
            .frame(width: 350, height: 200)
    }
    .padding()
    .background(.black)
}

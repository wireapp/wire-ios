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
import WireReusableUIComponents

public struct UploadDocumentPreview: View {
    let headerIcon: Image
    let headerText: String
    let labelText: String
    let onRemove: @Sendable () -> Void

    @ScaledMetric private var scale: CGFloat = 1

    public init(
        headerIcon: Image,
        headerText: String,
        labelText: String,
        onRemove: @escaping @Sendable () -> Void
    ) {
        self.headerIcon = headerIcon
        self.headerText = headerText
        self.labelText = labelText
        self.onRemove = onRemove
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4 * floor(scale)) {
                headerIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16 * scale, height: 16 * scale)
                Text(headerText)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    .wireTextStyle(.body1)
                    .lineLimit(max(1, Int(round(scale))))
                Spacer()
            }
            Text(labelText)
                .foregroundStyle(ColorTheme.Backgrounds.onSurfaceVariant.color)
                .wireTextStyle(.h3)
                .lineLimit(max(2, 2 * Int(round(scale))), reservesSpace: true)
        }
        .roundedBorderAndBackground(
            backgroundColor: ColorTheme.Backgrounds.surfaceVariant.color,
            borderColor: ColorTheme.Strokes.outline.color,
            borderWidth: 1,
            cornerRadius: 10,
            padding: 8
        )
        .deleteItemButton(onRemove: { onRemove() })
    }
}

package struct UploadDocumentPreview_Preview: View {
    package init() {}

    package var body: some View {
        UploadDocumentPreview(
            headerIcon: Image(systemName: "text.document"),
            headerText: "Document (336 KB)",
            labelText: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce ipsum purus, scelerisque molestie rutrum vitae, faucibus in velit. Sed eget consectetur elit, in tristique metus."
        ) {
            print("remove")
        }
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())
    }

}

#Preview {
    VStack {
        UploadDocumentPreview_Preview()
            .frame(width: 350, height: 200)
    }
    .padding()
    .background(.black)
}

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

public import SwiftUI
import WireDesign
import WireFoundation
import WireReusableUIComponents

public struct ConversationGenericDocumentPreview: View {
    let headerIcon: Image
    let headerText: String
    let labelText: String

    public var body: some View {
        ConversationDocumentPreviewHeader(
            headerIcon: headerIcon,
            headerText: headerText,
            labelText: labelText
        )
        .roundedBorderAndBackground(
            backgroundColor: ColorTheme.Backgrounds.surfaceVariant.color,
            borderColor: ColorTheme.Strokes.outline.color,
            borderWidth: 1,
            cornerRadius: 10,
            padding: 8
        )
    }
}

package struct ConversationGenericDocumentPreview_Preview: View {
    package var body: some View {
        ConversationGenericDocumentPreview(
            headerIcon: Image("square-placeholder", bundle: .module),
            headerText: "Document (336 KB)",
            labelText: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce ipsum purus, scelerisque molestie rutrum vitae, faucibus in velit. Sed eget consectetur elit, in tristique metus."
        )
    }
}

#Preview {
    VStack {
        ConversationGenericDocumentPreview_Preview()
            .frame(width: 350, height: 200)
    }
    .padding()
    .background(.black)
}

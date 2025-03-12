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

struct TimeDividerContentView: View, ConversationCellContentViewProtocol {
    typealias Model = TimeDividerModel

    private let dividerColor = ColorTheme.Strokes.outline.color

    private(set) var model: Model

    var body: some View {
        HStack(spacing: 0) {

            VStack {
                Divider()
                    .frame(minHeight: 1)
                    .overlay { dividerColor }
            }
            .padding(.leading, 12)

            if !model.text.isEmpty {
                Text(model.text)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
            }

            VStack {
                Divider()
                    .frame(minHeight: 1)
                    .overlay { dividerColor }
            }
            .padding(.trailing, 12)

        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

}

// MARK: - Previews

#Preview {
    TimeDividerContentView(model: "Friday")
}

#Preview("empty") {
    TimeDividerContentView(model: "")
}

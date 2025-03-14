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

struct TimeDividerContentView: ConversationCellContentViewProtocol {

    private let dividerColor = ColorTheme.Strokes.outline.color

    private(set) var model: TimeDividerModel

    var body: some View {
        if model.isUnreadIndicatorVisible {
            withUnreadIndicator
        } else {
            withoutUnreadIndicator
        }
    }

    @ViewBuilder private var withUnreadIndicator: some View {
        HStack(spacing: 0) {

            Circle()
                .fill(.tint)
                .frame(width: 8)
                .padding(.leading, 24)
                .padding(.trailing, 18)
                .layoutPriority(1)

            if !model.text.isEmpty {
                Text(model.text)
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(.trailing, 12)
                    .layoutPriority(1)
            }

            VStack {
                Divider()
                    .frame(minHeight: 1)
                    .overlay { dividerColor }
            }
            .padding(.trailing, 24)

        }
        .padding(.vertical, 8)
    }

    @ViewBuilder private var withoutUnreadIndicator: some View {
        HStack(spacing: 0) {

            VStack {
                Divider()
                    .frame(minHeight: 1)
                    .overlay { dividerColor }
            }
            .padding(.leading, 24)

            if !model.text.isEmpty {
                Text(model.text)
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .layoutPriority(1)
            }

            VStack {
                Divider()
                    .frame(minHeight: 1)
                    .overlay { dividerColor }
            }
            .padding(.trailing, 24)

        }
        .padding(.vertical, 8)
    }

}

// MARK: - Previews

#Preview("with unread indicator") {
    let model = TimeDividerModel(
        text: "Friday Lorem Ipsum Dolor",
        isUnreadIndicatorVisible: true
    )
    TimeDividerContentView(model: model)
}

#Preview("without unread indicator") {
    let model = TimeDividerModel(
        text: "Friday Lorem Ipsum Dolor",
        isUnreadIndicatorVisible: false
    )
    TimeDividerContentView(model: model)
}

#Preview("no text") {
    let model = TimeDividerModel()
    TimeDividerContentView(model: model)
}

#Preview("no text but unread indicator") {
    let model = TimeDividerModel(
        text: "",
        isUnreadIndicatorVisible: true
    )
    TimeDividerContentView(model: model)
}

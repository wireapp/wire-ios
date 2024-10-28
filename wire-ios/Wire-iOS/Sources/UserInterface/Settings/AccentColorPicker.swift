//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import Inject
import SwiftUI
import WireCommonComponents
import WireDesign
import WireFoundation
import WireSyncEngine

struct AccentColorPicker: View {

    @State
    var selectedColor: AccentColor
    private let colorViewSize: CGFloat = 28

    @ObserveInjection var inject

    let onColorSelect: ((AccentColor) -> Void)?

    var body: some View {
        accentColorList
            .enableInjection()
    }

    @ViewBuilder
    private var accentColorList: some View {
        List(AccentColor.allCases, id: \.self) { color in
            cell(for: color)
                .listRowBackground(Color(SemanticColors.View.backgroundUserCell))
                .onTapGesture {
                    self.selectedColor = color
                    onColorSelect?(color)
                }
        }
        .listStyle(.plain)
        .modifier(ListBackgroundStyleModifier())
        .background(Color(SemanticColors.View.backgroundDefault))
    }

    @ViewBuilder
    private func cell(for color: AccentColor) -> some View {
        HStack {
            // Color view
            Circle()
                .fill(Color(uiColor: color.uiColor))
                .frame(width: colorViewSize, height: colorViewSize)
                .padding(.trailing, 10)
            Text(color.name)
                .font(.textStyle(selectedColor == color ? .h3 : .body1))

            Spacer()

            // Checkmark view
            if selectedColor == color {
                Image(systemName: "checkmark")
                    .foregroundColor(Color(SemanticColors.Icon.foregroundDefaultBlack))
            }
        }
    }
}

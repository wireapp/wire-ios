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

import SwiftUI
import WireSyncEngine
import WireCommonComponents

struct ColorPickerView: View {
    let colors: [AccentColor]
    @State var selectedColor: AccentColor?
    var onColorSelect: ((AccentColor) -> Void)?

    private let colorViewSize: CGFloat = 28
    private let colorViewCornerRadius: CGFloat = 14
    private let leftPadding: CGFloat = 6
    private let rightPadding: CGFloat = 20

    var body: some View {
        List(colors, id: \.self) { color in
            HStack {
                // Color view
                Circle()
                    .fill(Color(uiColor: UIColor(for: color)))
                    .frame(width: colorViewSize, height: colorViewSize)
                    .padding(.leading, 2)

                Text(color.name)

                Spacer()

                // Checkmark view
                if selectedColor == color {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color(.label)) // Adjust color as needed
                        .padding(.trailing, rightPadding)
                }
            }
            .background(Color(SemanticColors.View.backgroundUserCell))
            .onTapGesture {
                withAnimation {
                    self.selectedColor = color
                    onColorSelect?(color)
                }
            }
        }
    }
}

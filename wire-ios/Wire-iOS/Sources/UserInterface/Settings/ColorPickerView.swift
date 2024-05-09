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
import WireCommonComponents
import WireSyncEngine

struct ColorPickerView: View {

    @State var selectedColor: AccentColor?

    let colors: [AccentColor]
    var onColorSelect: ((AccentColor) -> Void)?

    private let colorViewSize: CGFloat = 28
    private let colorViewCornerRadius: CGFloat = 14

    var body: some View {
        NavigationView {
            List(colors, id: \.self) { color in
                HStack {
                    // Color view
                    Circle()
                        .fill(Color(uiColor: color.uiColor))
                        .frame(width: colorViewSize, height: colorViewSize)
                        .padding(.trailing, 10)
                    Text(color.name)

                    Spacer()

                    // Checkmark view
                    if selectedColor == color {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color(SemanticColors.Icon.foregroundDefaultBlack))
                    }
                }
                .listRowBackground(Color(SemanticColors.View.backgroundUserCell))
                .onTapGesture {
                    withAnimation {
                        self.selectedColor = color
                        onColorSelect?(color)
                    }
                }
            }
            .listStyle(.plain)
            .modifier(ListBackgroundStyleModifier())
            .background(Color(SemanticColors.View.backgroundDefault))
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(L10n.Localizable.Self.Settings.AccountPictureGroup.color.capitalized)
                        .font(.textStyle(.h3))
                }
            }
        }
    }
}

struct ListBackgroundStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content.background(Color(SemanticColors.View.backgroundDefault))
        }
    }
}

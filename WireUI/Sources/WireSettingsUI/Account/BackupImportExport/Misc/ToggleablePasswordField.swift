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

// TODO: [WPB-15571] Add accessibility strings to the mask / unmask buttons
struct ToggleablePasswordField: View {

    @Binding var password: String
    var placeholder: String
    var placeholderColor: Color
    var borderColor: Color
    var focusOnAppear = true

    @State private var isPasswordVisible = false

    @FocusState private var isFocused: Bool

    @Environment(\.colorScheme) private var colorScheme

    private typealias Labels = L10n.Accessibility.Backup

    var body: some View {
        HStack {

            ZStack {
                TextField(text: $password) {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(placeholderColor)
                }
                .textContentType(.password)
                .autocapitalization(.none)
                .focused($isFocused)
                .disabled(!isPasswordVisible)
                .opacity(isPasswordVisible ? 1 : 0)

                SecureField(text: $password) {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(placeholderColor)
                }
                .textContentType(.password)
                .focused($isFocused)
                .disabled(isPasswordVisible)
                .opacity(isPasswordVisible ? 0 : 1)
            }
//            if isPasswordVisible {
//                TextField(text: $password) {
//                    Text(placeholder)
//                        .font(.body)
//                        .foregroundStyle(placeholderColor)
//                }
//                .textContentType(.password)
//                .autocapitalization(.none)
//                .focused($isFocused)
//            } else {
//                SecureField(text: $password) {
//                    Text(placeholder)
//                        .font(.body)
//                        .foregroundStyle(placeholderColor)
//                }
//                .textContentType(.password)
//                .focused($isFocused)
//            }

            let accessibilityLabel = isPasswordVisible ? Labels.Password.Hide.label : Labels.Password.Show.label
            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                    .foregroundColor(toggleVisibilityButtonColor)
            }
            .accessibilityLabel(accessibilityLabel)

        }
        .padding()
        .background(textFieldBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
        .onAppear {
            if focusOnAppear {
                isFocused = true
            }
        }
    }

    private var textFieldBackground: Color {
        if colorScheme != .dark {
            BaseColorPalette.Neutrals.white.color
        } else {
            ColorTheme.Backgrounds.background.color
        }
    }

    private var toggleVisibilityButtonColor: Color {
        UIColor { $0.userInterfaceStyle != .dark
            ? BaseColorPalette.Neutrals.black
            : BaseColorPalette.Grays.gray70
        }.color
    }

}

#Preview {
    ToggleablePasswordField(
        password: .constant(""),
        placeholder: "Placeholder Text",
        placeholderColor: BaseColorPalette.Neutrals.black.color,
        borderColor: BaseColorPalette.Neutrals.black.color
    )
    .padding()
}

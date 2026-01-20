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

import SwiftUI
import WireDesign
import WireLocators
import WireReusableUIComponents

struct ToggleablePasswordField: View {

    @Binding var password: String
    var placeholder: String
    var placeholderColor: Color
    var focusOnAppear = true
    var isContextMenuAllowed: Bool

    @State private var isPasswordVisible = false

    @Environment(\.colorScheme) private var colorScheme

    enum FocusedField: Hashable {
        case secureField
        case textField
    }

    @FocusState private var focusedField: FocusedField?

    private typealias Labels = L10n.Accessibility.Backup

    var body: some View {
        HStack {

            if isPasswordVisible {
                textField
            } else {
                secureField
            }

            Button {
                isPasswordVisible.toggle()
                focusedField = isPasswordVisible ? .textField : .secureField
            } label: {
                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                    .foregroundColor(toggleVisibilityButtonColor)
            }
            .accessibilityLabel(toggleButtonAccessibilityLabel)

        }
        .padding()
        .background(textFieldBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.tint, lineWidth: 1)
        )
        .onAppear {
            if focusOnAppear {
                focusedField = .secureField
            }
        }
    }

    @ViewBuilder private var textField: some View {
        ContextMenuControllableTextField(
            text: $password,
            placeholder: placeholder,
            isSecureTextEntry: false,
            placeholderColor: placeholderColor,
            isContextMenuAllowed: isContextMenuAllowed
        )
        .textContentType(.password)
        .autocapitalization(.none)
        .focused($focusedField, equals: .textField)
        .accessibilityIdentifier(Locators.SetPasswordPage.passwordInputField.rawValue)
    }

    @ViewBuilder private var secureField: some View {
        ContextMenuControllableTextField(
            text: $password,
            placeholder: placeholder,
            isSecureTextEntry: true,
            placeholderColor: placeholderColor,
            isContextMenuAllowed: isContextMenuAllowed
        )
        .textContentType(.password)
        .focused($focusedField, equals: .secureField)
        .accessibilityIdentifier(Locators.SetPasswordPage.passwordInputField.rawValue)
    }

    private var toggleButtonAccessibilityLabel: String {
        if isPasswordVisible {
            Labels.Password.Hide.label
        } else {
            Labels.Password.Show.label
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
        isContextMenuAllowed: true
    )
    .tint(.purple)
    .padding()
}

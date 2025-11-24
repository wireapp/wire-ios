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

public struct PasswordField: View {

    private typealias Strings = L10n.Passwordtextfield

    @FocusState private var isFocused: Bool
    // TextField and SecureField have different heights. Switching between them causes the view to jump.
    // But we also want their height to change with dynamic font sizes. Hence @ScaledMetric.
    @ScaledMetric private var fieldHeight: CGFloat = 48

    @State private var isPasswordVisible = false
    @Binding private var password: String

    private let passwordRules: String?
    private let placeholder: String
    private let title: String
    private let isValidPassword: (String) -> Bool

    @Environment(\.wireAccentColor) private var wireAccentColor

    public init(
        password: Binding<String>,
        placeholder: String,
        title: String,
        passwordRules: String?,
        isValidPassword: @escaping (String) -> Bool
    ) {
        self._password = password
        self.placeholder = placeholder
        self.title = title
        self.passwordRules = passwordRules
        self.isValidPassword = isValidPassword
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(for: .h4)
                .foregroundColor(titleColor)

            HStack {
                if isPasswordVisible {
                    TextField(placeholder, text: $password)
                        .autocorrectionDisabled()
                        .textContentType(.password)
                        .font(for: .body1)
                        .frame(height: fieldHeight)
                        .focused($isFocused)
                } else {
                    SecureField(placeholder, text: $password)
                        .autocorrectionDisabled()
                        .textContentType(.password)
                        .frame(height: fieldHeight)
                        .focused($isFocused)
                }
                Spacer()
                Button(action: {
                    isPasswordVisible.toggle()
                }, label: {
                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                        .foregroundColor(iconColor)
                        .padding(16)
                })
                .accessibilityLabel(isPasswordVisible ? Strings.hidePassword : Strings.showPassword)
            }
            .padding(.leading, 16)
            .frame(height: fieldHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        borderColor,
                        lineWidth: 1
                    )
            )

            if let passwordRules, shouldShowPasswordRules {
                Text(passwordRules)
                    .font(.caption)
                    .foregroundColor(titleColor)
            }
        }
    }

    // MARK: - Helper

    private var shouldShowPasswordRules: Bool {
        !isValidPassword(password) && !password.isEmpty
    }

    private var titleColor: Color {
        if password.isEmpty {
            ColorTheme.Base.labelTitle.color
        } else {
            isValidPassword(password) ? ColorTheme.Base.primary(wireAccentColor).color : ColorTheme.Base.error.color
        }
    }

    private var borderColor: Color {
        if password.isEmpty {
            ColorTheme.Strokes.outline.color
        } else {
            isValidPassword(password) ? ColorTheme.Base.primary(wireAccentColor).color : ColorTheme.Base.error.color
        }
    }

    private var iconColor: Color {
        password.isEmpty ? ColorTheme.Strokes.disabledOutline.color : ColorTheme.Buttons.Secondary.onEnabled.color
    }

}

// MARK: - Previews

#Preview("Invalid Password") {
    PasswordField(
        password: .constant("Invalid password"),
        placeholder: L10n.Passwordtextfield.Preview.placeholder,
        title: L10n.Passwordtextfield.Preview.title,
        passwordRules: L10n.Passwordtextfield.Preview.passwordrules,
        isValidPassword: { _ in false }
    )
    .padding()
}

#Preview("Valid Password") {
    PasswordField(
        password: .constant("Valid password!"),
        placeholder: L10n.Passwordtextfield.Preview.placeholder,
        title: L10n.Passwordtextfield.Preview.title,
        passwordRules: L10n.Passwordtextfield.Preview.passwordrules,
        isValidPassword: { _ in true }
    )
    .padding()
}

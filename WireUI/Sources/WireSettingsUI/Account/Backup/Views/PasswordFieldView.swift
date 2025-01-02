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

struct PasswordFieldView: View {
    @Binding var password: String
    var isPasswordValid: Bool
    @Binding var isPasswordVisible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("passwordField.title", tableName: "Localizable", bundle: .module)
                .font(.subheadline)
                .foregroundColor(isPasswordValid ? ColorTheme.Base.secondaryText.color : ColorTheme.Base.error.color)

            ZStack {
                if isPasswordVisible {
                    TextField(String(
                        localized: "passwordField.placeholder",
                        table: "Localizable",
                        bundle: .module),
                              text: $password)
                        .font(.textStyle(.body1))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(isPasswordValid ? ColorTheme.Base.secondaryText.color : ColorTheme.Base.error.color, lineWidth: 1)
                        )
                } else {
                    SecureField(String(
                        localized: "passwordField.placeholder",
                        table: "Localizable",
                        bundle: .module),
                                text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(isPasswordValid ? ColorTheme.Base.secondaryText.color : ColorTheme.Base.error.color, lineWidth: 1)
                        )
                }

                HStack {
                    Spacer()
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 10)
                }
            }

            Text("passwordField.rules", tableName: "Localizable", bundle: .module)
                .font(.caption)
                .foregroundColor(isPasswordValid ? ColorTheme.Base.secondaryText.color : ColorTheme.Base.error.color)
        }
        .padding(.horizontal)
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview("Invalid Password - Hidden") {
    PasswordFieldView(
        password: .constant(""),
        isPasswordValid: false,
        isPasswordVisible: .constant(false)
    )
}

@available(iOS 17, *)
#Preview("Invalid Password - Visible") {
    PasswordFieldView(
        password: .constant("ValidPassword1!"),
        isPasswordValid: false,
        isPasswordVisible: .constant(true)
    )
}

@available(iOS 17, *)
#Preview("Valid Password - Hidden") {
    PasswordFieldView(
        password: .constant("ValidPassword1!"),
        isPasswordValid: true,
        isPasswordVisible: .constant(false)
    )
}

@available(iOS 17, *)
#Preview("Valid Password - Visible") {
    PasswordFieldView(
        password: .constant("ValidPassword1!"),
        isPasswordValid: true,
        isPasswordVisible: .constant(true)
    )
}

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

struct PasswordFieldView: View { // TODO: [WPB-15211] try to use `ToggleablePasswordField`

    let passwordRules: Text
    @Binding var password: String
    @State fileprivate(set) var isPasswordVisible = false
    var isPasswordValid = true
    var focusOnAppear = true

    @FocusState private var isFocused: Bool

    private typealias Strings = L10n.Localizable.ExportBackup
    private typealias Labels = L10n.Accessibility.ExportBackup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.SetBackupPassword.title)
                .font(.subheadline)
                .foregroundColor(calculatedColor)

            ZStack {
                if isPasswordVisible {
                    TextField(Strings.SetBackupPassword.placeholder, text: $password)
                        .font(.body)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isFocused)
                } else {
                    SecureField(Strings.SetBackupPassword.placeholder, text: $password)
                        .font(.body)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isFocused)
                }
                HStack {
                    Spacer()
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 10)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(
                        calculatedColor,
                        lineWidth: password.isEmpty ? 0 : 1
                    )
            )

            passwordRules
                .font(.caption)
                .foregroundColor(calculatedColor)
        }
        .onAppear {
            if focusOnAppear {
                isFocused = true
            }
        }
    }

    // MARK: - Helper

    // TODO: [WPB-15211] actually there are different gray colors for the title, the border and the rules text.
    private var calculatedColor: Color {
        switch (password.isEmpty, isPasswordValid) {
        case (_, false):
            ColorTheme.Base.error.color
        case (true, _):
            ColorTheme.Base.labelTitle.color
        case (false, true):
            ColorTheme.Base.primary.color
        }
    }
}

// MARK: - Previews

private typealias Strings = L10n.Localizable.ExportBackup

#Preview("Invalid Password - Hidden") {
    PasswordFieldView(
        passwordRules: Text(Strings.SetBackupPassword.rules),
        password: .constant(""),
        isPasswordVisible: false
    )
}

#Preview("Invalid Password - Visible") {
    PasswordFieldView(
        passwordRules: Text(Strings.SetBackupPassword.rules),
        password: .constant("ValidPassword1!"),
        isPasswordVisible: true
    )
}

#Preview("Valid Password - Hidden") {
    PasswordFieldView(
        passwordRules: Text(Strings.SetBackupPassword.rules),
        password: .constant("ValidPassword1!"),
        isPasswordVisible: false
    )
}

#Preview("Valid Password - Visible") {
    PasswordFieldView(
        passwordRules: Text(Strings.SetBackupPassword.rules),
        password: .constant("ValidPassword1!"),
        isPasswordVisible: true
    )
}

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
    @Binding var isPasswordVisible: Bool
    let title: Text
    var isPasswordValid: Bool = true
    let passwordRules: Text?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            title
                .font(.subheadline)
                .foregroundColor(isPasswordValid ? ColorTheme.Base.secondaryText.color : ColorTheme.Base.error.color
                )

            ZStack {
                if isPasswordVisible {
                    TextField(
                        L10n.ExportBackup.SetBackupPassword.placeholder, text: $password
                    )
                    .font(.textStyle(.body1))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(
                                isPasswordValid ? ColorTheme.Base.secondaryText.color : ColorTheme.Base.error.color,
                                lineWidth: password.isEmpty ? 0 : 1
                            )
                    )
                } else {
                    SecureField(L10n.ExportBackup.SetBackupPassword.placeholder, text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(
                                    isPasswordValid ? ColorTheme.Base.secondaryText.color : ColorTheme.Base.error.color,
                                    lineWidth: password.isEmpty ? 0 : 11
                                )
                        )
                }
                HStack {
                    Spacer()
                    Button(action: {
                        isPasswordVisible.toggle()
                    }, label: {
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                            .foregroundColor(.gray)
                    })
                    .padding(.trailing, 10)
                }
            }

            passwordRules
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
        isPasswordVisible: .constant(false),
        title: Text(L10n.ExportBackup.SetBackupPassword.title),
        isPasswordValid: false,
        passwordRules: Text(L10n.ExportBackup.SetBackupPassword.rules)
    )
}

@available(iOS 17, *)
#Preview("Invalid Password - Visible") {
    PasswordFieldView(
        password: .constant("ValidPassword1!"),
        isPasswordVisible: .constant(true),
        title: Text(L10n.ExportBackup.SetBackupPassword.title),
        isPasswordValid: false,
        passwordRules: Text(L10n.ExportBackup.SetBackupPassword.rules)
    )
}

@available(iOS 17, *)
#Preview("Valid Password - Hidden") {
    PasswordFieldView(
        password: .constant("ValidPassword1!"),
        isPasswordVisible: .constant(false),
        title: Text(L10n.ExportBackup.SetBackupPassword.title),
        isPasswordValid: true,
        passwordRules: Text(L10n.ExportBackup.SetBackupPassword.rules)
    )
}

@available(iOS 17, *)
#Preview("Valid Password - Visible") {
    PasswordFieldView(
        password: .constant("ValidPassword1!"),
        isPasswordVisible: .constant(true),
        title: Text(L10n.ExportBackup.SetBackupPassword.title),
        isPasswordValid: true,
        passwordRules: Text(L10n.ExportBackup.SetBackupPassword.rules)
    )
}

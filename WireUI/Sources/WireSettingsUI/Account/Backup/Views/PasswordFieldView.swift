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
import WireFoundation

struct PasswordFieldView: View {
    @Binding var password: String
    @Binding var isPasswordVisible: Bool
    var isPasswordValid: Bool = true
    let passwordRules: Text?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Localizable.ExportBackup.SetBackupPassword.title)
                .font(.subheadline)
                .foregroundColor(calculatedColor)

            ZStack {
                if isPasswordVisible {
                    TextField(
                        L10n.Localizable.ExportBackup.SetBackupPassword.placeholder,
                        text: $password
                    )
                    .wireTextStyle(.body1)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    SecureField(L10n.Localizable.ExportBackup.SetBackupPassword.placeholder, text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
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
        .padding(.horizontal)
    }

    // MARK: - Helper

    private var calculatedColor: Color {
        switch (password.isEmpty, isPasswordValid) {
        case (_, false):
            ColorTheme.Base.error.color
        case (true, _):
            ColorTheme.Base.secondaryText.color
        case (false, true):
            ColorTheme.Base.primary.color
        }
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview("Invalid Password - Hidden") {
    PasswordFieldView(
        password: .constant(""),
        isPasswordVisible: .constant(false),
        passwordRules: Text(L10n.Localizable.ExportBackup.SetBackupPassword.rules)
    ).environment(\.wireTextStyleMapping, PreviewTextStyleMapping())
}

@available(iOS 17, *)
#Preview("Invalid Password - Visible") {
    PasswordFieldView(
        password: .constant("ValidPassword1!"),
        isPasswordVisible: .constant(true),
        passwordRules: Text(L10n.Localizable.ExportBackup.SetBackupPassword.rules)
    )
}

@available(iOS 17, *)
#Preview("Valid Password - Hidden") {
    PasswordFieldView(
        password: .constant("ValidPassword1!"),
        isPasswordVisible: .constant(false),
        passwordRules: Text(L10n.Localizable.ExportBackup.SetBackupPassword.rules)
    )
}

@available(iOS 17, *)
#Preview("Valid Password - Visible") {
    PasswordFieldView(
        password: .constant("ValidPassword1!"),
        isPasswordVisible: .constant(true),
        passwordRules: Text(L10n.Localizable.ExportBackup.SetBackupPassword.rules)
    )
}

private func PreviewTextStyleMapping() -> WireTextStyleMapping {
    .init { _ in
        fatalError("not implemented for preview yet")
    } fontMapping: { textStyle in
        switch textStyle {
        case .body1:
            .body
        default:
            fatalError("not implemented for preview yet")
        }
    }
}

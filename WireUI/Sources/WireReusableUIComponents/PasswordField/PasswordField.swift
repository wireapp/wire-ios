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
public struct PasswordField: View {
    @FocusState private var isFocused: Bool
    // TextField and SecureField have different heights. Switching between them causes the view to jump.
    // But we also want their height to change with dynamic font sizes. Hence @ScaledMetric.
    @ScaledMetric private var fieldHeight: CGFloat = 48

    @State public private(set) var arePasswordRulesVisible: Bool
    @State public fileprivate(set) var isPasswordVisible: Bool
    @Binding public fileprivate(set) var isPasswordValid: Bool
    @Binding public fileprivate(set) var password: String

    private let passwordValidator: any PasswordValidator
    private let placeholder: String
    private let title: String

    public init(
        arePasswordRulesVisible: Bool = false,
        isPasswordVisible: Bool = false,
        isPasswordValid: Binding<Bool>,
        password: Binding<String>,
        passwordValidator: any PasswordValidator,
        placeholder: String,
        title: String
    ) {
        self.arePasswordRulesVisible = arePasswordRulesVisible
        self.isPasswordVisible = isPasswordVisible
        self._isPasswordValid = isPasswordValid
        self._password = password
        self.passwordValidator = passwordValidator
        self.placeholder = placeholder
        self.title = title
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(calculatedColor)

            HStack {
                if isPasswordVisible {
                    TextField(placeholder, text: $password)
                        .wireTextStyle(.body1)
                        .frame(height: fieldHeight)
                        .focused($isFocused)
                } else {
                    SecureField(placeholder, text: $password)
                        .frame(height: fieldHeight)
                        .focused($isFocused)
                }
                Spacer()
                Button(action: {
                    isPasswordVisible.toggle()
                }, label: {
                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                })
            }
            .padding(.horizontal, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(
                        calculatedColor,
                        lineWidth: password.isEmpty ? 0 : 1
                    )
            )

            if let passwordRules = passwordValidator.localizedRulesDescription,
               arePasswordRulesVisible {
                Text(passwordRules)
                    .font(.caption)
                    .foregroundColor(calculatedColor)
            }
        }
        .padding(.horizontal)
        .onChange(of: password, perform: { newPassword in
            isPasswordValid = passwordValidator.validate(newPassword)
        })
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

package struct MockPasswordValidator: PasswordValidator {
    let validationCallback: @Sendable (String) -> Bool

    package init(validationCallback: @Sendable @escaping (String) -> Bool) {
        self.validationCallback = validationCallback
    }

    package func validate(_ password: String) -> Bool {
        validationCallback(password)
    }

    package var localizedRulesDescription: String? {
        "Password rules"
    }
}

@available(iOS 17, *)
#Preview("Invalid Password - Hidden") {
    PasswordField(
        isPasswordVisible: false,
        isPasswordValid: .constant(false),
        password: .constant("Invalid password"),
        passwordValidator: MockPasswordValidator(validationCallback: { _ in false }),
        placeholder: L10n.Passwordtextfield.Preview.placeholder,
        title: L10n.Passwordtextfield.Preview.title
    )
}

@available(iOS 17, *)
#Preview("Invalid Password - Visible") {
    PasswordField(
        isPasswordVisible: true,
        isPasswordValid: .constant(false),
        password: .constant("Invalid password"),
        passwordValidator: MockPasswordValidator(validationCallback: { _ in false }),
        placeholder: L10n.Passwordtextfield.Preview.placeholder,
        title: L10n.Passwordtextfield.Preview.title
    )
}

@available(iOS 17, *)
#Preview("Valid Password - Hidden") {
    PasswordField(
        isPasswordVisible: false,
        isPasswordValid: .constant(true),
        password: .constant("Valid password!"),
        passwordValidator: MockPasswordValidator(validationCallback: { _ in true }),
        placeholder: L10n.Passwordtextfield.Preview.placeholder,
        title: L10n.Passwordtextfield.Preview.title
    )
}

@available(iOS 17, *)
#Preview("Valid Password - Visible") {
    PasswordField(
        isPasswordVisible: true,
        isPasswordValid: .constant(true),
        password: .constant("Valid password!"),
        passwordValidator: MockPasswordValidator(validationCallback: { _ in true }),
        placeholder: L10n.Passwordtextfield.Preview.placeholder,
        title: L10n.Passwordtextfield.Preview.title
    )
}

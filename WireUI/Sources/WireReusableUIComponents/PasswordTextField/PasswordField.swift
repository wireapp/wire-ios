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

public final class PasswordFieldViewModel: ObservableObject {
    @Published public private(set) var arePasswordRulesVisible: Bool
    @Published public fileprivate(set) var isPasswordValid: Bool
    @Published public fileprivate(set) var isPasswordVisible: Bool
    @Published public fileprivate(set) var password: String

    fileprivate let passwordValidator: any PasswordValidator

    public init(
        arePasswordRulesVisible: Bool = false,
        isPasswordVisible: Bool = false,
        password: String = "",
        passwordValidator: any PasswordValidator
    ) {
        self.arePasswordRulesVisible = arePasswordRulesVisible

        self.isPasswordVisible = isPasswordVisible
        self.password = password
        self.passwordValidator = passwordValidator

        self.isPasswordValid = passwordValidator.validate(password)
    }
}

// [WPB-15571] Add accessibility strings to the mask / unmask buttons
public struct PasswordField: View {
    @FocusState private var isFocused: Bool
    @ObservedObject private var viewModel: PasswordFieldViewModel

    private let placeholder: String
    private let title: String

    public init(
        viewModel: PasswordFieldViewModel,
        placeholder: String,
        title: String
    ) {
        self.viewModel = viewModel
        self.placeholder = placeholder
        self.title = title
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(calculatedColor)

            ZStack {
                if viewModel.isPasswordVisible {
                    TextField(placeholder, text: $viewModel.password)
                        .wireTextStyle(.body1)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isFocused)
                } else {
                    SecureField(placeholder, text: $viewModel.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isFocused)
                }
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.isPasswordVisible.toggle()
                    }, label: {
                        Image(systemName: viewModel.isPasswordVisible ? "eye" : "eye.slash")
                            .foregroundColor(.gray)
                    })
                    .padding(.trailing, 10)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(
                        calculatedColor,
                        lineWidth: viewModel.password.isEmpty ? 0 : 1
                    )
            )

            if let passwordRules = viewModel.passwordValidator.localizedRulesDescription,
               viewModel.arePasswordRulesVisible {
                Text(passwordRules)
                    .font(.caption)
                    .foregroundColor(calculatedColor)
            }
        }
        .padding(.horizontal)
        .onChange(of: viewModel.password, perform: { newPassword in
            viewModel.isPasswordValid = viewModel.passwordValidator.validate(newPassword)
        })
    }

    // MARK: - Helper

    private var calculatedColor: Color {
        switch (viewModel.password.isEmpty, viewModel.isPasswordValid) {
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
        viewModel: PasswordFieldViewModel(
            isPasswordVisible: false,
            password: "Invalid password",
            passwordValidator: MockPasswordValidator(validationCallback: { _ in false })
        ),
        placeholder: L10n.Passwordtextfield.Preview.placeholder,
        title: L10n.Passwordtextfield.Preview.title
    )
}

@available(iOS 17, *)
#Preview("Invalid Password - Visible") {
    PasswordField(
        viewModel: PasswordFieldViewModel(
            isPasswordVisible: true,
            password: "Invalid password",
            passwordValidator: MockPasswordValidator(validationCallback: { _ in false })
        ),
        placeholder: L10n.Passwordtextfield.Preview.placeholder,
        title: L10n.Passwordtextfield.Preview.title
    )
}

@available(iOS 17, *)
#Preview("Valid Password - Hidden") {
    PasswordField(
        viewModel: PasswordFieldViewModel(
            isPasswordVisible: false,
            password: "Valid password!",
            passwordValidator: MockPasswordValidator(validationCallback: { _ in true })
        ),
        placeholder: L10n.Passwordtextfield.Preview.placeholder,
        title: L10n.Passwordtextfield.Preview.title
    )
}

@available(iOS 17, *)
#Preview("Valid Password - Visible") {
    PasswordField(
        viewModel: PasswordFieldViewModel(
            isPasswordVisible: true,
            password: "Valid password!",
            passwordValidator: MockPasswordValidator(validationCallback: { _ in true })
        ),
        placeholder: L10n.Passwordtextfield.Preview.placeholder,
        title: L10n.Passwordtextfield.Preview.title
    )
}

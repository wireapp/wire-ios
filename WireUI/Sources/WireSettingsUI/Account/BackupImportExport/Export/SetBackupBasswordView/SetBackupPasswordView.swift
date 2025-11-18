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
import WireLocators

struct SetBackupPasswordView: View {

    @StateObject var viewModel: SetBackupPasswordViewModel

    var focusPasswordFieldOnAppear = true
    private let isContextMenuAllowed: Bool

    @Environment(\.wireAccentColor) private var wireAccentColor

    private typealias Strings = L10n.Localizable
    private typealias Labels = L10n.Accessibility.ExportBackup

    init(
        viewModel: SetBackupPasswordViewModel,
        focusPasswordFieldOnAppear: Bool = true,
        isContextMenuAllowed: Bool
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.focusPasswordFieldOnAppear = focusPasswordFieldOnAppear
        self.isContextMenuAllowed = isContextMenuAllowed
    }

    var body: some View {
        NavigationStack {
            setBackupPasswordView
                .background(Color.viewBackground)
                .scrollContentBackground(.hidden)
                .navigationTitle(Strings.ExportBackup.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(Strings.ExportBackup.Cancel.title, action: viewModel.cancel)
                            .accessibilityLabel(Labels.Cancel.label)
                            .accessibilityIdentifier("cancel")
                    }
                }
        }
    }

    @ViewBuilder private var setBackupPasswordView: some View {
        VStack {

            ScrollView(content: scrollViewContent)
                .scrollBounceBehavior(.basedOnSize)

            Spacer()

            Button(Strings.ExportBackup.button, action: viewModel.triggerExport)
                .bold()
                .disabled(!viewModel.isPasswordValid)
                .wireButtonStyle(.primary)
                .padding()
                .accessibilityIdentifier(Locators.SetPasswordPage.backUpNowButton.rawValue)
        }
    }

    @ViewBuilder
    private func scrollViewContent() -> some View {
        VStack(alignment: .leading, spacing: 0) {

            Text(Strings.ExportBackup.description)
                .font(.body)
                .padding(.bottom, 28)

            passwordField
                .padding(.bottom, 8)

            footer

        }
        .padding()
    }

    // TODO: [WPB-16061] the following code is similar to the one in EnterPasswordView.swift, try to reuse

    @ViewBuilder private var passwordField: some View {

        Text(Strings.ExportBackup.SetBackupPassword.title)
            .foregroundStyle(passwordFieldTitleColor)
            .font(.subheadline)
            .padding(.bottom, 2)

        ToggleablePasswordField(
            password: $viewModel.password,
            placeholder: Strings.ExportBackup.SetBackupPassword.placeholder,
            placeholderColor: passwordFieldPlaceholderColor,
            focusOnAppear: focusPasswordFieldOnAppear,
            isContextMenuAllowed: isContextMenuAllowed
        )
        .tint(passwordFieldBorderColor)
    }

    private var passwordFieldTitleColor: Color {
        if !viewModel.isPasswordValid {
            ColorTheme.Base.error.color
        } else if viewModel.password.isEmpty {
            UIColor { $0.userInterfaceStyle != .dark
                ? BaseColorPalette.Grays.gray80
                : BaseColorPalette.Grays.gray40
            }.color
        } else {
            Color(wireAccentColor)
        }
    }

    private var passwordFieldPlaceholderColor: Color {
        if !viewModel.isPasswordValid {
            ColorTheme.Base.error.color
        } else if viewModel.password.isEmpty {
            UIColor { $0.userInterfaceStyle != .dark
                ? BaseColorPalette.Grays.gray70
                : BaseColorPalette.Grays.gray60
            }.color
        } else {
            Color(wireAccentColor)
        }
    }

    private var passwordFieldBorderColor: Color {
        if !viewModel.isPasswordValid {
            ColorTheme.Base.error.color
        } else if viewModel.password.isEmpty {
            UIColor { $0.userInterfaceStyle != .dark
                ? BaseColorPalette.Grays.gray40
                : BaseColorPalette.Grays.gray80
            }.color
        } else {
            Color(wireAccentColor)
        }
    }

    @ViewBuilder private var footer: some View {

        let footer = Text(viewModel.localizedPasswordRules)
            .font(.caption)

        if !viewModel.isPasswordValid {

            footer
                .foregroundStyle(ColorTheme.Base.error.color)

        } else {

            let footerColor = UIColor { $0.userInterfaceStyle != .dark
                ? BaseColorPalette.Grays.gray70
                : BaseColorPalette.Grays.gray40
            }
            footer
                .foregroundStyle(footerColor.color)

        }
    }

}

#Preview {
    SetBackupPasswordPreview()
        .tint(.purple)
}

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

struct SetBackupPasswordView: View {

    @StateObject var viewModel: SetBackupPasswordViewModel

    private typealias Strings = L10n.Localizable
    private typealias Labels = L10n.Accessibility.ExportBackup

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

            if #available(iOS 16.4, *) {
                ScrollView(content: scrollViewContent)
                    .scrollBounceBehavior(.basedOnSize)
            } else {
                ScrollView(content: scrollViewContent)
            }

            Spacer()

            Button(Strings.ExportBackup.button, action: viewModel.triggerExport)
                .bold()
                .disabled(!viewModel.isPasswordValid)
                .wireButtonStyle(.primary)
                .padding()
        }
    }

    @ViewBuilder
    private func scrollViewContent() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text(Strings.ExportBackup.description)
                .font(.body)
                .padding(.bottom, 28)

            passwordField
                .padding(.bottom, 8)

            footer

            Spacer()
        }
        .padding()
    }

    // TODO: [WPB-16061] the following code is similar to the one in EnterPasswordView.swift, try to reuse

    @ViewBuilder
    private var passwordField: some View {

        let title = Text(Strings.ExportBackup.SetBackupPassword.title)
                .font(.subheadline)
                .padding(.bottom, 2)

        let placeholderColor = UIColor { $0.userInterfaceStyle != .dark
            ? BaseColorPalette.Grays.gray70
            : BaseColorPalette.Grays.gray60
        }
        let passwordField = ToggleablePasswordField(
            password: $viewModel.password,
            placeholder: Strings.ExportBackup.SetBackupPassword.placeholder,
            placeholderColor: placeholderColor.color,
            focusOnAppear: true
        )

        if !viewModel.isPasswordValid {

            // use red for errors
            title
                .foregroundStyle(ColorTheme.Base.error.color)
            passwordField
                .tint(ColorTheme.Base.error.color)

        } else if viewModel.password.isEmpty {

            // use some gray when the field is empty
            let titleColor = UIColor { $0.userInterfaceStyle != .dark
                ? BaseColorPalette.Grays.gray80
                : BaseColorPalette.Grays.gray40
            }
            let fieldBorder = UIColor { $0.userInterfaceStyle != .dark
                ? BaseColorPalette.Grays.gray80
                : BaseColorPalette.Grays.gray40
            }
            title
                .foregroundStyle(titleColor.color)
            passwordField
                .tint(fieldBorder.color)

        } else {

            // use the tint color (user's accent color) when non-empty
            title
                .foregroundStyle(.tint)
            passwordField

        }
    }

    @ViewBuilder
    private var footer: some View {

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

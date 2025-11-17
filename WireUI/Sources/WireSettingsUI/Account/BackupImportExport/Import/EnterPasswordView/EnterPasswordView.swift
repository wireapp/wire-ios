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

struct EnterPasswordView: View {

    @Binding var password: String
    @Binding var passwordIsWrong: Bool
    var focusPasswordFieldOnAppear = true

    let continueAction: (_ password: String) -> Void
    let cancelAction: () -> Void
    let isContextMenuAllowed: Bool

    @Environment(\.wireAccentColor) private var wireAccentColor
    @Environment(\.wireAccentColorMapping) private var wireAccentColorMapping

    private typealias Strings = L10n.Localizable.ImportBackup
    private typealias Labels = L10n.Accessibility.ImportBackup

    var body: some View {
        NavigationStack {
            enterPasswordView
                .background(ColorTheme.Backgrounds.background.color)
                .navigationTitle(Strings.EnterPassword.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(Strings.Cancel.title, action: cancelAction)
                            .accessibilityLabel(Labels.Cancel.label)
                            .accessibilityIdentifier("cancel")
                    }
                }
        }
    }

    @ViewBuilder private var enterPasswordView: some View {
        VStack {

            ScrollView(content: scrollViewContent)
                .scrollBounceBehavior(.basedOnSize)

            Spacer()

            Button(Strings.EnterPassword.Button.title) {
                continueAction(password)
            }
            .bold()
            .disabled(password.isEmpty || passwordIsWrong)
            .wireButtonStyle(.primary)
            .padding()
        }
    }

    @ViewBuilder
    private func scrollViewContent() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text(Strings.EnterPassword.description)
                .font(.body)
                .padding(.bottom, 28)

            Text(Strings.EnterPassword.TextField.title)
                .foregroundStyle(passwordFieldTitleColor)
                .font(.subheadline)
                .padding(.bottom, 2)

            ToggleablePasswordField(
                password: $password,
                placeholder: Strings.EnterPassword.TextField.placeholder,
                placeholderColor: passwordFieldPlaceholderColor,
                focusOnAppear: focusPasswordFieldOnAppear,
                isContextMenuAllowed: isContextMenuAllowed
            )
            .tint(passwordFieldBorderColor)
            .padding(.bottom, 8)

            if passwordIsWrong {
                Text(Strings.EnterPassword.wrongPassword)
                    .foregroundStyle(passwordFooterColor)
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
    }

    private var passwordFieldTitleColor: Color {
        if passwordIsWrong {
            ColorTheme.Base.error.color
        } else if password.isEmpty {
            UIColor { $0.userInterfaceStyle != .dark
                ? BaseColorPalette.Grays.gray80
                : BaseColorPalette.Grays.gray40
            }.color
        } else {
            wireAccentColorMapping?.color(for: wireAccentColor) ?? ColorTheme.Base.primary.color
        }
    }

    private var passwordFieldPlaceholderColor: Color {
        if passwordIsWrong {
            ColorTheme.Base.error.color
        } else if password.isEmpty {
            UIColor { $0.userInterfaceStyle != .dark
                ? BaseColorPalette.Grays.gray70
                : BaseColorPalette.Grays.gray60
            }.color
        } else {
            wireAccentColorMapping?.color(for: wireAccentColor) ?? ColorTheme.Base.primary.color
        }
    }

    private var passwordFieldBorderColor: Color {
        if passwordIsWrong {
            ColorTheme.Base.error.color
        } else if password.isEmpty {
            UIColor { $0.userInterfaceStyle != .dark
                ? BaseColorPalette.Grays.gray40
                : BaseColorPalette.Grays.gray80
            }.color
        } else {
            wireAccentColorMapping?.color(for: wireAccentColor) ?? ColorTheme.Base.primary.color
        }
    }

    private var passwordFooterColor: Color {
        if passwordIsWrong {
            ColorTheme.Base.error.color
        } else {
            UIColor { $0.userInterfaceStyle != .dark
                ? BaseColorPalette.Grays.gray70
                : BaseColorPalette.Grays.gray40
            }.color
        }
    }

}

#Preview("empty") {
    EnterPasswordPreview()
}

#Preview("wrong") {
    EnterPasswordPreview(password: "some", isPasswordWrong: true)
}

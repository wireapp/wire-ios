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

    let continueAction: (_ password: String) -> Void
    let cancelAction: () -> Void

    var body: some View {
        NavigationStack {
            enterPasswordView
                .background(Color(uiColor: ColorTheme.Backgrounds.background))
                .navigationTitle(Text(L10n.Localizable.ImportBackup.EnterPassword.title))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: cancelAction) {
                            Text(L10n.Localizable.ImportBackup.Cancel.title)
                        }
                        .foregroundStyle(Color(uiColor: ColorTheme.Base.primary))
                        .accessibilityLabel(L10n.Accessibility.ImportBackup.Cancel.label)
                        .accessibilityIdentifier("cancel")
                    }
                }
        }
    }

    @ViewBuilder private var enterPasswordView: some View {
        VStack {

            let scrollView = ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    Text(L10n.Localizable.ImportBackup.EnterPassword.description)
                        .font(.body)
                        .padding(.bottom, 28)

                    Text(L10n.Localizable.ImportBackup.EnterPassword.TextField.title)
                        .foregroundStyle(passwordFieldTitleColor)
                        .font(.subheadline)
                        .foregroundStyle(Color(uiColor: BaseColorPalette.Grays.gray80))
                        .padding(.bottom, 2)

                    ToggleablePasswordField(
                        password: $password,
                        titleColor: passwordFieldTitleColor,
                        borderColor: passwordFieldBorderColor,
                        focusOnAppear: true
                    )
                    .padding(.bottom, 8)

                    if passwordIsWrong {
                        Text(L10n.Localizable.ImportBackup.EnterPassword.wrongPassword)
                            .foregroundStyle(passwordFieldTitleColor)
                            .font(.caption)
                            .foregroundStyle(Color(uiColor: BaseColorPalette.Grays.gray80))
                    }

                    Spacer()
                }
                .padding()
            }

            if #available(iOS 16.4, *) {
                scrollView
                    .scrollBounceBehavior(.basedOnSize)
            } else {
                scrollView
            }

            Spacer()

            Button(L10n.Localizable.ImportBackup.EnterPassword.Button.title) {
                continueAction(password)
            }
            .bold()
            .disabled(password.isEmpty || passwordIsWrong)
            .wireButtonStyle(.primary)
            .padding()
        }
    }

    private var passwordFieldTitleColor: Color {
        if passwordIsWrong {
            Color(uiColor: ColorTheme.Base.error)
        } else if password.isEmpty {
            Color(uiColor: BaseColorPalette.Grays.gray70)
        } else {
            Color(uiColor: ColorTheme.Base.primary)
        }
    }

    private var passwordFieldBorderColor: Color {
        if passwordIsWrong {
            Color(uiColor: ColorTheme.Base.error)
        } else if password.isEmpty {
            Color(uiColor: BaseColorPalette.Grays.gray40)
        } else {
            Color(uiColor: ColorTheme.Base.primary)
        }
    }
}

#Preview("empty") {
    EnterPasswordPreview()
}

#Preview("wrong") {
    EnterPasswordPreview(password: "some", isPasswordWrong: true)
}

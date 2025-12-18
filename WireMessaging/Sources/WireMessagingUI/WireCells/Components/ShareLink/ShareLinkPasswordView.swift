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
import WireMessagingDomain
import WireMessagingDomainSupport

private typealias Strings = L10n.Localizable.Conversation.WireCells.ShareLink.Password
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells.ShareLink

struct ShareLinkPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.wireAccentColor) private var wireAccentColor
    @State private var isPresentingRemovePasswordConfirmation = false

    @StateObject private var viewModel: ViewModel

    let id = UUID()

    init(viewModel: @autoclosure @escaping () -> ShareLinkPasswordView.ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            content()
                .navigationTitle(Text(Strings.title))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent()
                }
                .alert(
                    Strings.UnableToCreatePassword.title,
                    isPresented: $viewModel.isPresentingErrorAlert,
                    actions: {
                        Button(
                            Strings.UnableToCreatePassword.action,
                            action: {
                                Task {
                                    await viewModel.save()
                                    dismiss()
                                }
                            }
                        )

                        Button(
                            L10n.Localizable.General.cancel,
                            role: .cancel,
                            action: {}
                        )
                    },
                    message: { Text(Strings.UnableToCreatePassword.message) }
                )
                .alert(
                    Strings.RemoveConfirmation.title,
                    isPresented: $isPresentingRemovePasswordConfirmation,
                    actions: {
                        Button(
                            Strings.RemoveConfirmation.button,
                            action: {
                                Task {
                                    await viewModel.save()
                                    dismiss()
                                }
                            }
                        )

                        Button(
                            L10n.Localizable.General.cancel,
                            role: .cancel,
                            action: {}
                        )
                    },
                    message: { Text(Strings.RemoveConfirmation.message) }
                )
                .alert(
                    Strings.NoAccessToExisting.title,
                    isPresented: $viewModel.isPresentingNoAccessToExistingPasswordConfirmation,
                    actions: {
                        Button(
                            Strings.NoAccessToExisting.button,
                            action: { viewModel.resetPassword() }
                        )

                        Button(
                            L10n.Localizable.General.cancel,
                            role: .cancel,
                            action: {}
                        )
                    },
                    message: { Text(Strings.NoAccessToExisting.message) }
                )
                .background {
                    ColorTheme.Backgrounds.background.color
                        .ignoresSafeArea(edges: .all)
                }
                .tint(ColorTheme.Base.primary(wireAccentColor).color)
                .interactiveDismissDisabled(viewModel.isLoading)
        }
    }

    @ViewBuilder
    private func content() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                descriptionArea()

                setPasswordToggleArea()
                    .padding(.bottom, 18)

                if viewModel.displayPasswordInputArea {
                    Group {
                        if viewModel.hasChanges {
                            generatePasswordButton()
                            passwordInputArea()
                        }

                        if !viewModel.passwordInput.isEmpty {
                            sharePasswordButton()
                            resetPasswordButton()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    @ViewBuilder
    private func descriptionArea() -> some View {
        Text(Strings.description)
            .font(for: .subline1)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(ColorTheme.Base.secondaryText.color)
    }

    @ViewBuilder
    private func setPasswordToggleArea() -> some View {
        Toggle(isOn: $viewModel.isPasswordEnabled) {
            Text(Strings.setPasswordToggle)
                .font(for: .body1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(ColorTheme.Buttons.Secondary.enabled.color)
        }
    }

    @ViewBuilder
    private func generatePasswordButton() -> some View {
        Button {
            viewModel.generatePassword()
        } label: {
            Label {
                Text(Strings.generatePassword)
            } icon: {
                Image(systemName: "shield.righthalf.filled")
            }
            .font(for: .body2)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .stroke()
                    .foregroundStyle(ColorTheme.Buttons.Secondary.enabledOutline.color)
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(ColorTheme.Buttons.Secondary.enabled.color)
            }
        }
        .tint(.primaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func passwordInputArea() -> some View {
        VStack(spacing: 4) {
            Text(Strings.textfieldTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(for: .body1)

            HStack {
                passwordInputField()
                passwordInputShowHideButton()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .stroke()
                    .foregroundStyle(ColorTheme.Buttons.Secondary.enabledOutline.color)
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(ColorTheme.Buttons.Secondary.enabled.color)
            }
        }
    }

    @ViewBuilder
    private func passwordInputField() -> some View {
        let prompt = Text(Strings.textfieldPrompt)

        Group {
            if viewModel.isPasswordInputSecured {
                SecureField(text: $viewModel.passwordInput, prompt: prompt, label: { EmptyView() })
            } else {
                TextField(text: $viewModel.passwordInput, prompt: prompt, label: { EmptyView() })
                    .padding(.bottom, 0.5) // adjustment so that the text of the both fields align perfectly.
            }
        }
        .textContentType(.password)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }

    @ViewBuilder
    private func passwordInputShowHideButton() -> some View {
        Button {
            viewModel.isPasswordInputSecured.toggle()
        } label: {
            ZStack {
                Image(systemName: "eye.fill")
                    .opacity(viewModel.isPasswordInputSecured ? 0 : 1)

                Image(systemName: "eye.slash.fill")
                    .opacity(viewModel.isPasswordInputSecured ? 1 : 0)
            }
            .padding(.vertical, 2)
        }
        .tint(.primaryText)
        .accessibilityLabel(
            Text(viewModel.isPasswordInputSecured ? Accessibility.showPassword : Accessibility.hidePassword)
        )
    }

    @ViewBuilder
    private func sharePasswordButton() -> some View {
        ShareLink(item: viewModel.copyPassword()) {
            Label {
                Text(Strings.sharePassword)
            } icon: {
                Image(systemName: "document.on.document")
            }
            .font(for: .body2)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .stroke()
                    .foregroundStyle(ColorTheme.Buttons.Secondary.enabledOutline.color)
            }
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .foregroundStyle(ColorTheme.Buttons.Secondary.enabled.color)
            }
        }
        .tint(.primaryText)
    }

    @ViewBuilder
    private func resetPasswordButton() -> some View {
        Button {
            withAnimation(.snappy) {
                viewModel.resetPassword()
            }
        } label: {
            Label {
                Text(Strings.resetPassword)
            } icon: {
                Image(systemName: "arrow.counterclockwise")
            }
            .font(for: .body2)
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .stroke()
                    .foregroundStyle(ColorTheme.Buttons.Secondary.enabledOutline.color)
            }
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .foregroundStyle(ColorTheme.Buttons.Secondary.enabled.color)
            }
        }
        .tint(.primaryText)
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(role: .cancel) {
                dismiss()
            } label: {
                Text(L10n.Localizable.General.cancel)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task {
                    if !viewModel.isPasswordEnabled {
                        isPresentingRemovePasswordConfirmation = true
                    } else {
                        await viewModel.save()
                        dismiss()
                    }
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(ColorTheme.Base.secondaryText.color)
                } else {
                    Text(L10n.Localizable.General.save)
                        .bold()
                }
            }
            .disabled(!viewModel.canSave)
        }
    }
}

#Preview("Preview with password") {
    ShareLinkPasswordView(
        viewModel: .preview(password: "test", requiresPassword: true)
    )
}

#Preview("Preview without password") {
    ShareLinkPasswordView(
        viewModel: .preview(password: nil, requiresPassword: false)
    )
}

#Preview("Preview requires password, no password found") {
    ShareLinkPasswordView(
        viewModel: .preview(password: nil, requiresPassword: true)
    )
}

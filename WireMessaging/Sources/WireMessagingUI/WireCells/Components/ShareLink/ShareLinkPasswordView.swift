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

    @ObservedObject var viewModel: ShareLinkViewModel
    
    init(viewModel: ShareLinkViewModel) {
        self.viewModel = viewModel
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
                    Strings.RemoveConfirmation.title,
                    isPresented: $viewModel.isPresentingRemovePasswordConfirmation,
                    actions: {
                        Button(
                            Strings.RemoveConfirmation.button,
                            action: { viewModel.removePassword() }
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
                            action: { viewModel.changePassword() }
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
        }
    }
    
    @ViewBuilder private func content() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                descriptionArea()
                
                setPasswordToggleArea()
                    .padding(.bottom, 18)
                
                Group {
                    generatePasswordButton()
                    
                    passwordInputArea()
                    
                    copyPasswordButton()
                    
                    changePasswordButton()
                        .padding(.top, 24)
                }
                .disabled(!viewModel.isPasswordEnabled)
                .opacity(viewModel.isPasswordEnabled ? 1 : 0.7)
                    
                alertTestButtons()
                    .padding(.top, 30)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
    
    @ViewBuilder private func descriptionArea() -> some View {
        Text(Strings.description)
            .font(for: .subline1)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(ColorTheme.Base.secondaryText.color)
    }
    
    @ViewBuilder private func setPasswordToggleArea() -> some View {
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
    
    @ViewBuilder private func generatePasswordButton() -> some View {
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
    
    @ViewBuilder private func passwordInputArea() -> some View {
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
    
    @ViewBuilder private func passwordInputField() -> some View {
        let prompt = Text(Strings.textfieldPrompt)
        
        Group {
            if viewModel.isPasswordInputSecured {
                SecureField(text: $viewModel.passwordInput, prompt: prompt, label: { EmptyView() })
            } else {
                TextField(text: $viewModel.passwordInput, prompt: prompt, label: { EmptyView() })
                    .padding(.bottom, 0.5) //adjustment so that the text of the both fields align perfectly.
            }
        }
        .textContentType(.password)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }
    
    @ViewBuilder private func passwordInputShowHideButton() -> some View {
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

    @ViewBuilder private func copyPasswordButton() -> some View {
        Button {
            viewModel.copyPasswordToPasteboard()
        } label: {
            Label {
                Text(Strings.copyPassword)
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
    
    @ViewBuilder private func changePasswordButton() -> some View {
        Button {
            //TODO: ...
        } label: {
            Label {
                Text(Strings.changePassword)
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
    
    @ViewBuilder private func alertTestButtons() -> some View {
        VStack {
            Button {
                viewModel.isPresentingRemovePasswordConfirmation = true
            } label: {
                Text("show\n\"remove password\"\nconfirmation alert")
            }
            
            Button {
                viewModel.isPresentingNoAccessToExistingPasswordConfirmation = true
            } label: {
                Text("show\n\"no access to existing password\"\nalert")
            }
        }
        .buttonStyle(.bordered)
        .font(for: .subline1)
    }
    
    @ToolbarContentBuilder private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(role: .cancel) {
                dismiss()
            } label: {
                Text(L10n.Localizable.General.cancel)
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.pendingChangePassword = viewModel.currentPassword
                dismiss()
            } label: {
                Text(L10n.Localizable.General.save)
                    .bold()
            }
            .disabled(!viewModel.canSavePassword)
        }
    }
}

#Preview {
    let item = FilesViewItem(
        id: UUID(),
        kind: .file,
        name: "some_file.pdf",
        filePath: "some/path",
        ownedBy: nil,
        modifiedAt: nil,
        icon: .document,
        tags: []
    )
    
    ShareLinkPasswordView(
        viewModel: .init(fileItem: item)
    )
}

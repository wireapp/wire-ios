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
private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

struct ShareLinkPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.wireAccentColor) private var wireAccentColor

    @StateObject private var viewModel: ViewModel = .init()
    
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
                
                generatePasswordButton()
                
                passwordInputArea()
                
                copyPasswordButton()
                
                changePasswordButton()
                    .padding(.top, 24)
                
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
        Toggle(isOn: .constant(true)) {
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
            //TODO: ...
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
        Text("(password input area)")
    }
    
    @ViewBuilder private func copyPasswordButton() -> some View {
        Button {
            //TODO: ...
        } label: {
            Label {
                Text(Strings.copyPassword)
            } icon: {
                Image(systemName: "document.on.document")
            }
            .font(for: .body2)
            .padding(.vertical, 12)
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
                viewModel.save()
            } label: {
                Text(L10n.Localizable.General.save)
                    .bold()
            }
            .disabled(!viewModel.canSave)
        }
    }
}

#Preview {
    ShareLinkPasswordView()
}

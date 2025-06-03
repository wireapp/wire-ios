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
import WireReusableUIComponents

struct CreatePersonalAccountView: View {

    @StateObject private var viewModel: CreatePersonalAccountViewModel
    @Environment(\.dismiss) private var dismiss

    private typealias Strings = L10n.Localizable.CreatePersonalAccount
    private typealias Labels = L10n.Accessibility.CreatePersonalAccount

    package init(viewModel: CreatePersonalAccountViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                scrollViewContent
            }
            .sheet(isPresented: $viewModel.isCreateTeamAccountPresented, onDismiss: {
                dismiss()
            }, content: {
                if let teamAccountCreationLink = viewModel.teamAccountCreationLink {
                    SafariBrowserView(url: teamAccountCreationLink)
                        .ignoresSafeArea()
                }
            })
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle(Strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SheetCloseButton {
                        dismiss()
                    }
                    .accessibilityLabel(Labels.Close.label)
                }
            }
        }
    }

    @ViewBuilder private var scrollViewContent: some View {
        VStack(spacing: 24) {
            nameField
            emailField
            passwordField
            confirmPasswordField
            dataUsageAgreementView
            continueButton
            teamAccountCreationView
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    @ViewBuilder private var nameField: some View {
        LabeledTextField(
            placeholder: Strings.InputName.placeholder,
            title: Strings.InputName.title,
            string: $viewModel.name
        )
        .autocapitalization(.words)
        .autocorrectionDisabled()
        .textContentType(.name)
    }

    @ViewBuilder private var emailField: some View {
        LabeledTextField(
            placeholder: Strings.InputEmail.placeholder,
            title: Strings.InputEmail.title,
            string: $viewModel.email
        )
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .textContentType(.username)
        .keyboardType(.emailAddress)
    }

    @ViewBuilder private var passwordField: some View {
        PasswordField(
            password: $viewModel.password,
            placeholder: Strings.InputPassword.placeholder,
            title: Strings.InputPassword.title,
            passwordRules: "",
            isValidPassword: viewModel.isPasswordValid
        )
    }

    @ViewBuilder private var confirmPasswordField: some View {
        PasswordField(
            password: $viewModel.password,
            placeholder: Strings.InputConfirmPassword.placeholder,
            title: Strings.InputPassword.title,
            passwordRules: "",
            isValidPassword: viewModel.isPasswordValid
        )
    }


    @ViewBuilder private var dataUsageAgreementView: some View {
        Checkbox(
            isChecked: Binding(
                get: { viewModel.dataUsageAgreementAccepted },
                set: { viewModel.dataUsageAgreementAccepted = $0 }
            ),
            title: .formattedMarkdown(
                key: "create_personal_account.share_data_usage",
                bundle: .module,
                viewModel.privacyPolicyURL.absoluteString
            )
        )
    }

    @ViewBuilder private var continueButton: some View {
        Button(action: {
            Task {
                await viewModel.submitCredentials()
            }
        }, label: {
            Text(Strings.continue)
                .lineLimit(nil)
        })
        .wireButtonStyle(.primary)
        .bold()
        .disabled(!viewModel.canSubmitCredentials)
    }

    @ViewBuilder private var teamAccountCreationView: some View {
        VStack(spacing: 0) {
            Text(Strings.lookingForCollaboration)
                .multilineTextAlignment(.center)
            Button(
                action: {
                    viewModel.isCreateTeamAccountPresented = true
                },
                label: {
                    Text(Strings.createTeam)
                        .lineLimit(nil)
                }
            )
            .wireButtonStyle(.link)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

}

// TODO: move to ReusableUIComponents
struct Checkbox: View {
    @Binding var isChecked: Bool

    private let title: AttributedString

    init(isChecked: Binding<Bool>, title: AttributedString) {
        self._isChecked = isChecked
        self.title = title
    }

    init(isChecked: Binding<Bool>, title: String) {
        self._isChecked = isChecked
        self.title = AttributedString(title)
    }

    var body: some View {
        HStack {
            Button(action: {
                isChecked.toggle()
            }, label: {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24))
            })
            .buttonStyle(.plain)
            .foregroundStyle(isChecked ? ColorTheme.Checkbox.selected.color : ColorTheme.Checkbox.enabled.color)
            Text(title)
                .wireTextStyle(.subline1)
        }
    }
}

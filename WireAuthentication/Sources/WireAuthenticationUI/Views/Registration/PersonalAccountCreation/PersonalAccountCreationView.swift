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

struct PersonalAccountCreationView: View {

    @StateObject private var viewModel: PersonalAccountCreationViewModel
    @Environment(\.dismiss) private var dismiss

    private typealias Strings = L10n.Localizable.CreatePersonalAccount
    private typealias Labels = L10n.Accessibility.CreatePersonalAccount

    package init(
        factory: @autoclosure @escaping () -> PersonalAccountCreationFactory
    ) {
        self._viewModel = StateObject(wrappedValue: factory().viewModel)
    }

    package var body: some View {
        ScrollView {
            scrollViewContent
                .navigationTitle(Strings.title)
                .navigationBarTitleDisplayMode(.inline)
                .setPreferredSize(navigationBarHidden: false)
                .customBackButton()
                .background(ColorTheme.Backgrounds.surface.color)
        }
        .alert(
            item: $viewModel.alert,
            title: { Text($0.title) },
            message: { Text($0.message) },
            actions: { _ in
                Button(Strings.ConfirmationAlert.accept, action: {
                    Task {
                        try? await viewModel.requestEmailVerificationCode()
                    }
                })
                Button(Strings.ConfirmationAlert.view) {
                    viewModel.personalAccountCreationAnalyticsTracker.setUp()
                }
                Button(Strings.ConfirmationAlert.cancel, action: {})
            }
        )
        .presentationDetents([.large])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder private var scrollViewContent: some View {
        VStack(spacing: 20) {
            nameField
            emailField
            passwordField
            confirmPasswordField
            dataUsageAgreementView
            continueButton
            teamAccountCreationView

        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
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
            password: $viewModel.confirmedPassword,
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
            viewModel.alert = .termsOfUse
        }, label: {
            Text(Strings.continue)
                .lineLimit(nil)
        })
        .wireButtonStyle(.primary)
        .bold()
        .disabled(!viewModel.canRequestVerificationCode)
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

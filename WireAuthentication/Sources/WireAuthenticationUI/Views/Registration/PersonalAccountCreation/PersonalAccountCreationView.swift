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
import WireLocators

package struct PersonalAccountCreationView: View {

    @StateObject private var viewModel: PersonalAccountCreationViewModel

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
        .navigationDestination(for: PersonalAccountCreationDestination.self) {
            switch $0 {
            case let .verifyEmail(email, password, name):
                VerificationEmailCodeView(
                    factory: viewModel.factory.verificationEmailCodeFactory(
                        email: email,
                        password: password,
                        name: name,
                        trackingConsent: viewModel.trackingConsent
                    )
                )
            }
        }
        .sheet(isPresented: $viewModel.isCreateTeamAccountPresented, content: {
            if let teamAccountCreationLink = viewModel.teamAccountCreationLink {
                SafariBrowserView(url: teamAccountCreationLink).ignoresSafeArea()
            }
        })
        .alert(
            item: $viewModel.alert,
            title: { Text($0.title) },
            message: { Text($0.message) },
            actions: { alert in
                if alert == .termsOfUse {
                    Button(Strings.ConfirmationAlert.accept, action: {
                        Task {
                            try? await viewModel.requestEmailVerificationCode()
                        }
                    })
                    Button(Strings.ConfirmationAlert.view, action: {
                        viewModel.showTermsOfUse()
                    })
                    Button(Strings.ConfirmationAlert.cancel, action: {})
                }
            }
        )
        .presentationDetents([.large])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder private var scrollViewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            nameField
            emailField
            passwordField
            confirmPasswordField
            if viewModel.isAnalyticsTrackingAvailable {
                dataUsageAgreementView
            }
            continueButton

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
        .accessibilityIdentifier(Locators.CreatePersonalAccountFormPage.enterNameField.rawValue)
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
            passwordRules: viewModel.localizedPasswordRules,
            isValidPassword: { _ in viewModel.isPasswordValid }
        )
        .accessibilityIdentifier(Locators.CreatePersonalAccountFormPage.enterPasswordField.rawValue)
    }

    @ViewBuilder private var confirmPasswordField: some View {
        PasswordField(
            password: $viewModel.confirmedPassword,
            placeholder: Strings.InputConfirmPassword.placeholder,
            title: Strings.InputPassword.title,
            passwordRules: Strings.InputConfirmPassword.error,
            isValidPassword: { _ in viewModel.isPasswordMatchConfirmedPassword }
        )
        .accessibilityIdentifier(Locators.CreatePersonalAccountFormPage.enterConfirmPasswordField.rawValue)
    }

    @ViewBuilder private var dataUsageAgreementView: some View {
        Checkbox(
            isChecked: $viewModel.isDataUsageAgreementAccepted,
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
        .accessibilityIdentifier(Locators.CreatePersonalAccountFormPage.continueButton.rawValue)
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

private extension AttributedString {

    static func formattedMarkdown(
        key: String.LocalizationValue,
        bundle: Bundle? = nil,
        _ arguments: any CVarArg...
    ) -> AttributedString {
        let string: String = .formated(key: key, bundle: bundle, arguments)
        return .markdown(from: string)
    }

    static func localizedMarkdown(key: String.LocalizationValue, bundle: Bundle? = nil) -> AttributedString {
        let string: String = .localized(key: key, bundle: bundle)
        return .markdown(from: string)
    }

    static func markdown(from string: String) -> AttributedString {
        var attributed = (try? AttributedString(markdown: string)) ?? AttributedString(string)

        for run in attributed.runs where run.link != nil {
            attributed[run.range].underlineStyle = .single
        }

        return attributed
    }

}

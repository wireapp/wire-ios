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
                VerificationEmailCodeView(factory: viewModel.factory.verificationEmailCodeFactory(
                    email: email,
                    password: password,
                    name: name
                ))
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
            passwordRules: viewModel.localizedPasswordRules,
            isValidPassword: { _ in viewModel.isPasswordValid }
        )
    }

    @ViewBuilder private var confirmPasswordField: some View {
        PasswordField(
            password: $viewModel.confirmedPassword,
            placeholder: Strings.InputConfirmPassword.placeholder,
            title: Strings.InputPassword.title,
            passwordRules: Strings.InputConfirmPassword.error,
            isValidPassword: { _ in viewModel.isPasswordMatchConfirmedPassword }
        )
    }

    @ViewBuilder private var dataUsageAgreementView: some View {
        Checkbox(
            isChecked: $viewModel.dataUsageAgreementAccepted,
            title: .formattedMarkdown2(
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

extension AttributedString {
    static func formattedMarkdown1(
        key: String,
        bundle: Bundle? = nil,
        _ arguments: CVarArg...
    ) -> AttributedString {
        let mainBundle = bundle ?? .main

        var string = String(format: NSLocalizedString(key, bundle: mainBundle, value: "", comment: ""), arguments)

        if string == key,
           let basePath = mainBundle.path(forResource: "en", ofType: "lproj"),
           let baseBundle = Bundle(path: basePath) {
            string = String(format: NSLocalizedString(key, bundle: baseBundle, value: "", comment: ""), arguments)
        }

        return (try? AttributedString(markdown: string)) ?? AttributedString(string)
    }
}

public extension String {
    static func formatedWithFallback(
        key: String.LocalizationValue,
        bundle: Bundle? = nil,
        _ arguments: [CVarArg]
    ) -> String {
        let mainBundle = bundle ?? .main
        let keyString = String(describing: key)

        let localized = String(format: NSLocalizedString(keyString, bundle: mainBundle, value: "", comment: ""), arguments)

        if localized != keyString {
            return localized
        }

        // Fallback: explicitly load from en.lproj
        if let enPath = mainBundle.path(forResource: "en", ofType: "lproj"),
           let enBundle = Bundle(path: enPath) {
            let fallback = NSLocalizedString(keyString, bundle: enBundle, value: "", comment: "")
            return String(format: fallback, arguments: arguments)
        }

        return keyString // last resort
    }
}

public extension AttributedString {
    static func formattedMarkdown2(
        key: String,
        bundle: Bundle? = nil,
        _ arguments: CVarArg...
    ) -> AttributedString {
        let mainBundle = bundle ?? .main

        // Get localized string
        let localized = String(format: NSLocalizedString(key, bundle: mainBundle, value: "", comment: ""), arguments)

        // If key wasn't found, fallback to en.lproj
        let resolved: String
        if localized == key,
           let enPath = mainBundle.path(forResource: "en", ofType: "lproj"),
           let enBundle = Bundle(path: enPath) {
            let fallback = NSLocalizedString(key, bundle: enBundle, value: "", comment: "")
            resolved = String(format: fallback, arguments: arguments)
        } else {
            resolved = localized
        }

        // Parse Markdown
        return markdown(from: resolved)
    }

    static func markdown(from string: String) -> AttributedString {
        var attributed = (try? AttributedString(markdown: string)) ?? AttributedString(string)

        for run in attributed.runs where run.link != nil {
            attributed[run.range].underlineStyle = .single
        }

        return attributed
    }
}

//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import Foundation

final class AuthenticationCredentialsViewModel {

    enum FlowType {
        case login(AuthenticationPrefilledCredentials?)
        case registration(AuthenticationPrefilledCredentials?)
        case reauthentication(AuthenticationPrefilledCredentials?)
    }

    enum FocusTarget: Equatable {
        case email
        case emailPassword
        case proxyUsername
        case none
    }

    enum PrefillTarget: Equatable {
        case registrationEmail(String)
        case emailPassword(email: String?)
        case none
    }

    enum Route {
        case submitEmail(String)
        case submitCredentials(EmailPasswordInput, AuthenticationProxyCredentialsInput?)
        case confirmEmailPasswordInput
        case focus(FocusTarget)
        case openForgotPassword
        case showCustomBackendInfo
        case none
    }

    struct DisplayState: Equatable {
        let isEmailPasswordInputHidden: Bool
        let isEmailInputHidden: Bool
        let isLoginButtonHidden: Bool
        let isForgotPasswordButtonHidden: Bool
    }

    struct LoginButtonInput {
        let isProxyCredentialsRequired: Bool
        let hasValidEmailPasswordInput: Bool
        let hasValidEmail: Bool
        let hasValidPassword: Bool
        let hasValidProxyUsername: Bool
        let hasValidProxyPassword: Bool
    }

    let flowType: FlowType
    var prefilledCredentials: AuthenticationPrefilledCredentials?

    var isRegistering: Bool {
        if case .registration = flowType {
            true
        } else {
            false
        }
    }

    var isReauthenticating: Bool {
        if case .reauthentication = flowType {
            true
        } else {
            false
        }
    }

    var shouldUseScrollView: Bool {
        switch flowType {
        case .login, .reauthentication:
            true
        case .registration:
            false
        }
    }

    var displayState: DisplayState {
        DisplayState(
            isEmailPasswordInputHidden: isRegistering,
            isEmailInputHidden: !isRegistering,
            isLoginButtonHidden: isRegistering,
            isForgotPasswordButtonHidden: isRegistering
        )
    }

    var contextualFirstResponder: FocusTarget {
        switch flowType {
        case .login, .reauthentication:
            .emailPassword
        case .registration:
            .email
        }
    }

    init(flowType: FlowType) {
        self.flowType = flowType

        switch flowType {
        case let .login(credentials),
             let .registration(credentials),
             let .reauthentication(credentials):
            self.prefilledCredentials = credentials
        }
    }

    func prefillTarget() -> PrefillTarget {
        guard let prefilledCredentials else { return .none }

        let email = prefilledCredentials.credentials.emailAddress
        if isRegistering, let email, !email.isEmpty {
            return .registrationEmail(email)
        } else {
            return .emailPassword(email: email)
        }
    }

    func canBeginEditingEmail(
        useWireAuthentication: Bool
    ) -> Bool {
        guard
            useWireAuthentication,
            isRegistering,
            prefilledCredentials?.credentials.emailAddress != nil
        else {
            return true
        }

        return false
    }

    func isLoginButtonEnabled(input: LoginButtonInput) -> Bool {
        guard input.isProxyCredentialsRequired else {
            return input.hasValidEmailPasswordInput
        }

        return input.hasValidEmail &&
            input.hasValidPassword &&
            input.hasValidProxyUsername &&
            input.hasValidProxyPassword
    }

    func loginButtonTapped(
        isProxyCredentialsRequired: Bool,
        email: String,
        password: String,
        proxyUsername: String,
        proxyPassword: String
    ) -> Route {
        guard isProxyCredentialsRequired else {
            return .confirmEmailPasswordInput
        }

        return .submitCredentials(
            EmailPasswordInput(email: email, password: password),
            AuthenticationProxyCredentialsInput(username: proxyUsername, password: proxyPassword)
        )
    }

    func emailConfirmed(_ email: String) -> Route {
        .submitEmail(email)
    }

    func credentialsConfirmed(
        email: String,
        password: String,
        isProxyCredentialsRequired: Bool
    ) -> Route {
        guard !isProxyCredentialsRequired else {
            return .focus(.proxyUsername)
        }

        return .submitCredentials(EmailPasswordInput(email: email, password: password), nil)
    }

    func credentialsSubmittedWithValidationError(
        isProxyCredentialsRequired: Bool,
        isPasswordEmpty: Bool
    ) -> Route {
        guard !isProxyCredentialsRequired, !isPasswordEmpty else {
            return .focus(.proxyUsername)
        }

        return .none
    }

    func forgotPasswordTapped() -> Route {
        .openForgotPassword
    }

    func customBackendInfoTapped() -> Route {
        .showCustomBackendInfo
    }
}

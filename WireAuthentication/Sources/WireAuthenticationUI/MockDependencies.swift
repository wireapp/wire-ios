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

import Foundation
import WireAuthenticationAPI
import WireReusableUIComponents

@MainActor
final class MockDependencies {

    private var rootViewModel: RootViewModel {
        RootViewModel()
    }

    private var backendConfig: BackendConfig {
        _backendConfig
    }

    var _backendConfig = BackendConfig(
        title: "backen name",
        endpoints: Endpoints(
            backendURL: URL(string: "https://example.com")!,
            backendWSURL: URL(string: "https://example.com")!,
            blackListURL: URL(string: "https://example.com")!,
            teamsURL: URL(string: "https://example.com")!,
            accountsURL: URL(string: "https://example.com")!,
            websiteURL: URL(string: "https://example.com")!),
        proxySettings: nil,
        pinnedKeys: nil
    )

    var rootView: RootView {
        RootView(
            viewModel: rootViewModel,
            factory: self
        )
    }

    func makeDetermineAuthMethodView(
        emailOrSSOCode: String,
        isLoading: Bool,
        alert: DetermineAuthMethodViewModel.Alert?
    ) -> DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: DetermineAuthMethodViewModel(
                router: rootViewModel,
                validateEmailOrSSOCode: self,
                determineAuthMethod: self,
                fetchBackendConfig: self,
                ssoLinkGenerator: self,
                emailOrSSOCode: emailOrSSOCode,
                isLoading: isLoading,
                alert: alert
            ),
            factory: self
        )
    }

}

extension MockDependencies: ValidateEmailOrSSOCodeUseCaseProtocol {

    nonisolated func invoke(input: String) throws -> ValidatedEmailOrSSOCode {
        if input.contains("@") {
            return .email(email: input, domain: input.components(separatedBy: "@").last!)
        } else if input.hasSuffix("wire") {
            return .ssoCode(UUID())
        } else {
            throw ValidatedEmailOrSSOCodeFailure.invalidInput
        }
    }

}

extension MockDependencies: DetermineAuthMethodUseCaseProtocol {
    func invoke(
        emailOrSSOCode: String
    ) async throws(DetermineAuthMethodUseCaseFailure) -> AuthenticationMethod {
        try! await Task.sleep(for: .seconds(3))

        return .loginViaEmail(email: emailOrSSOCode, didDetectDomainConflict: false)
    }
}

extension MockDependencies: FetchBackendConfigUseCaseProtocol {

    func invoke(at configURL: URL) async throws(FetchBackendConfigFailure) -> BackendConfig {
        BackendConfig(
            title: "backend name",
            endpoints: Endpoints(
                backendURL: URL(string: "example")!,
                backendWSURL: URL(string: "example")!,
                blackListURL: URL(string: "example")!,
                teamsURL: URL(string: "example")!,
                accountsURL: URL(string: "example")!,
                websiteURL: URL(string: "example")!
            ),
            proxySettings: nil,
            pinnedKeys: nil
        )
    }
}

extension MockDependencies: LoginViaEmailUseCaseProtocol {

    func invoke(
        email: String,
        password: String,
        verificationCode: String?
    ) async throws(LoginViaEmailUseCaseFailure) -> ([HTTPCookie], AccessToken) {
        ([], AccessToken(userID: UUID(), token: "", type: "", expirationDate: Date()))
    }

}

extension MockDependencies: RequestLoginVerificationCodeUseCaseProtocol {

    func invoke(email: String) async throws(WireAuthenticationAPI.RequestLoginVerificationCodeUseCaseFailure) {
        try! await Task.sleep(for: .seconds(3))
    }

}

extension MockDependencies: DetermineAuthMethodBuilder {

    private var determineAuthMethodViewModel: DetermineAuthMethodViewModel {
        DetermineAuthMethodViewModel(
            router: rootViewModel,
            validateEmailOrSSOCode: self,
            determineAuthMethod: self,
            fetchBackendConfig: self,
            ssoLinkGenerator: self
        )
    }

    var determineAuthMethodView: DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: determineAuthMethodViewModel,
            factory: self
        )
    }

}

extension MockDependencies: FetchDefaultSSOSettingsUseCaseProtocol {

    func invoke() async throws(FetchDefaultSSOSettingsUseCaseFailure) -> UUID? {
        nil
    }

}

extension MockDependencies: SwitchBackendConfirmationBuilder {

    private var switchBackendConfirmationViewModel: SwitchBackendConfirmationViewModel {
        SwitchBackendConfirmationViewModel(
            router: rootViewModel,
            email: "email",
            fetchDefaultSSOSettings: self,
            ssoLinkGenerator: self,
            environment: BackendConfig(
                title: "backendName",
                endpoints: Endpoints(
                    backendURL: URL(string: "backendURL")!,
                    backendWSURL: URL(string: "backendWSURL")!,
                    blackListURL: URL(string: "blacklistURL")!,
                    teamsURL: URL(string: "teamsURL")!,
                    accountsURL: URL(string: "accountsURL")!,
                    websiteURL: URL(string: "websiteURL")!
                ),
                proxySettings: nil,
                pinnedKeys: nil
            )
        )
    }

    func switchBackendView(email: String, environment: BackendConfig) -> SwitchBackendConfirmationView {
        SwitchBackendConfirmationView(viewModel: switchBackendConfirmationViewModel)
    }

}

extension MockDependencies: NoHistoryViewBuilder {

    private var noHistoryViewModel: NoHistoryViewModel {
        NoHistoryViewModel(
            userID: UUID(),
            cookies: [],
            accessToken: nil,
            didDetectDomainConflict: false,
            howToChangeEmailURL: URL(string: "https://wire.com")!,
            howToDeleteAccountURL: URL(string: "https://wire.com")!,
            onFlowCompletion: { _ in }
        )
    }

    func noHistoryView(
        userID: UUID,
        cookies: [HTTPCookie],
        accessToken: AccessToken?,
        didDetectDomainConflict: Bool
    ) -> NoHistoryView {
        NoHistoryView(viewModel: noHistoryViewModel)
    }

}

extension MockDependencies: SSOLinkGeneratorProtocol {

    func generateSSOLink(ssoCode: UUID) async throws -> URL {
        URL(string: "https://example.com/login/\(ssoCode)")!
    }

    func flushToken() {}

}

extension MockDependencies: LoginViaEmailBuilder {

    private func loginViewModel(email: String, canCreateAccount: Bool) -> LoginViaEmailViewModel {
        LoginViaEmailViewModel(
            router: rootViewModel,
            loginViaEmailUseCase: self,
            email: email,
            accountsURL: URL(string: "https://example.com")!,
            passwordValidator: MockPasswordValidator(validationCallback: { _ in true }),
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: false,
            onCreateAccount: {}
        )
    }

    func loginViaEmailView(
        email: String,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool
    ) -> LoginViaEmailView {
        LoginViaEmailView(
            viewModel: loginViewModel(email: email, canCreateAccount: canCreateAccount),
            factory: self
        )
    }

}

extension MockDependencies: VerificationCodeBuilder {

    func previewVerificationCodeView(
        email: String,
        password: String,
        code: [String] = ["", "", "", "", "", ""]
    ) -> VerificationCodeView {
        let viewModel = VerificationCodeViewModel(
            email: email,
            password: password,
            loginViaEmailUseCase: self,
            requestLoginVerificationCodeUseCase: self,
            router: rootViewModel,
            numberOfDigits: code.count,
            didDetectDomainConflict: false
        )
        viewModel.code = code

        return VerificationCodeView(viewModel: viewModel)
    }

    func verificationCodeView(
        email: String,
        password: String,
        didDetectDomainConflict: Bool
    ) -> VerificationCodeView {
        VerificationCodeView(
            viewModel: VerificationCodeViewModel(
                email: email,
                password: password,
                loginViaEmailUseCase: self,
                requestLoginVerificationCodeUseCase: self,
                router: rootViewModel,
                didDetectDomainConflict: false
            )
        )
    }

}

extension MockDependencies: LoginViaEmailOnPremBuilder {

    private func loginViaEmailOnPremViewModel(email: String, backendConfig: BackendConfig) -> LoginViaEmailOnPremViewModel {
        LoginViaEmailOnPremViewModel(
            router: rootViewModel,
            loginViaEmailUseCase: self,
            email: email,
            backendConfig: backendConfig,
            passwordValidator: MockPasswordValidator(validationCallback: { _ in true }),
            canCreateAccount: false
        )
    }

    func loginViaEmailOnPremView(email: String, backendConfig: BackendConfig) -> LoginViaEmailOnPremView {
        LoginViaEmailOnPremView(
            viewModel: loginViaEmailOnPremViewModel(email: email, backendConfig: backendConfig)
        )
    }
}

extension MockDependencies: LoginViaSSOBuilder {

    private func loginViewModel(ssoURL: URL) -> LoginViaSSOViewModel {
        LoginViaSSOViewModel(ssoURL: ssoURL)
    }

    func loginViaSSOView(ssoURL: URL) -> LoginViaSSOView {
        LoginViaSSOView(viewModel: loginViewModel(ssoURL: ssoURL))
    }

}

private struct MockPasswordValidator: PasswordValidator {

    let validationCallback: @Sendable (String) -> Bool

    init(validationCallback: @Sendable @escaping (String) -> Bool) {
        self.validationCallback = validationCallback
    }

    func isPasswordValid(_ password: String) -> Bool {
        validationCallback(password)
    }

    var localizedRulesDescription: String? {
        "Password rules"
    }

}

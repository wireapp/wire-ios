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
            websiteURL: URL(string: "https://example.com")!
        ),
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
        let viewModel = DetermineAuthMethodViewModel(
            router: rootViewModel,
            factory: self,
            emailOrSSOCode: emailOrSSOCode,
            isLoading: isLoading,
            alert: alert
        )

        return DetermineAuthMethodView(
            viewModel: viewModel,
            factory: self
        )
    }

}

extension MockDependencies: DetermineAuthMethodViewModel.Factory {

    nonisolated
    func resolveBackendMetadataUseCase() -> any WireAuthenticationAPI.ResolveBackendMetadataUseCaseProtocol {
        MockResolveBackendMetadataUseCase()
    }

    nonisolated
    func determineAuthMethodUseCase(apiVersion: BackendMetadata.APIVersion) -> any DetermineAuthMethodUseCaseProtocol {
        MockDetermineAuthMethodUseCase()
    }

    nonisolated
    func validateEmailOrSSOCodeUseCase() -> any ValidateEmailOrSSOCodeUseCaseProtocol {
        MockValidateEmailOrSSOCodeUseCase()
    }

    nonisolated
    func ssoLinkGenerator(apiVersion: BackendMetadata.APIVersion) -> any SSOLinkGeneratorProtocol {
        MockSSOLinkGenerator()
    }

    nonisolated
    func fetchBackendConfigUseCase() -> any FetchBackendConfigUseCaseProtocol {
        MockFetchBackendConfigUseCase()
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
            factory: self
        )
    }

    var determineAuthMethodView: DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: determineAuthMethodViewModel,
            factory: self
        )
    }

}

extension MockDependencies: SwitchBackendConfirmationBuilder {

    private func switchBackendConfirmationViewModel(
        email: String?,
        backendConfig: BackendConfig
    ) -> SwitchBackendConfirmationViewModel {
        SwitchBackendConfirmationViewModel(
            router: rootViewModel,
            factory: self,
            email: email,
            backendConfig: BackendConfig(
                title: backendConfig.title,
                endpoints: Endpoints(
                    backendURL: backendConfig.endpoints.backendURL,
                    backendWSURL: backendConfig.endpoints.backendWSURL,
                    blackListURL: backendConfig.endpoints.blackListURL,
                    teamsURL: backendConfig.endpoints.teamsURL,
                    accountsURL: backendConfig.endpoints.accountsURL,
                    websiteURL: backendConfig.endpoints.websiteURL
                ),
                proxySettings: nil,
                pinnedKeys: nil
            )
        )
    }

    func switchBackendView(
        email: String?,
        backendConfig: BackendConfig
    ) -> SwitchBackendConfirmationView {
        SwitchBackendConfirmationView(
            viewModel: switchBackendConfirmationViewModel(
                email: email,
                backendConfig: backendConfig
            )
        )
    }

}

extension MockDependencies: FetchSSOURLUseCaseFactory {

    nonisolated
    func fetchSSOURLUseCase(
        apiVersion: WireAuthenticationAPI.BackendMetadata.APIVersion
    ) -> any FetchSSOURLUseCaseProtocol {
        MockFetchSSOURLUseCase()
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

extension MockDependencies: LoginViaEmailBuilder {

    private func loginViewModel(
        email: String,
        canCreateAccount: Bool,
        backendMetadata: BackendMetadata
    ) -> LoginViaEmailViewModel {
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
        didDetectDomainConflict: Bool,
        backendMetadata: BackendMetadata
    ) -> LoginViaEmailView {
        LoginViaEmailView(
            viewModel: loginViewModel(
                email: email,
                canCreateAccount: canCreateAccount,
                backendMetadata: backendMetadata
            ),
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

    private func loginViaEmailOnPremViewModel(
        email: String,
        backendConfig: BackendConfig
    ) -> LoginViaEmailOnPremViewModel {
        LoginViaEmailOnPremViewModel(
            router: rootViewModel,
            factory: self,
            email: email,
            backendConfig: backendConfig,
            backendMetadata: nil,
            passwordValidator: MockPasswordValidator(validationCallback: { _ in true }),
            canCreateAccount: false
        )
    }

    func loginViaEmailOnPremView(
        email: String,
        backendConfig: BackendConfig,
        backendMetadata: BackendMetadata?
    ) -> LoginViaEmailOnPremView {
        LoginViaEmailOnPremView(
            viewModel: loginViaEmailOnPremViewModel(email: email, backendConfig: backendConfig)
        )
    }
}

extension MockDependencies: LoginViaEmailUseCaseFactory {

    nonisolated
    func loginViaEmailUseCase(apiVersion: BackendMetadata.APIVersion) -> any LoginViaEmailUseCaseProtocol {
        MockMockLoginViaEmailUseCase()
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

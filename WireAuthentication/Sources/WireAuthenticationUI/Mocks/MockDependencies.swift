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
        RootViewModel(
            factory: self,
            bridge: WireAuthenticationBridge(),
            backendInfo: backendInfo

        )
    }

    var backendInfo: BackendInfo {
        BackendInfo(
            environmentType: environmentType,
            backendConfig: backendConfig
        )
    }

    var environmentType: BackendEnvironmentType {
        .production
    }

    private var backendConfig: BackendConfig {
        _backendConfig
    }

    var backendMetadata: BackendMetadata {
        BackendMetadata(
            apiVersion: .v8,
            domain: "example.com",
            isFederationEnabled: true
        )
    }

    var backendEnvironment: WireAuthenticationBackendEnvironment {
        WireAuthenticationBackendEnvironment(
            environmentType: environmentType,
            config: backendConfig,
            metadata: backendMetadata,
            proxySettings: nil
        )
    }

    var _backendConfig = BackendConfig(
        title: "backen name",
        endpoints: Endpoints(
            backendURL: URL(string: "https://example.com")!,
            backendWSURL: URL(string: "https://example.com")!,
            blackListURL: URL(string: "https://example.com")!,
            teamsURL: URL(string: "https://example.com")!,
            accountsURL: URL(string: "https://example.com")!,
            websiteURL: URL(string: "https://example.com")!,
            countlyURL: URL(string: "https://example.com")!
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
        canExitFlow: Bool,
        isLoading: Bool,
        alert: Alert?
    ) -> DetermineAuthMethodView {
        let viewModel = DetermineAuthMethodViewModel(
            router: rootViewModel,
            factory: self,
            bridge: WireAuthenticationBridge(),
            backendInfo: backendInfo,
            emailOrSSOCode: emailOrSSOCode,
            canExitFlow: canExitFlow,
            isLoading: isLoading
        )
        viewModel.alert = alert

        return DetermineAuthMethodView(
            viewModel: viewModel,
            factory: self
        )
    }

}

extension MockDependencies: DetermineAuthMethodBuilder {

    private var determineAuthMethodViewModel: DetermineAuthMethodViewModel {
        DetermineAuthMethodViewModel(
            router: rootViewModel,
            factory: self,
            bridge: WireAuthenticationBridge(),
            backendInfo: backendInfo,
            canExitFlow: false
        )
    }

    func determineAuthMethodView(
        backendInfo: BackendInfo
    ) -> DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: determineAuthMethodViewModel,
            factory: self
        )
    }

    func determineAuthMethodView() -> DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: determineAuthMethodViewModel,
            factory: self
        )
    }

}

extension MockDependencies: NoHistoryViewBuilder {

    private var noHistoryViewModel: NoHistoryViewModel {
        NoHistoryViewModel(
            didDetectDomainConflict: false,
            howToChangeEmailURL: URL(string: "https://wire.com")!,
            howToDeleteAccountURL: URL(string: "https://wire.com")!,
            onFlowCompletion: {}
        )
    }

    func noHistoryView(authenticationResult: AuthenticationResult) -> NoHistoryView {
        NoHistoryView(viewModel: noHistoryViewModel)
    }

}

extension MockDependencies: LoginViaEmailBuilder {
    private func loginViewModel(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        backendInfo: BackendInfo
    ) -> LoginViaEmailViewModel {
        LoginViaEmailViewModel(
            router: rootViewModel,
            factory: self,
            email: email,
            backendInfo: backendInfo,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict,
            onCreateAccount: {}
        )
    }

    func loginViaEmailView(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        backendInfo: BackendInfo
    ) -> LoginViaEmailView {
        LoginViaEmailView(
            viewModel: loginViewModel(
                email: email,
                canCreateAccount: canCreateAccount,
                didDetectDomainConflict: didDetectDomainConflict,
                backendInfo: backendInfo
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
            factory: self,
            email: email,
            password: password,
            proxyCredentials: nil,
            router: rootViewModel,
            numberOfDigits: code.count
        )
        viewModel.code = code

        return VerificationCodeView(
            viewModel: viewModel,
            factory: self
        )
    }

    @MainActor
    func verificationCodeView(
        email: String,
        password: String,
        proxyCredentials: ProxyCredentials?
    ) -> VerificationCodeView {
        VerificationCodeView(
            viewModel: VerificationCodeViewModel(
                factory: self,
                email: "jane@doe.com",
                password: password,
                proxyCredentials: proxyCredentials,
                router: rootViewModel
            ),
            factory: self
        )
    }

}

extension MockDependencies: LoginViaSSOBuilder {

    private func loginViewModel(ssoURL: URL) -> LoginViaSSOViewModel {
        LoginViaSSOViewModel(
            factory: self,
            bridge: WireAuthenticationBridge(),
            ssoURL: ssoURL,
            onResult: { _ in }
        )
    }

    func loginViaSSOView(
        ssoURL: URL,
        backendInfo: BackendInfo?,
        onAuthenticationResult: @escaping (Result<AuthenticationResult, any Error>) -> Void
    ) -> LoginViaSSOView {
        LoginViaSSOView(viewModel: loginViewModel(ssoURL: ssoURL))
    }

}

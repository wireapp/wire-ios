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

import NeedleFoundation
import SwiftUI
import WireAPI
import WireReusableUIComponents
internal import WireAuthenticationUI
import WireAuthenticationAPI

class RootComponent: BootstrapComponent {

    public let environmentType: BackendEnvironmentType
    public let backendConfig: BackendConfig
    public let preferredAPIVersion: APIVersion?
    public let productionVersions: Set<APIVersion>
    public let minTLSVersion: TLSVersion
    public let accountsURL: URL
    public let howToChangeEmailURL: URL
    public let howToDeleteAccountURL: URL
    public let passwordValidator: any PasswordValidator
    public let ssoCallbackURLScheme: String
    public let userDefaults: UserDefaults
    public let onRegisterAccount: () -> Void
    let onFlowCompletion: (AuthenticationResult) -> Void

    init(
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        preferredAPIVersion: APIVersion?,
        minTLSVersion: TLSVersion,
        accountsURL: URL,
        howToChangeEmailURL: URL,
        howToDeleteAccountURL: URL,
        passwordValidator: any PasswordValidator,
        ssoCallbackURLScheme: String,
        userDefaults: UserDefaults,
        onRegisterAccount: @escaping () -> Void,
        onFlowCompletion: @escaping (AuthenticationResult) -> Void
    ) {
        self.environmentType = environmentType
        self.backendConfig = backendConfig
        self.preferredAPIVersion = preferredAPIVersion
        self.productionVersions = APIVersion.productionVersions
        self.minTLSVersion = minTLSVersion
        self.accountsURL = accountsURL
        self.howToChangeEmailURL = howToChangeEmailURL
        self.howToDeleteAccountURL = howToDeleteAccountURL
        self.passwordValidator = passwordValidator
        self.ssoCallbackURLScheme = ssoCallbackURLScheme
        self.userDefaults = userDefaults
        self.onRegisterAccount = onRegisterAccount
        self.onFlowCompletion = onFlowCompletion
    }

    // MARK: - View

    @MainActor var view: some View {
        RootView(
            viewModel: viewModel,
            factory: self
        )
    }

    @MainActor private var viewModel: RootViewModel {
        shared { RootViewModel() }
    }

    @MainActor public var bridge: WireAuthenticationBridge {
        shared {
            WireAuthenticationBridge(
                onFlowCompletion: onFlowCompletion,
                onRegisterAccount: onRegisterAccount
            )
        }
    }

    // MARK: - Public dependencies

    @MainActor public var router: any Router {
        viewModel
    }

    // MARK: - Children

    @MainActor
    var determineAuthMethodComponent: DetermineAuthMethodComponent {
        DetermineAuthMethodComponent(
            parent: self,
            router: router,
            environmentType: environmentType,
            backendConfig: backendConfig,
            preferredAPIVersion: preferredAPIVersion,
            productionVersions: productionVersions,
            minTLSVersion: minTLSVersion,
            ssoCallbackURLScheme: ssoCallbackURLScheme,
            userDefaults: userDefaults,
            bridge: bridge,
            passwordValidator: passwordValidator
        )
    }

    @MainActor
    func noHistoryComponent(
        authenticationResult: AuthenticationResult,
        didDetectDomainConflict: Bool
    ) -> NoHistoryComponent {
        NoHistoryComponent(
            parent: self,
            authenticationResult: authenticationResult,
            didDetectDomainConflict: didDetectDomainConflict,
            howToChangeEmailURL: howToChangeEmailURL,
            howToDeleteAccountURL: howToDeleteAccountURL,
            bridge: bridge
        )
    }

    @MainActor
    func loginViaEmailOnPremComponent(
        email: String,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        backendMetadata: WireAuthenticationAPI.BackendMetadata?
    ) -> LoginViaEmailOnPremComponent {
        LoginViaEmailOnPremComponent(
            parent: self,
            email: email,
            environmentType: environmentType,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata,
            router: router,
            minTLSVersion: minTLSVersion,
            passwordValidator: passwordValidator,
            bridge: bridge,
            preferredAPIVersion: preferredAPIVersion
        )
    }

    @MainActor
    func loginViaSSOComponent(
        ssoURL: URL,
        backendEnvironment: WireAuthenticationBackendEnvironment
    ) -> LoginViaSSOComponent {
        LoginViaSSOComponent(
            parent: self,
            ssoURL: ssoURL,
            backendEnvironment: backendEnvironment,
            router: router,
            bridge: bridge
        )
    }

}

extension RootComponent: RootView.Factory {

    @MainActor var determineAuthMethodView: DetermineAuthMethodView {
        determineAuthMethodComponent.view
    }

    @MainActor
    func noHistoryView(
        authenticationResult: AuthenticationResult,
        didDetectDomainConflict: Bool
    ) -> NoHistoryView {
        noHistoryComponent(
            authenticationResult: authenticationResult,
            didDetectDomainConflict: didDetectDomainConflict
        ).view
    }

    @MainActor
    func loginViaEmailOnPremView(
        email: String,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        backendMetadata: WireAuthenticationAPI.BackendMetadata?
    ) -> LoginViaEmailOnPremView {
        loginViaEmailOnPremComponent(
            email: email,
            environmentType: environmentType,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata
        ).view
    }

    func loginViaSSOView(
        ssoURL: URL,
        backendEnvironment: WireAuthenticationBackendEnvironment
    ) -> LoginViaSSOView {
        loginViaSSOComponent(
            ssoURL: ssoURL,
            backendEnvironment: backendEnvironment
        ).view
    }

}

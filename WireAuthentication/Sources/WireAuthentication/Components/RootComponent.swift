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
internal import WireAuthenticationLogic

class RootComponent: BootstrapComponent {

    public let environmentType: BackendEnvironmentType
    public let backendConfig: BackendConfig
    public let preferredAPIVersion: APIVersion?
    public let productionVersions: Set<APIVersion>
    public let minTLSVersion: TLSVersion
    public let howToChangeEmailURL: URL
    public let howToDeleteAccountURL: URL
    public let passwordValidator: any PasswordValidator
    public let ssoCallbackURLScheme: String
    public let userDefaults: UserDefaults
    public let appStoreURL: URL
    public let existsAnotherAccount: Bool

    init(
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        preferredAPIVersion: APIVersion?,
        minTLSVersion: TLSVersion,
        howToChangeEmailURL: URL,
        howToDeleteAccountURL: URL,
        passwordValidator: any PasswordValidator,
        ssoCallbackURLScheme: String,
        userDefaults: UserDefaults,
        appStoreURL: URL,
        existsAnotherAccount: Bool
    ) {
        self.environmentType = environmentType
        self.backendConfig = backendConfig
        self.preferredAPIVersion = preferredAPIVersion
        self.productionVersions = APIVersion.productionVersions
        self.minTLSVersion = minTLSVersion
        self.howToChangeEmailURL = howToChangeEmailURL
        self.howToDeleteAccountURL = howToDeleteAccountURL
        self.passwordValidator = passwordValidator
        self.ssoCallbackURLScheme = ssoCallbackURLScheme
        self.userDefaults = userDefaults
        self.appStoreURL = appStoreURL
        self.existsAnotherAccount = existsAnotherAccount
    }

    // MARK: - View

    @MainActor var view: some View {
        RootView(
            viewModel: viewModel,
            factory: self
        )
    }

    @MainActor private var viewModel: RootViewModel {
        shared {
            RootViewModel(bridge: bridge)
        }
    }

    @MainActor public var bridge: WireAuthenticationBridge {
        shared {
            WireAuthenticationBridge()
        }
    }

    // MARK: - Public dependencies

    @MainActor public var router: any Router {
        viewModel
    }

    // MARK: - Children

    func determineAuthMethodOnPremComponent(
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        backendMetadata: BackendMetadata?
    ) -> DetermineAuthMethodOnPremComponent {
        DetermineAuthMethodOnPremComponent(
            parent: self,
            environmentType: environmentType,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata
        )
    }

    var determineAuthMethodComponent: DetermineAuthMethodComponent {
        let networkStack = NetworkStack(
            environmentType: environmentType,
            backendConfig: backendConfig,
            minTLSVersion: minTLSVersion
        )

        return DetermineAuthMethodComponent(
            parent: self,
            networkStack: networkStack
        )
    }

    func loginViaEmailComponent(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        networkStack: NetworkStack
    ) -> LoginViaEmailComponent {
        LoginViaEmailComponent(
            parent: self,
            email: email,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict,
            networkStack: networkStack
        )
    }

}

extension RootComponent: RootView.Factory {

    @MainActor
    func determineAuthMethodView(
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        backendMetadata: WireAuthenticationAPI.BackendMetadata?
    ) -> DetermineAuthMethodView {
        determineAuthMethodOnPremComponent(
            environmentType: environmentType,
            backendConfig: backendConfig,
            backendMetadata: backendMetadata
        ).view
    }

    @MainActor
    func determineAuthMethodView() -> DetermineAuthMethodView {
        determineAuthMethodComponent.view
    }

    @MainActor
    func loginViaEmailView(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        environmentType: BackendEnvironmentType,
        backendConfig: BackendConfig,
        backendMetadata: BackendMetadata
    ) -> LoginViaEmailView {
        // TODO: fix
        fatalError()
    }

}

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
import WireAuthenticationAPI
import WireLogging
internal import WireAuthenticationUI
internal import WireAuthenticationLogic

protocol DetermineAuthMethodComponentDependency: Dependency {

    @MainActor var router: any Router { get }
    @MainActor var bridge: WireAuthenticationBridge { get }
    var preferredAPIVersion: APIVersion? { get }
    var minTLSVersion: TLSVersion { get }
    var ssoCallbackURLScheme: String { get }
    var userDefaults: UserDefaults { get }
    var existsAnotherAccount: Bool { get }

}

class DetermineAuthMethodComponent: Component<DetermineAuthMethodComponentDependency> {

    public let networkStack: NetworkStack

    init(
        parent: any Scope,
        networkStack: NetworkStack
    ) {
        self.networkStack = networkStack
        super.init(parent: parent)
    }

    @MainActor var view: DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: viewModel,
            factory: self
        )
    }

    @MainActor private var viewModel: DetermineAuthMethodViewModel {
        DetermineAuthMethodViewModel(
            router: dependency.router,
            factory: self,
            bridge: dependency.bridge,
            backendInfo: networkStack.backendInfo,
            canExitFlow: dependency.existsAnotherAccount
        )
    }

    // MARK: - Children

    func loginViaEmailComponent(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        backendInfo: BackendInfo
    ) -> LoginViaEmailComponent {
        let networkStack = NetworkStack(
            backendInfo: backendInfo,
            minTLSVersion: dependency.minTLSVersion,
            preferredAPIVersion: dependency.preferredAPIVersion
        )
        return LoginViaEmailComponent(
            parent: self,
            email: email,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict,
            networkStack: networkStack
        )
    }

    func loginViaSSOComponent(
        ssoURL: URL,
        backendInfo: BackendInfo?,
        onAuthenticationResult: @escaping (Result<AuthenticationResult, any Error>) -> Void
    ) -> LoginViaSSOComponent {
        let networkStack: NetworkStack = if let backendInfo {
            NetworkStack(
                backendInfo: backendInfo,
                minTLSVersion: dependency.minTLSVersion,
                preferredAPIVersion: dependency.preferredAPIVersion
            )
        } else {
            self.networkStack
        }

        return LoginViaSSOComponent(
            parent: self,
            ssoURL: ssoURL,
            networkStack: networkStack,
            onAuthenticationResult: onAuthenticationResult
        )
    }

    func noHistoryComponent(authenticationResult: AuthenticationResult) -> NoHistoryComponent {
        NoHistoryComponent(
            parent: self,
            authenticationResult: authenticationResult,
            didDetectDomainConflict: false
        )
    }

}

extension DetermineAuthMethodComponent: DetermineAuthMethodViewModel.Factory {

    func validateEmailOrSSOCodeUseCase() -> any ValidateEmailOrSSOCodeUseCaseProtocol {
        ValidateEmailOrSSOCodeUseCase()
    }

    func determineAuthMethodUseCase() async throws -> any DetermineAuthMethodUseCaseProtocol {
        let authenticationAPI = try await networkStack.makeAuthenticationAPI()
        return DetermineAuthMethodUseCase(
            validateEmailOrSSOCode: validateEmailOrSSOCodeUseCase(),
            authenticationAPI: authenticationAPI,
            urlSession: URLSession.shared
        )
    }

    func ssoLinkGenerator() async throws -> any SSOLinkGeneratorProtocol {
        let authenticationAPI = try await networkStack.makeAuthenticationAPI()
        return SSOLinkGenerator(
            authenticationAPI: authenticationAPI,
            baseURL: networkStack.backendInfo.backendConfig.endpoints.backendURL,
            callbackScheme: dependency.ssoCallbackURLScheme,
            defaults: dependency.userDefaults
        )
    }

    func fetchBackendConfigUseCase() -> any FetchBackendConfigUseCaseProtocol {
        FetchBackendConfigUseCase()
    }

    func fetchSSOURLUseCase(
        backendInfo: BackendInfo
    ) async throws -> any FetchSSOURLUseCaseProtocol {
        let networkStack = NetworkStack(
            backendInfo: backendInfo,
            minTLSVersion: dependency.minTLSVersion,
            preferredAPIVersion: dependency.preferredAPIVersion
        )
        let authenticationAPI = try await networkStack.makeAuthenticationAPI()
        let linkGenerator = SSOLinkGenerator(
            authenticationAPI: authenticationAPI,
            baseURL: backendInfo.backendConfig.endpoints.backendURL,
            callbackScheme: dependency.ssoCallbackURLScheme,
            defaults: dependency.userDefaults
        )
        return FetchSSOURLUseCase(
            authenticationAPI: authenticationAPI,
            linkGenerator: linkGenerator
        )
    }

}

extension DetermineAuthMethodComponent: DetermineAuthMethodView.Factory {

    @MainActor
    func loginViaEmailView(
        email: String?,
        canCreateAccount: Bool,
        didDetectDomainConflict: Bool,
        backendInfo: BackendInfo
    ) -> LoginViaEmailView {
        loginViaEmailComponent(
            email: email,
            canCreateAccount: canCreateAccount,
            didDetectDomainConflict: didDetectDomainConflict,
            backendInfo: backendInfo
        ).view
    }

    @MainActor
    func loginViaSSOView(
        ssoURL: URL,
        backendInfo: BackendInfo?,
        onAuthenticationResult: @escaping (Result<AuthenticationResult, any Error>) -> Void
    ) -> LoginViaSSOView {
        loginViaSSOComponent(
            ssoURL: ssoURL,
            backendInfo: backendInfo,
            onAuthenticationResult: onAuthenticationResult
        ).view
    }

    func noHistoryView(authenticationResult: AuthenticationResult) -> NoHistoryView {
        noHistoryComponent(authenticationResult: authenticationResult).view
    }

}

// TODO: [WPB-16272] remove when API version is deduplicated.
extension WireAPI.APIVersion {

    init(_ apiVersion: WireAuthenticationAPI.BackendMetadata.APIVersion) {
        switch apiVersion {
        case .v0:
            self = .v0
        case .v1:
            self = .v1
        case .v2:
            self = .v2
        case .v3:
            self = .v3
        case .v4:
            self = .v4
        case .v5:
            self = .v5
        case .v6:
            self = .v6
        case .v7:
            self = .v7
        case .v8:
            self = .v8
        }
    }

}

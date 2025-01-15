//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import NeedleFoundation
import SwiftUI
import WireAPI
import WireAuthenticationAPI
internal import WireAuthenticationUI
internal import WireAuthenticationCore

public struct WireAuthenticationAssembly {

    public init() {
        registerProviderFactories()
    }

    @MainActor
    public func assemble(
        backendURL: URL,
        minTLSVersion: TLSVersion,
        apiVersion: APIVersion
    ) -> some View {
        let root = RootComponent(
            backendURL: backendURL,
            minTLSVersion: minTLSVersion,
            apiVersion: apiVersion
        )
        return root.rootView
    }

}

class RootComponent: BootstrapComponent {

    let backendURL: URL
    let minTLSVersion: TLSVersion
    public let apiVersion: APIVersion

    public init(
        backendURL: URL,
        minTLSVersion: TLSVersion,
        apiVersion: APIVersion
    ) {
        self.backendURL = backendURL
        self.minTLSVersion = minTLSVersion
        self.apiVersion = apiVersion
    }

    var serverTrustValidator: ServerTrustValidator {
        shared {
            ServerTrustValidator(pinnedKeys: [])
        }
    }

    var urlSessionConfigurationFactory: URLSessionConfigurationFactory {
        shared {
            URLSessionConfigurationFactory(
                minTLSVersion: minTLSVersion,
                proxySettings: nil
            )
        }
    }

    public var networkService: NetworkService {
        shared {
            let service = NetworkService(
                baseURL: backendURL,
                serverTrustValidator: serverTrustValidator
            )
            let config = urlSessionConfigurationFactory.makeRESTAPISessionConfiguration()
            let session = URLSession(configuration: config, delegate: service, delegateQueue: nil)
            service.configure(with: session)
            return service
        }
    }

    public var router: Router {
        shared {
            Router()
        }
    }

    @MainActor
    var rootView: some View {
        RootView(
            router: router,
            builder: landingComponent
        )
    }

    // Children

    var landingComponent: LandingComponent {
        LandingComponent(parent: self)
    }

}

protocol LandingComponentDependency: Dependency {

    var router: Router { get }

}

class LandingComponent: Component<LandingComponentDependency>, LandingBuilder {

    var determineAuthenticationMethodUseCase: some DetermineAuthenticationMethodUseCaseProtocol {
        DetermineAuthenticationMethodUseCase()
    }

    @MainActor
    var viewModel: DetermineAuthMethodViewModel {
        .init(
            router: dependency.router,
            determineAuthenticationMethod: determineAuthenticationMethodUseCase
        )
    }

    @MainActor
    var landingView: DetermineAuthMethodView {
        DetermineAuthMethodView(
            viewModel: viewModel,
            builder: loginViaEmailComponent
        )
    }

    // Children

    var loginViaEmailComponent: LoginViaEmailComponent {
        LoginViaEmailComponent(parent: self)
    }

}

protocol LoginViaEmailComponentDependency: Dependency {

    var router: Router { get }
    var networkService: NetworkService { get }
    var apiVersion: APIVersion { get }

}

class LoginViaEmailComponent: Component<LoginViaEmailComponentDependency>, LoginViaEmailBuilder {

    var loginAPIBuilder: LoginAPIBuilder {
        shared {
            .init(networkService: dependency.networkService)
        }
    }

    var loginAPI: some LoginAPI {
        loginAPIBuilder.makeAPI(for: dependency.apiVersion)
    }

    var loginViaEmailUseCase: some LoginViaEmailUseCaseProtocol {
        LoginViaEmailUseCase(loginAPI: loginAPI)
    }

    @MainActor
    func loginViewModel(email: String) -> LoginViaEmailViewModel {
        LoginViaEmailViewModel(
            router: dependency.router,
            loginViaEmailUseCase: loginViaEmailUseCase,
            email: email,
            isRegistrationAllowed: false
        )
    }

    @MainActor
    func loginViaEmailView(email: String) -> LoginViaEmailView {
        LoginViaEmailView(
            viewModel: loginViewModel(email: email),
            builder: verifyEmailComponent
        )
    }

    // Children

    var verifyEmailComponent: VerifyEmailComponent {
        VerifyEmailComponent(parent: self)
    }

}

protocol VerifyEmailComponentDependency: Dependency {

    var router: Router { get }

}

class VerifyEmailComponent: Component<VerifyEmailComponentDependency>, VerifyEmailBuilder {

    var submitCodeUseCase: SubmitTwoFactorAuthenticationCodeUseCaseProtocol {
        SubmitTwoFactorAuthenticationCodeUseCase()
    }

    @MainActor
    var verifyEmailViewModel: TwoFactorAuthenticationViewModel {
        TwoFactorAuthenticationViewModel(
            router: dependency.router,
            submitCode: submitCodeUseCase
        )
    }

    @MainActor
    var verifyEmailView: TwoFactorAuthenticationView {
        TwoFactorAuthenticationView(viewModel: verifyEmailViewModel)
    }

}

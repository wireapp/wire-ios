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

import Combine
import NeedleFoundation
import SwiftUI
import WireNetwork
import WireReusableUIComponents
internal import WireAuthenticationUI
import WireAuthenticationAPI
import WireMultiBackendUI
internal import WireAuthenticationLogic
import WireFoundation

final class RootComponent: BootstrapComponent {

    public let environment: BackendEnvironment2
    public let preferredAPIVersion: APIVersion?
    public let productionVersions: Set<APIVersion>
    public let minTLSVersion: TLSVersion
    public let howToChangeEmailURL: URL
    public let howToDeleteAccountURL: URL
    public let privacyPolicyURL: URL
    public let termsOfUseURL: URL
    public let passwordValidator: any PasswordValidator
    public let ssoCallbackURLScheme: String
    public let appStoreURL: URL
    public let accountsPublisher: CurrentValuePublisher<[AccountUIModel]>
    public let registrationAnalyticsTracker: (any RegistrationAnalyticsTrackerProtocol)?

    @MainActor public var bridge: WireAuthenticationBridge {
        shared {
            WireAuthenticationBridge()
        }
    }

    @MainActor public var router: any Router {
        viewModel
    }

    private let authenticationType: AuthenticationType

    init(
        authenticationType: AuthenticationType,
        environment: BackendEnvironment2,
        preferredAPIVersion: APIVersion?,
        minTLSVersion: TLSVersion,
        howToChangeEmailURL: URL,
        howToDeleteAccountURL: URL,
        privacyPolicyURL: URL,
        termsOfUseURL: URL,
        passwordValidator: any PasswordValidator,
        ssoCallbackURLScheme: String,
        appStoreURL: URL,
        accountsPublisher: CurrentValuePublisher<[AccountUIModel]>,
        registrationAnalyticsTracker: (any RegistrationAnalyticsTrackerProtocol)?
    ) {
        self.authenticationType = authenticationType
        self.environment = environment
        self.preferredAPIVersion = preferredAPIVersion
        self.productionVersions = APIVersion.productionVersions
        self.minTLSVersion = minTLSVersion
        self.howToChangeEmailURL = howToChangeEmailURL
        self.howToDeleteAccountURL = howToDeleteAccountURL
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfUseURL = termsOfUseURL
        self.passwordValidator = passwordValidator
        self.ssoCallbackURLScheme = ssoCallbackURLScheme
        self.appStoreURL = appStoreURL
        self.accountsPublisher = accountsPublisher
        self.registrationAnalyticsTracker = registrationAnalyticsTracker
    }

    // MARK: - Children

    func determineAuthMethodComponent(environment: BackendEnvironment2) -> DetermineAuthMethodComponent {
        let networkStack = NetworkStack(
            backendEnvironment: environment,
            minTLSVersion: minTLSVersion,
            preferredAPIVersion: preferredAPIVersion,
            proxyCredentials: nil
        )

        return DetermineAuthMethodComponent(
            parent: self,
            networkStack: networkStack,
            existsAnotherAccount: !accountsPublisher.value.isEmpty
        )
    }

}

extension RootComponent: RootViewModel.Factory {

    // MARK: - Factory

    @MainActor var viewModel: RootViewModel {
        shared {
            RootViewModel(
                factory: self,
                bridge: bridge,
                environment: environment,
                authenticationType: authenticationType,
                hasOtherAccountsProvider: { [accountsPublisher] in
                    !accountsPublisher.value.isEmpty
                }
            )
        }
    }

    func determineAuthMethodFactory(environment: BackendEnvironment2) -> any DetermineAuthMethodFactory {
        determineAuthMethodComponent(environment: environment)
    }

    func reloginViaEmailFactory(email: String) -> any ReloginViaEmailFactory {
        let networkStack = NetworkStack(
            backendEnvironment: environment,
            minTLSVersion: minTLSVersion,
            preferredAPIVersion: preferredAPIVersion,
            proxyCredentials: nil
        )

        return ReloginViaEmailComponent(
            parent: self,
            email: email,
            networkStack: networkStack,
            existsAnotherAccount: !accountsPublisher.value.isEmpty
        )
    }

    func reloginViaSSOFactory() -> any ReloginViaSSOFactory {
        let networkStack = NetworkStack(
            backendEnvironment: environment,
            minTLSVersion: minTLSVersion,
            preferredAPIVersion: preferredAPIVersion,
            proxyCredentials: nil
        )

        return ReloginViaSSOComponent(
            parent: self,
            networkStack: networkStack,
            existsAnotherAccount: !accountsPublisher.value.isEmpty
        )
    }

    func accountsSwitcherFactory() -> any AccountSwitcherFactory {
        AccountSwitcherComponent(parent: self)
    }

    // MARK: - Use cases

    func openAppStoreUseCase() -> any OpenAppStoreUseCaseProtocol {
        OpenAppStoreUseCase(url: appStoreURL)
    }

}

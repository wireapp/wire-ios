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
import Combine
import WireAPI
import WireReusableUIComponents
internal import WireAuthenticationUI
import WireAuthenticationAPI
import WireMultiBackendUI
internal import WireAuthenticationLogic
import WireFoundation

class RootComponent: BootstrapComponent {

    public let backendInfo: BackendInfo
    public let preferredAPIVersion: APIVersion?
    public let productionVersions: Set<APIVersion>
    public let minTLSVersion: TLSVersion
    public let howToChangeEmailURL: URL
    public let howToDeleteAccountURL: URL
    public let passwordValidator: any PasswordValidator
    public let ssoCallbackURLScheme: String
    public let appStoreURL: URL
    public let existsAnotherAccount: Bool
    public var otherAccountsPublisher: ReadOnlyCurrentValueSubject<[AccountUIModel]>
    public let useLegacyRegistrationFlow: Bool

    @MainActor public var bridge: WireAuthenticationBridge {
        shared {
            WireAuthenticationBridge()
        }
    }

    @MainActor public var router: any Router {
        viewModel
    }

    init(
        backendInfo: BackendInfo,
        preferredAPIVersion: APIVersion?,
        minTLSVersion: TLSVersion,
        howToChangeEmailURL: URL,
        howToDeleteAccountURL: URL,
        passwordValidator: any PasswordValidator,
        ssoCallbackURLScheme: String,
        appStoreURL: URL,
        existsAnotherAccount: Bool,
        otherAccountsPublisher: ReadOnlyCurrentValueSubject<[AccountUIModel]>,
        useLegacyRegistrationFlow: Bool
    ) {
        self.backendInfo = backendInfo
        self.preferredAPIVersion = preferredAPIVersion
        self.productionVersions = APIVersion.productionVersions
        self.minTLSVersion = minTLSVersion
        self.howToChangeEmailURL = howToChangeEmailURL
        self.howToDeleteAccountURL = howToDeleteAccountURL
        self.passwordValidator = passwordValidator
        self.ssoCallbackURLScheme = ssoCallbackURLScheme
        self.appStoreURL = appStoreURL
        self.existsAnotherAccount = existsAnotherAccount
        self.otherAccountsPublisher = otherAccountsPublisher
        self.useLegacyRegistrationFlow = useLegacyRegistrationFlow
    }

    // MARK: - Children

    func determineAuthMethodComponent(backendInfo: BackendInfo) -> DetermineAuthMethodComponent {
        let networkStack = NetworkStack(
            backendInfo: backendInfo,
            minTLSVersion: minTLSVersion,
            preferredAPIVersion: preferredAPIVersion
        )

        return DetermineAuthMethodComponent(
            parent: self,
            networkStack: networkStack
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
                backendInfo: backendInfo
            )
        }
    }

    func determineAuthMethodFactory(backendInfo: BackendInfo) -> any DetermineAuthMethodFactory {
        determineAuthMethodComponent(backendInfo: backendInfo)
    }
    
    func accountsSwitcherFactory() -> any AccountSwitcherFactory {
        accountSwitcherComponent()
    }
    
    func accountSwitcherComponent() -> AccountSwitcherComponent {
        AccountSwitcherComponent(parent: self)
    }

    // MARK: - Use cases

    func openAppStoreUseCase() -> any OpenAppStoreUseCaseProtocol {
        OpenAppStoreUseCase(url: appStoreURL)
    }

}

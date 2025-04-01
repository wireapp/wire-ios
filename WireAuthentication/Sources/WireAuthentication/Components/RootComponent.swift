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

class RootComponent: BootstrapComponent, RootFactory {


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

    init(
        backendInfo: BackendInfo,
        preferredAPIVersion: APIVersion?,
        minTLSVersion: TLSVersion,
        howToChangeEmailURL: URL,
        howToDeleteAccountURL: URL,
        passwordValidator: any PasswordValidator,
        ssoCallbackURLScheme: String,
        appStoreURL: URL,
        existsAnotherAccount: Bool
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
    }

    // MARK: - View

//    @MainActor var view: some View {
//        RootView(
//            viewModel: viewModel,
//            factory: self
//        )
//    }

    @MainActor var viewModel: RootViewModel {
        let viewModel = RootViewModel(
            factory: self,
            bridge: bridge,
            backendInfo: backendInfo
        )
        viewModel.componentFactory = self
        
        return viewModel
    }

    // MARK: - Public dependencies

    @MainActor public var bridge: WireAuthenticationBridge {
        shared {
            WireAuthenticationBridge()
        }
    }

    @MainActor public var router: any Router {
        viewModel
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
    
    func determineAuthMethodFactory(backendInfo: WireAuthenticationAPI.BackendInfo) -> any WireAuthenticationUI.DetermineAuthMethodFactory {
        determineAuthMethodComponent(backendInfo: backendInfo)
    }
    

}

extension RootComponent: RootViewModel.Factory {

    func openAppStoreUseCase() -> any OpenAppStoreUseCaseProtocol {
        OpenAppStoreUseCase(url: appStoreURL)
    }

}
//
//extension RootComponent: RootView.Factory {
//
//    @MainActor
//    func determineAuthMethodView(backendInfo: BackendInfo) -> DetermineAuthMethodView {
//        determineAuthMethodComponent(backendInfo: backendInfo).view
//    }
//
//}

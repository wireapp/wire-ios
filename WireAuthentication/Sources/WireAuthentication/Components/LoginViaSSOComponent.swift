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
import NeedleFoundation
import WireAuthenticationAPI
internal import WireAuthenticationUI

protocol LoginViaSSODependency: Dependency {

    // FIXME: Adjust as necessary
//    @MainActor var router: any Router { get }
//    @MainActor var bridge: WireAuthenticationBridge { get }

}

class LoginViaSSOComponent: Component<LoginViaSSODependency> {

    private let ssoURL: URL
    private let backendEnvironment: WireAuthenticationBackendEnvironment
    private let router: any Router
    private let bridge: WireAuthenticationBridge

    init(
        parent: any Scope,
        ssoURL: URL,
        backendEnvironment: WireAuthenticationBackendEnvironment,
        router: any Router,
        bridge: WireAuthenticationBridge
    ) {
        self.ssoURL = ssoURL
        self.backendEnvironment = backendEnvironment
        self.router = router
        self.bridge = bridge

        super.init(parent: parent)
    }

    // MARK: - View

    @MainActor var view: LoginViaSSOView {
        LoginViaSSOView(viewModel: viewModel)
    }

    @MainActor private var viewModel: LoginViaSSOViewModel {
        bridge.onSSOSuccess = { [router, backendEnvironment] userID, cookies in
            let authenticationResult = AuthenticationResult(
                userID: userID,
                cookies: cookies,
                accessToken: nil,
                emailCredentials: nil,
                backendEnvironment: backendEnvironment
            )

            router.presentSheet(
                RootView.ModalDestination.noHistory(
                    authenticationResult: authenticationResult,
                    didDetectDomainConflict: false
                )
            )
        }

        bridge.onSSOFailure = { [router] in
            router.presentAlert(RootViewModel.Alert.ssoLoginFailed)
        }

        return LoginViaSSOViewModel(ssoURL: ssoURL)
    }

}

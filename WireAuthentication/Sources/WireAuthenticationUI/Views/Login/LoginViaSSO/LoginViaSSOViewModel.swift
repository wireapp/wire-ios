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
import Foundation
import SwiftUI
import WireAuthenticationAPI

@MainActor
package final class LoginViaSSOViewModel: ObservableObject {

    let ssoURL: URL
    private let bridge: WireAuthenticationBridge
    private let router: any Router
    private let backendEnvironment: WireAuthenticationBackendEnvironment
    private var cancellable: AnyCancellable?

    package init(
        ssoURL: URL,
        bridge: WireAuthenticationBridge,
        router: any Router,
        backendEnvironment: WireAuthenticationBackendEnvironment
    ) {
        self.ssoURL = ssoURL
        self.bridge = bridge
        self.router = router
        self.backendEnvironment = backendEnvironment

        cancellable = bridge.inboundEvents.sink { event in
            switch event {
            case let .ssoAuthenticationSuccess(userID, cookies):
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
            case .ssoAutheticationFailure:
                router.presentAlert(RootViewModel.Alert.ssoLoginFailed)
            }
        }
    }

}

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
import WireAuthentication
import WireLogging
import WireSyncEngine

// A temporary bridging object to allow the new WireAuthentication flow inside
// the existing AuthenticationController flow.
final class AuthenticationHostingController<Content: View>: UIHostingController<Content>,
    AuthenticationCoordinatedViewController {

    var authenticationCoordinator: AuthenticationCoordinator?
    private var cancellable: AnyCancellable?

    init(
        rootView: Content,
        bridge: WireAuthenticationBridge,
        authenticationCoordinator: AuthenticationCoordinator?
    ) {
        self.authenticationCoordinator = authenticationCoordinator
        super.init(rootView: rootView)

        self.cancellable = bridge.outboundEvents.sink { event in
            switch event {
            case let .userAuthenticated(authenticationResult):
                authenticationCoordinator?.eventResponderChain.handleEvent(
                    ofType: .wireAuthenticationModuleComplete(authenticationResult)
                )

<<<<<<< HEAD
            case .accountRegistrationRequested:
                // TODO: [WPB-16279] Navigate to the account registration flow
                break
=======
            case let .accountRegistrationRequested(
                email,
                backendEnvironment
            ):
                authenticationCoordinator?.wireAuthenticationDidRequestAccountRegistration(
                    email: email,
                    backendEnvironment: backendEnvironment
                )

            case .exitFlowRequested:
                guard
                    let sessionManager = SessionManager.shared,
                    let account = sessionManager.firstAuthenticatedAccount
                else {
                    WireLogger.authentication.error("WireAuthentication requested exit but no account to go back to")
                    return
                }

                sessionManager.select(account)
>>>>>>> cf871dddd6 (fix: can't exit authentication flow - WPB-16562 (#2692))
            }
        }

        authenticationCoordinator?.unauthenticatedSession.appendURLActionProcessors(action: { userID, cookies in
            bridge.sendInboundEvent(.ssoAuthenticationSuccess(userID: userID, cookies: cookies))
        })

        authenticationCoordinator?.unauthenticatedSession.setErrorHandler {
            bridge.sendInboundEvent(.ssoAutheticationFailure)
        }
    }

    @available(*, unavailable)
    @MainActor @preconcurrency
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func executeErrorFeedbackAction(_ feedbackAction: AuthenticationErrorFeedbackAction) {
        // no op
    }

    func displayError(_ error: any Error) {
        // no op
    }

}

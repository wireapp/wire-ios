//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireDomain
import WireLogging
import WireSyncEngine

// A temporary bridging object to allow the new WireAuthentication flow inside
// the existing AuthenticationController flow.
final class AuthenticationHostingController<Content: View>: UIHostingController<Content>,
    AuthenticationCoordinatedViewController {

    weak var authenticationCoordinator: AuthenticationCoordinator?
    private let bridge: WireAuthenticationBridge
    private var cancellables = Set<AnyCancellable>()

    init(
        rootView: Content,
        bridge: WireAuthenticationBridge,
        authenticationCoordinator: AuthenticationCoordinator?
    ) {
        self.authenticationCoordinator = authenticationCoordinator
        self.bridge = bridge
        super.init(rootView: rootView)

        bridge.outboundEvents.sink { [weak authenticationCoordinator, weak self] event in
            switch event {
            case let .userAuthenticated(context):
                authenticationCoordinator?.eventResponderChain.handleEvent(
                    ofType: .wireAuthenticationModuleComplete(context)
                )
            case .exitFlowRequested:
                self?.selectAccount()
            case let .logoutRequested(deleteData):
                authenticationCoordinator?.eventResponderChain.handleEvent(
                    ofType: .logoutRequested(deleteData: deleteData)
                )
            }
        }
        .store(in: &cancellables)

        authenticationCoordinator?.unauthenticatedSession.appendURLActionProcessors(
            handleBackendSwitch: { url in
                bridge.sendInboundEvent(.backendSwitchRequested(configURL: url))
            }
        )

        NotificationCenter.default
            .publisher(for: AccountManagerDidUpdateAccountsNotificationName)
            .compactMap { $0.object as? AccountManager }
            .sink { accountManager in
                let numberOfAccounts = accountManager.numberOfAccounts
                bridge.sendInboundEvent(.updateAnotherAccountExistence(newValue: numberOfAccounts > 0))

            }
            .store(in: &cancellables)
    }

    private func selectAccount(completion: (() -> Void)? = nil) {
        guard
            let sessionManager = SessionManager.shared,
            let account = sessionManager.firstAuthenticatedAccount
        else {
            WireLogger.authentication.error("WireAuthentication requested exit but no account to go back to")
            return
        }

        Task {
            _ = await sessionManager.select(account)
            completion?()
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

    func didRewindToThisView() {
        bridge.sendInboundEvent(.didRewindToThisView)
    }

}

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

import Foundation
import WireAuthenticationAPI
import WireLogging
import WireNetwork

@MainActor
package final class ReloginViaSSOViewModel: ObservableObject {

    package typealias Factory =
        LoginViaSSOUseCaseFactory &
        ReloginViaSSOFactory &
        ValidateSSOCodeUseCaseFactory

    // MARK: - View state

    @Published var rawSSOCode = ""
    @Published var isSSOCodeRequired = false
    @Published var existsAnotherAccount: Bool

    var isOnPremiseBackend: Bool {
        environment.environmentType != .default
    }

    let environment: BackendEnvironment2

    // MARK: - Dependencies

    package let factory: any Factory
    private let router: any Router
    private let bridge: WireAuthenticationBridge

    // MARK: - Life cycle

    package init(
        factory: any Factory,
        router: any Router,
        bridge: WireAuthenticationBridge,
        environment: BackendEnvironment2,
        existsAnotherAccount: Bool
    ) {
        self.factory = factory
        self.router = router
        self.bridge = bridge
        self.environment = environment
        self.existsAnotherAccount = existsAnotherAccount
    }

    // MARK: - Actions

    func login() async {

        do {
            var code: UUID?

            if isSSOCodeRequired {
                let validateSSOCode = factory.validateSSOCodeUseCase()
                code = try validateSSOCode.invoke(ssoCode: rawSSOCode)
            }

            let loginViaSSO = try await factory.loginViaSSOUseCase(environment: environment)
            let authResult = try await loginViaSSO.invoke(code: code)
            router.navigate(to: ReloginViaSSODestination.noHistory(authResult))
        } catch LoginViaSSOUseCaseError.userCancelled {
            // No op
        } catch LoginViaSSOUseCaseError.noDefaultCodeAvailable {
            isSSOCodeRequired = true
        } catch LoginViaSSOUseCaseError.invalidCode, ValidateSSOCodeFailure.invalidCode {
            router.presentAlert(.incorrectSSOCode)
        } catch LoginViaSSOUseCaseError.invalidURL {
            router.presentAlert(.invalidSSOLink)
        } catch let LoginViaSSOUseCaseError.authenticationFailed(error) {
            WireLogger.authentication.error("sso failed: \(String(describing: error))")
            router.presentAlert(.ssoLoginFailed)
        } catch {
            router.presentAlert(for: error)
        }
    }

    func logout() {
        router.presentAlert(.logoutConfirmation)
    }

    func exitFlow() {
        bridge.sendOutboundEvent(.exitFlowRequested)
    }

}

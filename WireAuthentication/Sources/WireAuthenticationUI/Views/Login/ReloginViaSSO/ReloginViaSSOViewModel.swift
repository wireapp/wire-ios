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
import WireAuthenticationAPI
import WireLogging
import WireNetwork

@MainActor
package final class ReloginViaSSOViewModel: ObservableObject {
    
    package typealias Factory =
    ReloginViaSSOFactory &
    LoginViaSSOUseCaseFactory
    
    // MARK: - View state

    @Published var rawSSOCode = ""
    @Published var isSSOCodeRequired = false

    var isOnPremiseBackend: Bool {
        environment.environmentType != .default
    }
    
    let environment: BackendEnvironment2
    
    // MARK: - Dependencies
    
    package let factory: any Factory
    private let router: any Router
    
    // MARK: - Life cycle
    
    package init(
        factory: any Factory,
        router: any Router,
        environment: BackendEnvironment2
    ) {
        self.factory = factory
        self.router = router
        self.environment = environment
    }
    
    // MARK: - Actions
    
    func login() async {
        var code: UUID?
        if isSSOCodeRequired {
            guard let ssoCode = UUID(uuidString: rawSSOCode) else {
                router.presentAlert(.incorrectSSOCode)
                return
            }
            code = ssoCode
        }

        do {
            let loginViaSSO = try await factory.loginViaSSOUseCase(environment: environment)
            let authResult = try await loginViaSSO.invoke(code: code)
            router.navigate(to: ReloginViaSSODestination.noHistory(authResult))
        } catch LoginViaSSOUseCaseError.userCancelled {
            // No op
        } catch LoginViaSSOUseCaseError.noDefaultCodeAvailable {
            isSSOCodeRequired = true
        } catch LoginViaSSOUseCaseError.invalidCode {
            router.presentAlert(.incorrectSSOCode)
        } catch LoginViaSSOUseCaseError.invalidURL {
            router.presentAlert(.invalidSSOLink)
        } catch let LoginViaSSOUseCaseError .authenticationFailed(error) {
            WireLogger.authentication.error("sso failed: \(String(describing: error))")
            router.presentAlert(.ssoLoginFailed)
        } catch {
            router.presentAlert(for: error)
        }
    }

}

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

package struct SSOSuccessHandler {

    private let router: any Router

    package init(router: Router) {
        self.router = router
    }

    @MainActor
    package func handleSuccess(userID: UUID, cookies: [HTTPCookie]) {
        router.presentSheet(
            RootView.ModalDestination.noHistory(
                userID: userID,
                cookies: cookies,
                accessToken: nil,
                didDetectDomainConflict: false
            )
        )
    }

}

package struct BackendSwitchHandler {

    package typealias Factory = FetchBackendConfigUseCaseFactory

    private let router: any Router
    //private let factory: any Factory
    private let useCase: FetchBackendConfigUseCaseProtocol

    package init(router: Router, useCase: FetchBackendConfigUseCaseProtocol /*factory: any Factory*/) {
        self.router = router
        self.useCase = useCase
    }

    @MainActor
    package func handleSuccess(backendConfigURL: URL) async {
        do {
            //let useCase = factory.fetchBackendConfigUseCase()
            let backendConfig = try await Task.detached {
                try await useCase.invoke(at: backendConfigURL)
            }.value
            router.presentSheet(RootView.ModalDestination.switchBackend(backendConfig: backendConfig))
        } catch {
            WireLogger.authentication.error("Unexpected error while fetching backend config: \(error)")
        }
    }

}

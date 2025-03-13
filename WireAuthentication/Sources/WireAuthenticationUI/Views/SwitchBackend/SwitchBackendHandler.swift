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

package struct SwitchBackendHandler {

    package typealias Factory = FetchBackendConfigUseCaseFactory

    private let router: any Router
    private let factory: any Factory

    package init(router: Router, factory: any Factory) {
        self.router = router
        self.factory = factory
    }

    @MainActor
    package func invoke(_ backendConfigURL: URL) async {
        do {
            let useCase = factory.fetchBackendConfigUseCase()
            let backendConfig = try await Task.detached {
                try await useCase.invoke(at: backendConfigURL)
            }.value
            router.presentSheet(RootView.ModalDestination.switchBackend(backendConfig: backendConfig))
        } catch {
            WireLogger.authentication.error("Unexpected error while fetching backend config: \(error)")
        }
    }

}

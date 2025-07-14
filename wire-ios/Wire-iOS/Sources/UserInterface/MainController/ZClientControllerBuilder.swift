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

import WireCellsAPI
import WireCellsBindings
import WireDataModel
import WireNetwork
@preconcurrency import WireSyncEngine
import WireTransport

struct ZClientControllerBuilder {

    private(set) var account: Account
    private(set) var userSession: UserSession
    private(set) var trackingManager: TrackingManager?
    let environment: WireTransport.BackendEnvironment

    func build(router: AuthenticatedRouterProtocol) -> ZClientViewController {
        let viewController = ZClientViewController(
            account: account,
            selfProfileViewsMonitor: SelfProfileViewsMonitorImplementation(),
            userSession: userSession,
            trackingManager: trackingManager,
            wireCellsFactory: buildWireCellsFactory()
        )
        viewController.router = router
        return viewController
    }

    func callAsFunction(router: AuthenticatedRouterProtocol) -> ZClientViewController {
        build(router: router)
    }

    private func buildWireCellsFactory() -> WireCellsFactory {
        if DeveloperFlag.wireCellsManualAuthentication.isOn {
            WireCellsFactory(
                serverURL: URL(string: "https://service.zeta.pydiocells.com")!,
                accessToken: ManualTokenProvider()
            )
        } else {
            WireCellsFactory(
                serverURL: environment.backendURL,
                accessToken: DefaultAccessTokenProvider(userSession: userSession)
            )
        }
    }
}

private struct DefaultAccessTokenProvider: AccessTokenProvider {

    enum Error: Swift.Error {
        case noAuthenticationManager
    }

    let userSession: UserSession

    func accessToken() async throws -> WireCellsAccessToken {
        guard let authManager = userSession.clientSessionComponent?.authenticationManager else {
            throw Error.noAuthenticationManager
        }

        let token = try await authManager.getValidAccessToken()
        return WireCellsAccessToken(
            token: token.token,
            expirationDate: token.expirationDate
        )
    }
}

private struct ManualTokenProvider: AccessTokenProvider {

    func accessToken() async throws -> WireCellsAccessToken {
        WireCellsAccessToken(
            token: UserDefaults.standard.string(forKey: "ZMWireCellsAccessToken") ?? "unknown",
            expirationDate: Date.distantFuture
        )
    }
}

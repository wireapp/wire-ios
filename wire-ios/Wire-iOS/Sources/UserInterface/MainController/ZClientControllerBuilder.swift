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

import WireCallingAssembly
import WireCommonComponents
import WireData
@preconcurrency import WireDataModel
import WireLogging
import WireMessagingAssembly
import WireMessagingDomain
import WireNetwork
@preconcurrency import WireSyncEngine
import WireTransport

final class ZClientControllerBuilder {

    private(set) var account: Account
    private(set) var userSession: UserSession
    private(set) var trackingManager: TrackingManager?
    let legacyEnvironment: WireTransport.BackendEnvironment
    let newEnvironment: WireNetwork.BackendEnvironment2?
    private lazy var wireCellsBackendURL: URL = {
        let serverURL = newEnvironment?.config.endpoints.restAPIURL ?? legacyEnvironment.backendURL
        return switch serverURL.host {
        case "prod-nginz-https.wire.com": // Production
            URL(string: "https://cells-beta.wire.com")!
        case "staging-nginz-https.zinfra.io": // Staging
            URL(string: "https://cells.staging.zinfra.io")!
        case "nginz-https.fulu.wire.link": // Fulu
            URL(string: "https://cells.fulu.wire.link")!
        case "nginz-https.imai.wire.link": // Imai
            URL(string: "https://cells.imai.wire.link")!
        default:
            serverURL
        }
    }()

    init(
        account: Account,
        userSession: UserSession,
        trackingManager: TrackingManager? = nil,
        legacyEnvironment: WireTransport.BackendEnvironment,
        newEnvironment: WireNetwork.BackendEnvironment2?
    ) {
        self.account = account
        self.userSession = userSession
        self.trackingManager = trackingManager
        self.legacyEnvironment = legacyEnvironment
        self.newEnvironment = newEnvironment
    }

    @MainActor
    func build(router: AuthenticatedRouterProtocol) -> ZClientViewController {
        let viewController = ZClientViewController(
            account: account,
            contextProvider: DefaultManagedObjectContextProvider(contextProvider: userSession.contextProvider),
            selfProfileViewsMonitor: SelfProfileViewsMonitorImplementation(),
            userSession: userSession,
            trackingManager: trackingManager,
            wireMeetingsFactory: buildWireMeetingsFactory(),
            wireMessagingFactory: buildWireMessagingFactory()
        )
        viewController.router = router
        return viewController
    }

    @MainActor
    func callAsFunction(router: AuthenticatedRouterProtocol) -> ZClientViewController {
        build(router: router)
    }

    @MainActor
    private func buildWireMessagingFactory() -> any WireMessagingFactoryProtocol {
        let cellsURLResolver: @Sendable () throws -> URL = { [weak self] in
            enum Failure: Error {
                case missingCellsBackendURL
            }

            guard let self else {
                throw Failure.missingCellsBackendURL
            }

            return wireCellsBackendURL
        }

        return WireMessagingFactory(
            cellsURLResolver: cellsURLResolver,
            // TODO: [WPB-18798] Temporary fix, when multibackend is on we use new backend environment, when off we use the legacy one
            accessToken: DefaultAccessTokenProvider(userSession: userSession),
            fileCache: userSession.fileAssetCache,
            contextProvider: DefaultManagedObjectContextProvider(contextProvider: userSession.contextProvider),
            isFoldersEnabled: DeveloperFlag.wireCellsFolders.isOn,
            isCollaboraEnabled: DeveloperFlag.wireCellsCollabora.isOn
        )
    }

    @MainActor
    private func buildWireMeetingsFactory() -> any WireMeetingsFactoryProtocol {
        WireMeetingsFactory(
            passwordValidator: AuthenticationPasswordValidator(),
            isContextMenuAllowed: SecurityFlags.clipboard.isEnabled
        )
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

extension FileAssetCache: WireMessagingDomain.FileCache, @unchecked @retroactive Sendable {}

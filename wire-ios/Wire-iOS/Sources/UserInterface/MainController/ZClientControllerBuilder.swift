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

struct ZClientControllerBuilder {

    private(set) var account: Account
    private(set) var userSession: UserSession
    private(set) var trackingManager: TrackingManager?
    let legacyEnvironment: WireTransport.BackendEnvironment
    let newEnvironment: WireNetwork.BackendEnvironment2?

    @MainActor
    func build(router: AuthenticatedRouterProtocol) -> ZClientViewController {
        let viewController = ZClientViewController(
            account: account,
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
        let cellsURLResolver: @Sendable () async throws -> URL = {
            enum Failure: Error {
                case missingCellsBackendURL
            }

            let clientSessionComponent = userSession.clientSessionComponent
            let featureConfig = clientSessionComponent?.featureConfigRepository
            let serverURL = try await featureConfig?.fetchCellsInternal().config?.backend.url

            guard let serverURL else {
                throw Failure.missingCellsBackendURL
            }

            return serverURL
        }

        return WireMessagingFactory(
            cellsURLResolver: cellsURLResolver,
            // TODO: [WPB-18798] Temporary fix, when multibackend is on we use new backend environment, when off we use the legacy one
            accessToken: DefaultAccessTokenProvider(userSession: userSession),
            fileCache: userSession.fileAssetCache,
            contextProvider: DefaultContextProvider(contextProvider: userSession.contextProvider),
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

private struct DefaultContextProvider: ManagedObjectContextProvider {

    let contextProvider: any ContextProvider

    var viewContext: NSManagedObjectContext {
        contextProvider.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        contextProvider.newBackgroundContext()
    }

}

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
import WireDomain
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
    private lazy var wireDriveBackendURL: URL? = {
        let contextProvider = userSession.contextProvider
        let syncContext = contextProvider.syncContext
        let featureRepository = LegacyFeatureRepository(context: syncContext)

        return syncContext.performAndWait {
            featureRepository.fetchCellsInternal()?.config.backend.url
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
        let driveURLResolver: @Sendable () throws -> URL = { [weak self] in
            enum Failure: Error {
                case missingDriveBackendURL
            }

            guard let self, let wireDriveBackendURL else {
                throw Failure.missingDriveBackendURL
            }

            return wireDriveBackendURL
        }

        let context = userSession.contextProvider.syncContext
        let driveConversationLocalStore = ConversationLocalStore(
            context: context,
            mlsService: nil,
            messageLocalStore: MessageLocalStore(context: context),
            localDomain: userSession.resolvedBackendMetadata.domain,
            isFederationEnabled: userSession.resolvedBackendMetadata.isFederationEnabled
        )

        return WireMessagingFactory(
            driveURLResolver: driveURLResolver,
            driveConversationLocalStore: driveConversationLocalStore,
            accessToken: DefaultAccessTokenProvider(userSession: userSession),
            fileCache: userSession.fileAssetCache,
            contextProvider: DefaultManagedObjectContextProvider(contextProvider: userSession.contextProvider)
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

    func accessToken() async throws -> WireDriveAccessToken {
        guard let authManager = userSession.clientSessionComponent?.authenticationManager else {
            throw Error.noAuthenticationManager
        }

        let token = try await authManager.getValidAccessToken()
        return WireDriveAccessToken(
            token: token.token,
            expirationDate: token.expirationDate
        )
    }

}

extension FileAssetCache: WireMessagingDomain.FileCache, @unchecked @retroactive Sendable {}
extension ConversationLocalStore: @retroactive WireDriveConversationsLocalStoreProtocol,
    @unchecked @retroactive Sendable {
    public func fetchDriveConversations() async -> [WireMessagingDomain.WireDriveConversation] {
        let driveEnabledConversations: [ZMConversation] = await fetchDriveConversations()

        return await context.perform {
            driveEnabledConversations.reduce(into: [WireDriveConversation]()) { result, conversation in
                if let name = conversation.name {
                    let participants: [WireDriveConversation.Participant] = conversation.participants
                        .compactMap { item -> WireDriveConversation.Participant? in
                            guard let id = item.remoteIdentifier, let domain = item.domain else { return nil }
                            
                            return .init(
                                handle: item.handle ?? "-",
                                displayName: item.name ?? "-",
                                isSelfUser: item.isSelfUser,
                                id: id.uuidString + "@" + domain,
                                iconData: WireDriveConversation.Participant.IconData(
                                    initials: item.initials ?? "",
                                    color: item.accentColor,
                                    image: item.previewImageData.flatMap(UIImage.init)
                                )
                            )
                        }

                    let kind: WireDriveConversation.Kind = conversation.isChannel ? .channel : .group

                    let driveConversation = WireDriveConversation(
                        id: conversation.wireDriveCellName,
                        name: name,
                        kind: kind,
                        participants: Set(participants)
                    )

                    result.append(driveConversation)
                }
            }
        }
    }
}

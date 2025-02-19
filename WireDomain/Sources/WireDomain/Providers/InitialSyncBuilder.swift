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
import WireAPI
import WireDataModel
import WireFoundation

public struct InitialSyncBuilder: InitialSyncBuilderProtocol {

    public enum Failure: Error {

        case missingLocalDomain
        case missingAPIVersion

    }

    let selfUserID: UUID
    let selfClientID: String?
    let syncContext: NSManagedObjectContext
    let mlsService: any MLSServiceInterface
    let sharedUserDefaults: UserDefaults
    let backendEnvironment: WireAPI.BackendEnvironment
    let minTLSVersion: WireAPI.TLSVersion

    public init(
        selfUserID: UUID,
        selfClientID: String?,
        syncContext: NSManagedObjectContext,
        mlsService: any MLSServiceInterface,
        sharedUserDefaults: UserDefaults,
        backendEnvironment: WireAPI.BackendEnvironment,
        minTLSVersion: WireAPI.TLSVersion
    ) {
        self.selfUserID = selfUserID
        self.selfClientID = selfClientID
        self.syncContext = syncContext
        self.mlsService = mlsService
        self.sharedUserDefaults = sharedUserDefaults
        self.backendEnvironment = backendEnvironment
        self.minTLSVersion = minTLSVersion
    }

    public func build() throws -> any InitialSyncProtocol {
        guard let localDomain = BackendInfo.domain else {
            throw Failure.missingLocalDomain
        }

        let apiService = buildAPIService()
        let apis = try buildAPIS(apiService: apiService)
        let stores = buildStores()
        let syncs = buildSyncs(
            localDomain: localDomain,
            apis: apis,
            stores: stores
        )

        let pullResourcesSync = buildPullResourceSync(syncs: syncs)

        let featureConfigRepository = FeatureConfigRepository(
            featureConfigsAPI: apis.featureConfigsAPI,
            featureConfigLocalStore: stores.featureConfigsLocalStore
        )

        let pushSupportedProtocolsUseCase = PushSupportedProtocolsUseCase(
            featureConfigRepository: featureConfigRepository,
            pushSupportedProtocolsSync: syncs.pushSupportedProtocolsSync,
            userClientsLocalStore: stores.userClientsLocalStore
        )

        let mlsProvider = MLSProvider(
            service: mlsService,
            isMLSEnabled: BackendInfo.isMLSEnabled
        )

        let oneOnOneResolver = OneOnOneResolver(
            context: syncContext,
            userLocalStore: stores.userLocalStore,
            conversationLocalStore: stores.conversationsLocalStore,
            pullMLSOneOnOneSync: syncs.pullMLSOneOnOneSync,
            mlsProvider: mlsProvider
        )

        return InitialSync(
            pullLastUpdateEventIDSync: syncs.pullLastUpdateEventIDSync,
            pullResourcesSync: pullResourcesSync,
            pushSupportedProtocolsUseCase: pushSupportedProtocolsUseCase,
            oneOnOneResolver: oneOnOneResolver
        )
    }

    private func buildAPIService() -> APIService {
        let keychain = WireFoundation.Keychain()
        let serverTrustValidator = ServerTrustValidator(pinnedKeys: backendEnvironment.pinnedKeys)

        let networkService = NetworkService(
            baseURL: backendEnvironment.url,
            serverTrustValidator: serverTrustValidator
        )

        let urlSessionConfigurationFactory = URLSessionConfigurationFactory(
            minTLSVersion: minTLSVersion,
            proxySettings: backendEnvironment.proxySettings
        )

        let config = urlSessionConfigurationFactory.makeRESTAPISessionConfiguration()

        let session = URLSession(
            configuration: config,
            delegate: networkService,
            delegateQueue: nil
        )

        networkService.configure(with: session)

        let cookieStorage = CookieStorage(
            userID: selfUserID,
            cookieEncryptionKey: UserDefaults.cookiesKey(),
            keychain: keychain
        )

        let authenticationManager = AuthenticationManager(
            clientID: selfClientID,
            cookieStorage: cookieStorage,
            networkService: networkService
        )

        return APIService(
            networkService: networkService,
            authenticationManager: authenticationManager
        )
    }

    private func buildAPIS(apiService: APIService) throws -> APIS {
        guard
            let rawAPIVersion = BackendInfo.apiVersion?.rawValue,
            let apiVersion = WireAPI.APIVersion(rawValue: UInt(rawAPIVersion))
        else {
            throw Failure.missingAPIVersion
        }

        return APIS(
            updateEventsAPI: UpdateEventsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion),
            selfUserAPI: SelfUserAPIBuilder(apiService: apiService).makeAPI(for: apiVersion),
            teamsAPI: TeamsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion),
            userConnectionsAPI: ConnectionsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion),
            conversationsAPI: ConversationsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion),
            usersAPI: UsersAPIBuilder(apiService: apiService).makeAPI(for: apiVersion),
            userPropertiesAPI: UserPropertiesAPIBuilder(apiService: apiService).makeAPI(for: apiVersion),
            featureConfigsAPI: FeatureConfigsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion),
            backendInfoAPI: BackendInfoAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
        )
    }

    private func buildStores() -> Stores {
        let updateEventsLocalStore = UpdateEventsLocalStore(
            context: syncContext,
            userID: selfUserID,
            sharedUserDefaults: sharedUserDefaults
        )

        let userLocalStore = UserLocalStore(
            context: syncContext,
            userDefaults: sharedUserDefaults
        )

        let teamLocalStore = TeamLocalStore(
            context: syncContext,
            userLocalStore: userLocalStore
        )

        let userConnectionsStore = ConnectionsLocalStore(context: syncContext)
        let messageLocalStore = MessageLocalStore(
            context: syncContext,
            userLocalStore: userLocalStore
        )

        let conversationsLocalStore = ConversationLocalStore(
            context: syncContext,
            mlsService: mlsService,
            userLocalStore: userLocalStore,
            messageLocalStore: messageLocalStore
        )

        let conversationLabelsLocalStore = ConversationLabelsLocalStore(context: syncContext)
        let featureConfigsLocalStore = FeatureConfigLocalStore(context: syncContext)

        let userClientsLocalStore = UserClientsLocalStore(
            context: syncContext,
            userLocalStore: userLocalStore
        )

        let backendConfigLocalStore = BackendConfigLocalStore(sharedUserDefaults: sharedUserDefaults)

        return Stores(
            updateEventsLocalStore: updateEventsLocalStore,
            userLocalStore: userLocalStore,
            teamLocalStore: teamLocalStore,
            userConnectionsStore: userConnectionsStore,
            messageLocalStore: messageLocalStore,
            conversationsLocalStore: conversationsLocalStore,
            conversationLabelsLocalStore: conversationLabelsLocalStore,
            featureConfigsLocalStore: featureConfigsLocalStore,
            userClientsLocalStore: userClientsLocalStore,
            backendConfigLocalStore: backendConfigLocalStore
        )
    }

    private func buildSyncs(
        localDomain: String,
        apis: APIS,
        stores: Stores
    ) -> Syncs {
        let pullSelfUserSync = PullSelfUserSync(
            api: apis.selfUserAPI,
            store: stores.userLocalStore
        )

        let pullSelfUserSettingsSync = PullSelfUserSettingsSync(
            api: apis.userPropertiesAPI,
            store: stores.userLocalStore
        )

        let pullSelfTeamSync = PullSelfTeamSync(
            api: apis.teamsAPI,
            store: stores.teamLocalStore
        )

        let pullSelfTeamRolesSync = PullSelfTeamRolesSync(
            api: apis.teamsAPI,
            store: stores.teamLocalStore
        )

        let pullSelfTeamMembersSync = PullSelfTeamMembersSync(
            api: apis.teamsAPI,
            store: stores.teamLocalStore
        )

        let pullSelfLegalholdInfoSync = PullSelfLegalholdInfoSync(
            selfUserID: selfUserID,
            api: apis.teamsAPI,
            store: stores.userLocalStore
        )

        let pullUserConnectionsSync = PullUserConnectionsSync(
            api: apis.userConnectionsAPI,
            store: stores.userConnectionsStore
        )

        let pullAllConversationsSync = PullAllConversationsSync(
            localDomain: localDomain,
            isFederationEnabled: BackendInfo.isFederationEnabled,
            isMLSEnabled: BackendInfo.isMLSEnabled,
            api: apis.conversationsAPI,
            store: stores.conversationsLocalStore
        )

        let pullKnownUsersSync = PullKnownUsersSync(
            api: apis.usersAPI,
            store: stores.userLocalStore
        )

        let pullConversationLabelsSync = PullConversationLabelsSync(
            api: apis.userPropertiesAPI,
            store: stores.conversationLabelsLocalStore
        )

        let pullAllFeatureConfigsSync = PullAllFeatureConfigsSync(
            api: apis.featureConfigsAPI,
            store: stores.featureConfigsLocalStore
        )

        let pushSupportedProtocolsSync = PushSupportedProtocolsSync(
            api: apis.selfUserAPI,
            store: stores.userLocalStore
        )

        let pullMLSOneOnOneSync = PullMLSOneOnOneSync(
            api: apis.conversationsAPI,
            store: stores.conversationsLocalStore,
            isFederationEnabled: BackendInfo.isFederationEnabled,
            isMLSEnabled: BackendInfo.isMLSEnabled
        )

        let pullMLSStatusSync = PullMLSStatusSync(
            api: apis.backendInfoAPI,
            store: stores.backendConfigLocalStore
        )

        let pullLastUpdateEventIDSync = PullLastUpdateEventIDSync(
            selfClientID: selfClientID,
            api: apis.updateEventsAPI,
            store: stores.updateEventsLocalStore
        )

        return Syncs(
            pullSelfUserSync: pullSelfUserSync,
            pullSelfUserSettingsSync: pullSelfUserSettingsSync,
            pullSelfTeamSync: pullSelfTeamSync,
            pullSelfTeamRolesSync: pullSelfTeamRolesSync,
            pullSelfTeamMembersSync: pullSelfTeamMembersSync,
            pullSelfLegalholdInfoSync: pullSelfLegalholdInfoSync,
            pullUserConnectionsSync: pullUserConnectionsSync,
            pullAllConversationsSync: pullAllConversationsSync,
            pullKnownUsersSync: pullKnownUsersSync,
            pullConversationLabelsSync: pullConversationLabelsSync,
            pullAllFeatureConfigsSync: pullAllFeatureConfigsSync,
            pushSupportedProtocolsSync: pushSupportedProtocolsSync,
            pullMLSOneOnOneSync: pullMLSOneOnOneSync,
            pullMLSStatusSync: pullMLSStatusSync,
            pullLastUpdateEventIDSync: pullLastUpdateEventIDSync
        )
    }

    private func buildPullResourceSync(syncs: Syncs) -> PullResourcesSync {
        PullResourcesSync(
            pullSelfUserSync: syncs.pullSelfUserSync,
            pullSelfUserSettingsSync: syncs.pullSelfUserSettingsSync,
            pullSelfTeamSync: syncs.pullSelfTeamSync,
            pullSelfTeamRolesSync: syncs.pullSelfTeamRolesSync,
            pullSelfTeamMembersSync: syncs.pullSelfTeamMembersSync,
            pullSelfLegalholdInfoSync: syncs.pullSelfLegalholdInfoSync,
            pullUserConnectionsSync: syncs.pullUserConnectionsSync,
            pullAllConversationsSync: syncs.pullAllConversationsSync,
            pullKnownUsersSync: syncs.pullKnownUsersSync,
            pullConversationLabelsSync: syncs.pullConversationLabelsSync,
            pullAllFeatureConfigsSync: syncs.pullAllFeatureConfigsSync,
            pullMLSStatusSync: syncs.pullMLSStatusSync
        )
    }

    private struct APIS {

        let updateEventsAPI: UpdateEventsAPI
        let selfUserAPI: SelfUserAPI
        let teamsAPI: TeamsAPI
        let userConnectionsAPI: ConnectionsAPI
        let conversationsAPI: ConversationsAPI
        let usersAPI: UsersAPI
        let userPropertiesAPI: UserPropertiesAPI
        let featureConfigsAPI: FeatureConfigsAPI
        let backendInfoAPI: BackendInfoAPI

    }

    private struct Stores {

        let updateEventsLocalStore: UpdateEventsLocalStore
        let userLocalStore: UserLocalStore
        let teamLocalStore: TeamLocalStore
        let userConnectionsStore: ConnectionsLocalStore
        let messageLocalStore: MessageLocalStore
        let conversationsLocalStore: ConversationLocalStore
        let conversationLabelsLocalStore: ConversationLabelsLocalStore
        let featureConfigsLocalStore: FeatureConfigLocalStore
        let userClientsLocalStore: UserClientsLocalStore
        let backendConfigLocalStore: BackendConfigLocalStore

    }

    private struct Syncs {

        let pullSelfUserSync: PullSelfUserSync
        let pullSelfUserSettingsSync: PullSelfUserSettingsSync
        let pullSelfTeamSync: PullSelfTeamSync
        let pullSelfTeamRolesSync: PullSelfTeamRolesSync
        let pullSelfTeamMembersSync: PullSelfTeamMembersSync
        let pullSelfLegalholdInfoSync: PullSelfLegalholdInfoSync
        let pullUserConnectionsSync: PullUserConnectionsSync
        let pullAllConversationsSync: PullAllConversationsSync
        let pullKnownUsersSync: PullKnownUsersSync
        let pullConversationLabelsSync: PullConversationLabelsSync
        let pullAllFeatureConfigsSync: PullAllFeatureConfigsSync
        let pushSupportedProtocolsSync: PushSupportedProtocolsSync
        let pullMLSOneOnOneSync: PullMLSOneOnOneSync
        let pullMLSStatusSync: PullMLSStatusSync
        let pullLastUpdateEventIDSync: PullLastUpdateEventIDSync

    }

}

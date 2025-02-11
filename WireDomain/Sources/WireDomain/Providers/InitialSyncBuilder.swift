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

public struct InitialSyncBuilder {

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

    public func build() throws -> InitialSync {
        guard let localDomain = BackendInfo.domain else {
            throw Failure.missingLocalDomain
        }

        guard
            let rawAPIVersion = BackendInfo.apiVersion?.rawValue,
            let apiVersion = WireAPI.APIVersion(rawValue: UInt(rawAPIVersion))
        else {
            throw Failure.missingAPIVersion
        }

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

        let apiService = APIService(
            networkService: networkService,
            authenticationManager: authenticationManager
        )

        let updateEventsAPI = UpdateEventsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
        let selfUserAPI = SelfUserAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
        let teamsAPI = TeamsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
        let userConnectionsAPI = ConnectionsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
        let conversationsAPI = ConversationsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
        let usersAPI = UsersAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
        let userPropertiesAPI = UserPropertiesBuilder(apiService: apiService).makeAPI(for: apiVersion)
        let featureConfigsAPI = FeatureConfigsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)

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

        let pullLastUpdateEventIDSync = PullLastUpdateEventIDSync(
            selfClientID: selfClientID,
            api: updateEventsAPI,
            store: updateEventsLocalStore
        )

        let pullSelfUserSync = PullSelfUserSync(
            api: selfUserAPI,
            store: userLocalStore
        )

        let pullSelfUserSettingsSync = PullSelfUserSettingsSync(
            api: userPropertiesAPI,
            store: userLocalStore
        )

        let pullSelfTeamSync = PullSelfTeamSync(
            api: teamsAPI,
            store: teamLocalStore
        )

        let pullSelfTeamRolesSync = PullSelfTeamRolesSync(
            api: teamsAPI,
            store: teamLocalStore
        )

        let pullSelfTeamMembersSync = PullSelfTeamMembersSync(
            api: teamsAPI,
            store: teamLocalStore
        )

        let pullSelfLegalholdInfoSync = PullSelfLegalholdInfoSync(
            selfUserID: selfUserID,
            api: teamsAPI,
            store: userLocalStore
        )

        let pullUserConnectionsSync = PullUserConnectionsSync(
            api: userConnectionsAPI,
            store: userConnectionsStore
        )

        let pullAllConversationsSync = PullAllConversationsSync(
            localDomain: localDomain,
            isFederationEnabled: BackendInfo.isFederationEnabled,
            isMLSEnabled: BackendInfo.isMLSEnabled,
            api: conversationsAPI,
            store: conversationsLocalStore
        )

        let pullKnownUsersSync = PullKnownUsersSync(
            api: usersAPI,
            store: userLocalStore
        )

        let pullConversationLabelsSync = PullConversationLabelsSync(
            api: userPropertiesAPI,
            store: conversationLabelsLocalStore
        )

        let pullAllFeatureConfigsSync = PullAllFeatureConfigsSync(
            api: featureConfigsAPI,
            store: featureConfigsLocalStore
        )

        let pullResourcesSync = PullResourcesSync(
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
            pullAllFeatureConfigsSync: pullAllFeatureConfigsSync
        )

        let pushSupportedProtocolsSync = PushSupportedProtocolsSync(
            api: selfUserAPI,
            store: userLocalStore
        )

        let featureConfigRepository = FeatureConfigRepository(
            featureConfigsAPI: featureConfigsAPI,
            featureConfigLocalStore: featureConfigsLocalStore
        )

        let pushSupportedProtocolsUseCase = PushSupportedProtocolsUseCase(
            featureConfigRepository: featureConfigRepository,
            pushSupportedProtocolsSync: pushSupportedProtocolsSync,
            userClientsLocalStore: userClientsLocalStore
        )

        let pullMLSOneOnOneSync = PullMLSOneOnOneSync(
            api: conversationsAPI,
            store: conversationsLocalStore,
            isFederationEnabled: BackendInfo.isFederationEnabled,
            isMLSEnabled: BackendInfo.isMLSEnabled
        )

        let mlsProvider = MLSProvider(
            service: mlsService,
            isMLSEnabled: BackendInfo.isMLSEnabled
        )

        let oneOnOneResolver = OneOnOneResolver(
            context: syncContext,
            userLocalStore: userLocalStore,
            conversationLocalStore: conversationsLocalStore,
            pullMLSOneOnOneSync: pullMLSOneOnOneSync,
            mlsProvider: mlsProvider
        )

        return InitialSync(
            pullLastUpdateEventIDSync: pullLastUpdateEventIDSync,
            pullResourcesSync: pullResourcesSync,
            pushSupportedProtocolsUseCase: pushSupportedProtocolsUseCase,
            oneOnOneResolver: oneOnOneResolver
        )
    }

}

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

public final class ClientSessionComponent {

    private let selfUserID: UUID
    private let selfClientID: String

    private let networkService: NetworkService
    private let apiVersion: WireAPI.APIVersion

    private let localDomain: String
    private let isFederationEnabled: Bool
    private let isMLSEnabled: Bool

    private let cookieStorage: any CookieStorageProtocol
    private let sharedUserDefaults: UserDefaults
    private let syncContext: NSManagedObjectContext
    private let eventContext: NSManagedObjectContext

    private let mlsService: any MLSServiceInterface
    private let mlsDecryptionService: any MLSDecryptionServiceInterface
    private let proteusService: any ProteusServiceInterface

    public init(
        selfUserID: UUID,
        selfClientID: String,
        networkService: NetworkService,
        apiVersion: WireAPI.APIVersion,
        localDomain: String,
        isFederationEnabled: Bool,
        isMLSEnabled: Bool,
        cookieStorage: any CookieStorageProtocol,
        sharedUserDefaults: UserDefaults,
        syncContext: NSManagedObjectContext,
        eventContext: NSManagedObjectContext,
        mlsService: any MLSServiceInterface,
        mlsDecryptionService: any MLSDecryptionServiceInterface,
        proteusService: any ProteusServiceInterface
    ) {
        self.selfUserID = selfUserID
        self.selfClientID = selfClientID
        self.cookieStorage = cookieStorage
        self.networkService = networkService
        self.apiVersion = apiVersion
        self.sharedUserDefaults = sharedUserDefaults
        self.syncContext = syncContext
        self.eventContext = eventContext
        self.mlsService = mlsService
        self.mlsDecryptionService = mlsDecryptionService
        self.proteusService = proteusService
        self.localDomain = localDomain
        self.isFederationEnabled = isFederationEnabled
        self.isMLSEnabled = isMLSEnabled
    }

    private lazy var authenticationManager: some AuthenticationManagerProtocol = AuthenticationManager(
        clientID: selfClientID,
        cookieStorage: cookieStorage,
        networkService: networkService
    )

    // MARK: - Network API clients

    private lazy var apiService: some APIServiceProtocol = APIService(
        networkService: networkService,
        authenticationManager: authenticationManager
    )

    private lazy var backendInfoAPI: any BackendInfoAPI = BackendInfoAPIBuilder(apiService: apiService)
        .makeAPI(for: apiVersion)

    private lazy var conversationsAPI: any ConversationsAPI = ConversationsAPIBuilder(apiService: apiService)
        .makeAPI(for: apiVersion)

    private lazy var featureConfigsAPI: any FeatureConfigsAPI = FeatureConfigsAPIBuilder(apiService: apiService)
        .makeAPI(for: apiVersion)

    private lazy var selfUserAPI: any SelfUserAPI = SelfUserAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)

    private lazy var teamsAPI: any TeamsAPI = TeamsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)

    private lazy var updateEventsAPI: any UpdateEventsAPI = UpdateEventsAPIBuilder(apiService: apiService)
        .makeAPI(for: apiVersion)

    private lazy var userClientsAPI: any UserClientsAPI = UserClientsAPIBuilder(apiService: apiService)
        .makeAPI(for: apiVersion)

    private lazy var userConnectionsAPI: any ConnectionsAPI = ConnectionsAPIBuilder(apiService: apiService)
        .makeAPI(for: apiVersion)

    private lazy var usersAPI: any UsersAPI = UsersAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)

    private lazy var userPropertiesAPI: any UserPropertiesAPI = UserPropertiesAPIBuilder(apiService: apiService)
        .makeAPI(for: apiVersion)

    // MARK: - Local storage

    private lazy var backendConfigLocalStore: some BackendConfigLocalStoreProtocol = BackendConfigLocalStore(
        sharedUserDefaults: sharedUserDefaults
    )

    private lazy var conversationLabelsLocalStore: some ConversationLabelsLocalStore = ConversationLabelsLocalStore(
        context: syncContext
    )

    private lazy var conversationLocalStore: some ConversationLocalStoreProtocol = ConversationLocalStore(
        context: syncContext,
        mlsService: mlsService,
        userLocalStore: userLocalStore,
        messageLocalStore: messageLocalStore
    )

    private lazy var featureConfigsLocalStore: some FeatureConfigLocalStoreProtocol = FeatureConfigLocalStore(
        context: syncContext
    )

    private lazy var messageLocalStore: some MessageLocalStoreProtocol = MessageLocalStore(
        context: syncContext,
        userLocalStore: userLocalStore
    )

    private lazy var teamLocalStore: some TeamLocalStoreProtocol = TeamLocalStore(
        context: syncContext,
        userLocalStore: userLocalStore
    )

    private lazy var updateEventsLocalStore: some UpdateEventsLocalStoreProtocol = UpdateEventsLocalStore(
        context: eventContext,
        userID: selfUserID,
        sharedUserDefaults: sharedUserDefaults
    )

    private lazy var userClientsLocalStore: some UserClientsLocalStore = UserClientsLocalStore(
        context: syncContext,
        userLocalStore: userLocalStore
    )

    private lazy var userConnectionsStore: some ConnectionsLocalStoreProtocol = ConnectionsLocalStore(
        context: syncContext
    )

    private lazy var userLocalStore: some UserLocalStoreProtocol = UserLocalStore(
        context: syncContext,
        userDefaults: sharedUserDefaults
    )

    // MARK: - Pull syncs

    private lazy var pullAllConversationsSync: some PullAllConversationsSyncProtocol = PullAllConversationsSync(
        localDomain: localDomain,
        isFederationEnabled: BackendInfo.isFederationEnabled,
        isMLSEnabled: BackendInfo.isMLSEnabled,
        api: conversationsAPI,
        store: conversationLocalStore
    )

    private lazy var pullAllFeatureConfigsSync: some PullAllFeatureConfigsSyncProtocol = PullAllFeatureConfigsSync(
        api: featureConfigsAPI,
        store: featureConfigsLocalStore
    )

    private lazy var pullConversationLabelsSync: some PullConversationLabelsSyncProtocol = PullConversationLabelsSync(
        api: userPropertiesAPI,
        store: conversationLabelsLocalStore
    )

    private lazy var pullLastUpdateEventIDSync: some PullLastUpdateEventIDSyncProtocol = PullLastUpdateEventIDSync(
        selfClientID: selfClientID,
        api: updateEventsAPI,
        store: updateEventsLocalStore
    )

    private lazy var pullKnownUsersSync: some PullKnownUsersSyncProtocol = PullKnownUsersSync(
        api: usersAPI,
        store: userLocalStore
    )

    private lazy var pullMLSOneOnOneSync: some PullMLSOneOnOneSyncProtocol = PullMLSOneOnOneSync(
        api: conversationsAPI,
        store: conversationLocalStore,
        isFederationEnabled: BackendInfo.isFederationEnabled,
        isMLSEnabled: BackendInfo.isMLSEnabled
    )

    private lazy var pullMLSStatusSync: some PullMLSStatusSyncProtocol = PullMLSStatusSync(
        api: backendInfoAPI,
        store: backendConfigLocalStore
    )

    private lazy var pullSelfLegalholdInfoSync: some PullSelfLegalholdInfoSyncProtocol = PullSelfLegalholdInfoSync(
        selfUserID: selfUserID,
        api: teamsAPI,
        store: userLocalStore
    )

    private lazy var pullSelfTeamMembersSync: some PullSelfTeamMembersSyncProtocol = PullSelfTeamMembersSync(
        api: teamsAPI,
        store: teamLocalStore
    )

    private lazy var pullSelfTeamRolesSync: some PullSelfTeamRolesSyncProtocol = PullSelfTeamRolesSync(
        api: teamsAPI,
        store: teamLocalStore
    )

    private lazy var pullSelfTeamSync: some PullSelfTeamSyncProtocol = PullSelfTeamSync(
        api: teamsAPI,
        store: teamLocalStore
    )

    private lazy var pullSelfUserSettingsSync: some PullSelfUserSettingsSyncProtocol = PullSelfUserSettingsSync(
        api: userPropertiesAPI,
        store: userLocalStore
    )

    private lazy var pullSelfUserSync: some PullSelfUserSyncProtocol = PullSelfUserSync(
        api: selfUserAPI,
        store: userLocalStore
    )

    private lazy var pullUserConnectionsSync: some PullUserConnectionsSyncProtocol = PullUserConnectionsSync(
        api: userConnectionsAPI,
        store: userConnectionsStore
    )

    // MARK: - Push syncs

    private lazy var pushSupportedProtocolsSync: some PushSupportedProtocolsSyncProtocol = PushSupportedProtocolsSync(
        api: selfUserAPI,
        store: userLocalStore
    )

    // MARK: High level syncs

    public lazy var initialSync: some InitialSyncProtocol = {
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
            pullAllFeatureConfigsSync: pullAllFeatureConfigsSync,
            pullMLSStatusSync: pullMLSStatusSync
        )

        let featureConfigRepository = FeatureConfigRepository(
            featureConfigsAPI: featureConfigsAPI,
            featureConfigLocalStore: featureConfigsLocalStore
        )

        let pushSupportedProtocolsUseCase = PushSupportedProtocolsUseCase(
            featureConfigRepository: featureConfigRepository,
            pushSupportedProtocolsSync: pushSupportedProtocolsSync,
            userClientsLocalStore: userClientsLocalStore,
            userLocalStore: userLocalStore
        )

        return InitialSync(
            pullLastUpdateEventIDSync: pullLastUpdateEventIDSync,
            pullResourcesSync: pullResourcesSync,
            pushSupportedProtocolsUseCase: pushSupportedProtocolsUseCase,
            oneOnOneResolver: oneOnOneResolver
        )
    }()

    // MARK: - Other

    private lazy var oneOnOneResolver: some OneOnOneResolverProtocol = OneOnOneResolver(
        context: syncContext,
        userLocalStore: userLocalStore,
        conversationLocalStore: conversationLocalStore,
        pullMLSOneOnOneSync: pullMLSOneOnOneSync,
        mlsProvider: mlsProvider
    )

    private lazy var mlsProvider = MLSProvider(
        service: mlsService,
        isMLSEnabled: isMLSEnabled
    )

}

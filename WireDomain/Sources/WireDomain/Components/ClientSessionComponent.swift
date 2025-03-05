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
    private let pushChannelNetworkService: NetworkService
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
        pushChannelNetworkService: NetworkService,
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
        self.pushChannelNetworkService = pushChannelNetworkService
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

    private lazy var authenticationManager = AuthenticationManager(
        clientID: selfClientID,
        cookieStorage: cookieStorage,
        networkService: networkService
    )

    // MARK: - Network API clients

    private lazy var apiService = APIService(
        networkService: networkService,
        authenticationManager: authenticationManager
    )

    private lazy var backendInfoAPI = BackendInfoAPIBuilder(
        networkService: networkService
    ).makeAPI()

    private lazy var conversationsAPI = ConversationsAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)

    private lazy var featureConfigsAPI = FeatureConfigsAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)

    private lazy var mlsAPI = MLSAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)

    private lazy var pushChannelAPI = PushChannelAPIBuilder(
        pushChannelService: pushChannelService
    ).makeAPI()

    private lazy var selfUserAPI = SelfUserAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)

    private lazy var teamsAPI = TeamsAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)

    private lazy var updateEventsAPI = UpdateEventsAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)

    private lazy var userClientsAPI = UserClientsAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)

    private lazy var userConnectionsAPI = ConnectionsAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)

    private lazy var usersAPI = UsersAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)

    private lazy var userPropertiesAPI = UserPropertiesAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)

    // MARK: - Local storage

    private lazy var backendConfigLocalStore = BackendConfigLocalStore(
        sharedUserDefaults: sharedUserDefaults
    )

    private lazy var conversationLabelsLocalStore = ConversationLabelsLocalStore(
        context: syncContext
    )

    private lazy var conversationLocalStore = ConversationLocalStore(
        context: syncContext,
        mlsService: mlsService,
        userLocalStore: userLocalStore,
        messageLocalStore: messageLocalStore
    )

    private lazy var featureConfigsLocalStore = FeatureConfigLocalStore(
        context: syncContext
    )

    private lazy var messageLocalStore = MessageLocalStore(
        context: syncContext,
        userLocalStore: userLocalStore
    )

    private lazy var teamLocalStore = TeamLocalStore(
        context: syncContext,
        userLocalStore: userLocalStore
    )

    private lazy var updateEventsLocalStore = UpdateEventsLocalStore(
        context: eventContext,
        userID: selfUserID,
        sharedUserDefaults: sharedUserDefaults
    )

    private lazy var userClientsLocalStore = UserClientsLocalStore(
        context: syncContext,
        userLocalStore: userLocalStore
    )

    private lazy var userConnectionsStore = ConnectionsLocalStore(
        context: syncContext
    )

    private lazy var userLocalStore = UserLocalStore(
        context: syncContext,
        userDefaults: sharedUserDefaults
    )

    // MARK: - Pull syncs

    private lazy var pullAllConversationsSync = PullAllConversationsSync(
        localDomain: localDomain,
        isFederationEnabled: BackendInfo.isFederationEnabled,
        isMLSEnabled: BackendInfo.isMLSEnabled,
        api: conversationsAPI,
        store: conversationLocalStore
    )

    private lazy var pullAllFeatureConfigsSync = PullAllFeatureConfigsSync(
        api: featureConfigsAPI,
        store: featureConfigsLocalStore
    )

    private lazy var pullConversationLabelsSync = PullConversationLabelsSync(
        api: userPropertiesAPI,
        store: conversationLabelsLocalStore
    )

    private lazy var pullLastUpdateEventIDSync = PullLastUpdateEventIDSync(
        selfClientID: selfClientID,
        api: updateEventsAPI,
        store: updateEventsLocalStore
    )

    private lazy var pullKnownUsersSync = PullKnownUsersSync(
        api: usersAPI,
        store: userLocalStore
    )

    private lazy var pullMLSOneOnOneSync = PullMLSOneOnOneSync(
        api: conversationsAPI,
        store: conversationLocalStore,
        isFederationEnabled: BackendInfo.isFederationEnabled,
        isMLSEnabled: BackendInfo.isMLSEnabled
    )

    private lazy var pullMLSStatusSync = PullMLSStatusSync(
        api: mlsAPI,
        store: backendConfigLocalStore
    )

    private lazy var pullPendingUpdateEventsSync = PullPendingUpdateEventsSync(
        selfClientID: selfClientID,
        api: updateEventsAPI,
        store: updateEventsLocalStore,
        decryptor: updateEventDecryptor
    )

    private lazy var pullSelfLegalholdInfoSync = PullSelfLegalholdInfoSync(
        selfUserID: selfUserID,
        api: teamsAPI,
        store: userLocalStore
    )

    private lazy var pullSelfTeamMembersSync = PullSelfTeamMembersSync(
        api: teamsAPI,
        store: teamLocalStore
    )

    private lazy var pullSelfTeamRolesSync = PullSelfTeamRolesSync(
        api: teamsAPI,
        store: teamLocalStore
    )

    private lazy var pullSelfTeamSync = PullSelfTeamSync(
        api: teamsAPI,
        store: teamLocalStore
    )

    private lazy var pullSelfUserSettingsSync = PullSelfUserSettingsSync(
        api: userPropertiesAPI,
        store: userLocalStore
    )

    private lazy var pullSelfUserSync = PullSelfUserSync(
        api: selfUserAPI,
        store: userLocalStore
    )

    private lazy var pullUserConnectionsSync = PullUserConnectionsSync(
        api: userConnectionsAPI,
        store: userConnectionsStore
    )

    // MARK: - Push syncs

    private lazy var pushSupportedProtocolsSync = PushSupportedProtocolsSync(
        api: selfUserAPI,
        store: userLocalStore
    )

    // MARK: High level syncs

    public lazy var initialSync = {
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

    private lazy var pushChannelService = PushChannelService(
        networkService: pushChannelNetworkService,
        authenticationManager: authenticationManager
    )

    public lazy var incrementalSync = IncrementalSync(
        selfClientID: selfClientID,
        pushChannelAPI: pushChannelAPI,
        updateEventsSync: pullPendingUpdateEventsSync,
        decryptor: updateEventDecryptor,
        store: updateEventsLocalStore,
        processor: updateEventProcessor
    )

    // MARK: - Repositories

    private lazy var conversationLabelsRepository = ConversationLabelsRepository(
        userPropertiesAPI: userPropertiesAPI,
        conversationLabelsLocalStore: conversationLabelsLocalStore
    )

    private lazy var conversationRepository = ConversationRepository(
        conversationsAPI: conversationsAPI,
        conversationsLocalStore: conversationLocalStore,
        userLocalStore: userLocalStore,
        teamRepository: teamRepository,
        messageRepository: messageRepository,
        backendInfo: .init(
            domain: localDomain,
            isFederationEnabled: isFederationEnabled,
            isMLSEnabled: isMLSEnabled
        ),
        mlsProvider: mlsProvider
    )

    private lazy var featureConfigRepository = FeatureConfigRepository(
        featureConfigsAPI: featureConfigsAPI,
        featureConfigLocalStore: featureConfigsLocalStore
    )

    private lazy var messageRepository = MessageRepository(
        localStore: messageLocalStore
    )

    private lazy var teamRepository = TeamRepository(
        userRepository: userRepository,
        teamLocalStore: teamLocalStore,
        teamsAPI: teamsAPI
    )

    private lazy var userClientsRepository = UserClientsRepository(
        userClientsAPI: userClientsAPI,
        userRepository: userRepository,
        userClientsLocalStore: userClientsLocalStore
    )

    private lazy var userConnectionsRepository = ConnectionsRepository(
        connectionsAPI: userConnectionsAPI,
        connectionsLocalStore: userConnectionsStore
    )

    private lazy var userRepository = UserRepository(
        usersAPI: usersAPI,
        selfUserAPI: selfUserAPI,
        conversationLabelsRepository: conversationLabelsRepository,
        conversationLocalStore: conversationLocalStore,
        userLocalStore: userLocalStore
    )

    // MARK: - Update events

    private lazy var updateEventDecryptor = UpdateEventDecryptor(
        proteusService: proteusService,
        mlsService: mlsService,
        mlsDecryptionService: mlsDecryptionService,
        userClientsLocalStore: userClientsLocalStore,
        messageRepository: messageRepository,
        userLocalStore: userLocalStore,
        conversationLocalStore: conversationLocalStore
    )

    private lazy var conversationAccessUpdateEventProcessor = ConversationAccessUpdateEventProcessor(
        repository: conversationRepository,
        localStore: conversationLocalStore
    )

    private lazy var conversationCreateEventProcessor = ConversationCreateEventProcessor(
        repository: conversationRepository
    )

    private lazy var conversationDeleteEventProcessor = ConversationDeleteEventProcessor(
        repository: conversationRepository
    )

    private lazy var conversationMemberJoinEventProcessor = ConversationMemberJoinEventProcessor(
        conversationRepository: conversationRepository,
        conversationLocalStore: conversationLocalStore,
        userRepository: userRepository
    )

    private lazy var conversationMemberLeaveEventProcessor = ConversationMemberLeaveEventProcessor(
        repository: conversationRepository
    )

    private lazy var conversationMemberUpdateEventProcessor = ConversationMemberUpdateEventProcessor(
        conversationRepository: conversationRepository,
        userRepository: userRepository,
        localStore: conversationLocalStore
    )

    private lazy var conversationMessageTimerUpdateEventProcessor = ConversationMessageTimerUpdateEventProcessor(
        conversationLocalStore: conversationLocalStore,
        messageLocalStore: messageLocalStore
    )

    private lazy var conversationMLSMessageAddEventProcessor = ConversationMLSMessageAddEventProcessor(
        conversationLocalStore: conversationLocalStore,
        messageLocalStore: messageLocalStore,
        userLocalStore: userLocalStore,
        protobufMessageProcessor: conversationProtobufMessageProcessor
    )

    private lazy var conversationMLSWelcomeEventProcessor = ConversationMLSWelcomeEventProcessor(
        conversationRepository: conversationRepository,
        conversationLocalStore: conversationLocalStore,
        mlsService: mlsService,
        mlsDecryptionService: mlsDecryptionService,
        oneOnOneResolver: oneOnOneResolver
    )

    private lazy var conversationProteusMessageAddEventProcessor = ConversationProteusMessageAddEventProcessor(
        conversationLocalStore: conversationLocalStore,
        messageLocalStore: messageLocalStore,
        userLocalStore: userLocalStore,
        protobufMessageProcessor: conversationProtobufMessageProcessor
    )

    private lazy var conversationProtocolUpdateEventProcessor = ConversationProtocolUpdateEventProcessor(
        repository: conversationRepository
    )

    private lazy var conversationReceiptModeUpdateEventProcessor = ConversationReceiptModeUpdateEventProcessor(
        userRepository: userRepository,
        conversationRepository: conversationRepository,
        conversationLocalStore: conversationLocalStore,
        messageRepository: messageRepository
    )

    private lazy var conversationRenameEventProcessor = ConversationRenameEventProcessor(
        repository: conversationRepository
    )

    private lazy var conversationTypingEventProcessor = ConversationTypingEventProcessor(
        conversationRepository: conversationRepository,
        conversationLocalStore: conversationLocalStore,
        userRepository: userRepository
    )

    private lazy var featureConfigUpdateEventProcessor = FeatureConfigUpdateEventProcessor(
        repository: featureConfigRepository
    )

    private lazy var federationConnectionRemovedEventProcessor = FederationConnectionRemovedEventProcessor(
        context: syncContext
    )

    private lazy var federationDeleteEventProcessor = FederationDeleteEventProcessor(
        context: syncContext
    )

    private lazy var userClientAddEventProcessor = UserClientAddEventProcessor(
        repository: userClientsRepository
    )

    private lazy var userClientRemoveEventProcessor = UserClientRemoveEventProcessor()

    private lazy var userConnectionEventProcessor = UserConnectionEventProcessor(
        connectionsRepository: userConnectionsRepository,
        oneOnOneResolver: oneOnOneResolver
    )

    private lazy var userDeleteEventProcessor = UserDeleteEventProcessor(
        repository: userRepository
    )

    private lazy var userLegalholdDisableEventProcessor = UserLegalholdDisableEventProcessor(
        repository: userRepository
    )

    private lazy var userLegalholdEnableEventProcessor = UserLegalholdEnableEventProcessor(
        context: syncContext,
        userRepository: userRepository,
        userClientsRepository: userClientsRepository
    )

    private lazy var userLegalholdRequestEventProcessor = UserLegalholdRequestEventProcessor(
        repository: userRepository
    )

    private lazy var userPropertiesSetEventProcessor = UserPropertiesSetEventProcessor(
        repository: userRepository
    )

    private lazy var userPropertiesDeleteEventProcessor = UserPropertiesDeleteEventProcessor(
        repository: userRepository
    )

    private lazy var userPushRemoveEventProcessor = UserPushRemoveEventProcessor(
        repository: userRepository
    )

    private lazy var userUpdateEventProcessor = UserUpdateEventProcessor(
        repository: userRepository
    )

    private lazy var teamDeleteEventProcessor = TeamDeleteEventProcessor(
        context: syncContext
    )

    private lazy var teamMemberLeaveEventProcessor = TeamMemberLeaveEventProcessor(
        repository: teamRepository
    )

    private lazy var teamMemberUpdateEventProcessor = TeamMemberUpdateEventProcessor(
        repository: teamRepository
    )

    private lazy var updateEventProcessor: UpdateEventProcessor = {
        let conversationEventProcessor = ConversationEventProcessor(
            accessUpdateEventProcessor: conversationAccessUpdateEventProcessor,
            createEventProcessor: conversationCreateEventProcessor,
            deleteEventProcessor: conversationDeleteEventProcessor,
            memberJoinEventProcessor: conversationMemberJoinEventProcessor,
            memberLeaveEventProcessor: conversationMemberLeaveEventProcessor,
            memberUpdateEventProcessor: conversationMemberUpdateEventProcessor,
            messageTimerUpdateEventProcessor: conversationMessageTimerUpdateEventProcessor,
            mlsMessageAddEventProcessor: conversationMLSMessageAddEventProcessor,
            mlsWelcomeEventProcessor: conversationMLSWelcomeEventProcessor,
            proteusMessageAddEventProcessor: conversationProteusMessageAddEventProcessor,
            protocolUpdateEventProcessor: conversationProtocolUpdateEventProcessor,
            receiptModeUpdateEventProcessor: conversationReceiptModeUpdateEventProcessor,
            renameEventProcessor: conversationRenameEventProcessor,
            typingEventProcessor: conversationTypingEventProcessor
        )

        let featureConfigEventProcessor = FeatureConfigEventProcessor(
            updateEventProcessor: featureConfigUpdateEventProcessor
        )

        let federationEventProcessor = FederationEventProcessor(
            connectionRemovedEventProcessor: federationConnectionRemovedEventProcessor,
            deleteEventProcessor: federationDeleteEventProcessor
        )

        let userEventProcessor = UserEventProcessor(
            clientAddEventProcessor: userClientAddEventProcessor,
            clientRemoveEventProcessor: userClientRemoveEventProcessor,
            connectionEventProcessor: userConnectionEventProcessor,
            deleteEventProcessor: userDeleteEventProcessor,
            legalholdDisableEventProcessor: userLegalholdDisableEventProcessor,
            legalholdEnableEventProcessor: userLegalholdEnableEventProcessor,
            legalholdRequestEventProcessor: userLegalholdRequestEventProcessor,
            propertiesSetEventProcessor: userPropertiesSetEventProcessor,
            propertiesDeleteEventProcessor: userPropertiesDeleteEventProcessor,
            pushRemoveEventProcessor: userPushRemoveEventProcessor,
            updateEventProcessor: userUpdateEventProcessor
        )

        let teamEventProcessor = TeamEventProcessor(
            deleteEventProcessor: teamDeleteEventProcessor,
            memberLeaveEventProcessor: teamMemberLeaveEventProcessor,
            memberUpdateEventProcessor: teamMemberUpdateEventProcessor
        )

        return UpdateEventProcessor(
            conversationEventProcessor: conversationEventProcessor,
            featureConfigEventProcessor: featureConfigEventProcessor,
            federationEventProcessor: federationEventProcessor,
            userEventProcessor: userEventProcessor,
            teamEventProcessor: teamEventProcessor
        )
    }()

    // MARK: - Other

    private lazy var conversationProtobufMessageProcessor = ConversationProtobufMessageProcessor(
        messageLocalStore: messageLocalStore,
        conversationLocalStore: conversationLocalStore,
        userLocalStore: userLocalStore
    )

    private lazy var oneOnOneResolver = OneOnOneResolver(
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

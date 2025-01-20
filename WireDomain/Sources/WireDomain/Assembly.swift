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

import WireAPI
import WireDataModel
import WireFoundation
import NeedleFoundation

public typealias RootComponent = BootstrapComponent

public final class Assembly: RootComponent {

    private let userID: UUID
    private let clientID: String
    private let teamID: UUID
    private let context: NSManagedObjectContext
    private let sharedUserDefaults: UserDefaults
    private let proteusService: any ProteusServiceInterface
    private let apiService: any APIServiceProtocol
    private let apiVersion: WireAPI.APIVersion
    private let mlsService: MLSServiceInterface
    private let mlsProvider: MLSProvider
    private let mlsDecryptionService: any MLSDecryptionServiceInterface
    let pushChannel: any PushChannelProtocol
    let backendEnvironmentProvider: BackendEnvironmentProvider

    init(
        userID: UUID,
        clientID: String,
        teamID: UUID,
        context: NSManagedObjectContext,
        sharedUserDefaults: UserDefaults,
        proteusService: any ProteusServiceInterface,
        apiService: any APIServiceProtocol,
        apiVersion: WireAPI.APIVersion,
        pushChannel: any PushChannelProtocol,
        mlsService: any MLSServiceInterface,
        mlsDecryptionService: any MLSDecryptionServiceInterface,
        mlsProvider: MLSProvider,
        backendEnvironmentProvider: any BackendEnvironmentProvider
    ) {
        self.userID = userID
        self.clientID = clientID
        self.teamID = teamID
        self.context = context
        self.sharedUserDefaults = sharedUserDefaults
        self.proteusService = proteusService
        self.apiService = apiService
        self.apiVersion = apiVersion
        self.pushChannel = pushChannel
        self.backendEnvironmentProvider = backendEnvironmentProvider
        self.mlsService = mlsService
        self.mlsProvider = mlsProvider
        self.mlsDecryptionService = mlsDecryptionService
    }

    // MARK: - API

    lazy var updateEventsAPI = UpdateEventsAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)
    
    private lazy var usersAPI = UsersAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)
    
    private lazy var selfUserAPI = SelfUserAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)
    
    private lazy var userPropertiesAPI = UserPropertiesBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)
    
    private lazy var conversationsAPI = ConversationsAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)
    
    private lazy var teamsAPI = TeamsAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)

    // MARK: - Repositories
    
    private lazy var conversationLabelsRepository = ConversationLabelsRepository(
        userPropertiesAPI: userPropertiesAPI,
        conversationLabelsLocalStore: conversationLabelsLocalStore
    )
    
    private lazy var teamRepository = TeamRepository(
        selfTeamID: teamID,
        userRepository: userRepository,
        teamLocalStore: teamLocalStore,
        teamsAPI: teamsAPI
    )
    
    private lazy var conversationRepository = ConversationRepository(
        conversationsAPI: conversationsAPI,
        conversationsLocalStore: conversationsLocalStore,
        userRepository: userRepository,
        teamRepository: teamRepository,
        messageRepository: messageRepository,
        backendInfo: .init(domain: "", isFederationEnabled: true, isMLSEnabled: true),
        mlsProvider: mlsProvider
    )
    
    private lazy var userRepository = UserRepository(
        usersAPI: usersAPI,
        selfUserAPI: selfUserAPI,
        conversationLabelsRepository: conversationLabelsRepository,
        userLocalStore: userLocalStore
    )
    
    private lazy var messageRepository = MessageRepository(
        localStore: messagesLocalStore
    )
    
    // MARK: - Local stores
    
    private lazy var conversationLabelsLocalStore = ConversationLabelsLocalStore(
        context: context
    )
    
    private lazy var conversationsLocalStore = ConversationLocalStore(
        context: context,
        mlsService: mlsService,
        messageLocalStore: messagesLocalStore
    )
    
    private lazy var teamLocalStore = TeamLocalStore(
        context: context,
        userLocalStore: userLocalStore
    )

    lazy var userLocalStore: UserLocalStoreProtocol = UserLocalStore(
        context: context,
        conversationLocalStore: conversationsLocalStore
    )
    
    private lazy var messagesLocalStore = MessageLocalStore(
        context: context
    )

    lazy var updateEventsLocalStore: UpdateEventsLocalStoreProtocol = UpdateEventsLocalStore(
        context: context,
        userID: userID,
        sharedUserDefaults: sharedUserDefaults
    )
    
    private lazy var userClientsLocalStore = UserClientsLocalStore(
        context: context,
        userLocalStore: userLocalStore
    )
    
    // MARK: - Decryptors
    
    private lazy var proteusMessageDecryptor = ProteusMessageDecryptor(
        proteusService: proteusService,
        userClientsLocalStore: userClientsLocalStore,
        userRepository: userRepository
    )
    
    private lazy var mlsMessageDecryptor = MLSMessageDecryptor(
        mlsDecryptionService: mlsDecryptionService,
        mlsService: mlsService,
        conversationLocalStore: conversationsLocalStore
    )
    
    lazy var updateEventsDecryptor: UpdateEventDecryptorProtocol = UpdateEventDecryptor(
        proteusMessageDecryptor: proteusMessageDecryptor,
        mlsMessageDecryptor: mlsMessageDecryptor,
        messageRepository: messageRepository
    )
    
    func setupNotificationSession() {
        let session = NotificationSession(parent: self)
        NotificationService.notificationSession = session
    }

}

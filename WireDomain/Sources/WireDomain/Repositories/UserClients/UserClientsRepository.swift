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

public struct UserClientsRepository: UserClientsRepositoryProtocol {

    // MARK: - Properties

    private let userClientsAPI: any UserClientsAPI
    private let userRepository: any UserRepositoryProtocol
    private let userClientsLocalStore: any UserClientsLocalStoreProtocol

    // MARK: - Object lifecycle

    init(
        userClientsAPI: any UserClientsAPI,
        userRepository: any UserRepositoryProtocol,
        userClientsLocalStore: any UserClientsLocalStoreProtocol
    ) {
        self.userClientsAPI = userClientsAPI
        self.userRepository = userRepository
        self.userClientsLocalStore = userClientsLocalStore
    }

    // MARK: - Public

    public func fetchSelfClient() async -> WireDataModel.UserClient? {
        await userClientsLocalStore.fetchSelfClient()
    }

    public func fetchClient(
        id: String,
        forUser user: ZMUser,
        createIfNeeded: Bool
    ) async -> UserClient? {
        await userClientsLocalStore.fetchClient(
            id: id,
            forUser: user,
            createIfNeeded: createIfNeeded
        )
    }

    public func fetchOrCreateClient(
        id: String
    ) async throws -> (client: WireDataModel.UserClient, isNew: Bool) {
        await userClientsLocalStore.fetchOrCreateClient(
            id: id
        )
    }

    public func deleteClient(
        id: String
    ) async {
        await userClientsLocalStore.deleteClient(id: id)
    }

    public func pullSelfClients() async throws {
        let remoteSelfClients = try await userClientsAPI.getSelfClients()

        for remoteSelfClient in remoteSelfClients {
            let localUserClient = await userClientsLocalStore.fetchOrCreateClient(
                id: remoteSelfClient.id
            )

            try await updateClient(
                id: remoteSelfClient.id,
                from: remoteSelfClient,
                isNewClient: localUserClient.isNew
            )
        }

        let deletedSelfClientsIDs = await userClientsLocalStore.deletedSelfClients(
            newClients: remoteSelfClients.map(\.id)
        )

        for deletedSelfClientID in deletedSelfClientsIDs {
            await userClientsLocalStore.deleteClient(id: deletedSelfClientID)
        }
    }

    public func updateClient(
        id: String,
        from remoteClient: WireAPI.SelfUserClient,
        isNewClient: Bool
    ) async throws {
        await userClientsLocalStore.updateClient(
            id: id,
            isNewClient: isNewClient,
            userClientInfo: remoteClient.toDomainModel()
        )
    }

    public func allSelfUserClientsAreActiveMLSClients() async -> Bool {
        await userClientsLocalStore.allSelfUserClientsAreActiveMLSClients()
    }

}







//public extension UserClientsRepository {
//    
//    static func make(apiService: any APIServiceProtocol,
//                     apiVersion: WireAPI.APIVersion,
//                     context: NSManagedObjectContext) -> UserClientsRepositoryProtocol {
//        
//        let userClientsAPI = UserClientsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
//        let usersAPI = UsersAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
//        let selfUserAPI = SelfUserAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
//        let userPropertiesAPI = UserPropertiesBuilder(apiService: apiService).makeAPI(for: apiVersion)
//        
//        
//        let conversationLabelsLocalStore = ConversationLabelsLocalStore(context: context)
//
//        let conversationRepository = ConversationRepository(conversationsAPI: <#T##any ConversationsAPI#>,
//                                                            conversationsLocalStore: any ConversationLocalStoreProtocol,
//                                                            userRepository: <#T##any UserRepositoryProtocol#>,
//                                                            teamRepository: <#T##any TeamRepositoryProtocol#>,
//                                                            messageRepository: <#T##any MessageRepositoryProtocol#>,
//                                                            backendInfo: <#T##ConversationRepository.BackendInfo#>,
//                                                            mlsProvider: <#T##MLSProvider#>)
//        
//        let conversationLabelsRepository = ConversationLabelsRepository(userPropertiesAPI: userPropertiesAPI, conversationLabelsLocalStore: conversationLabelsLocalStore)
//        
//        
//        let userRepository = UserRepository(usersAPI: usersAPI,
//                                            selfUserAPI: selfUserAPI,
//                                            conversationLabelsRepository: conversationLabelsRepository, conversationRepository: <#T##any ConversationRepositoryProtocol#>, userLocalStore: <#T##any UserLocalStoreProtocol#>)
//        let userClientsLocalStore = UserClientsLocalStore(context: context, userLocalStore: )
//      
//        return UserClientsRepository(userClientsAPI: userClientsAPI,
//                                     userRepository: userRepository,
//                                     userClientsLocalStore: userClientsLocalStore)
//    }
//}

//public extension SupportedProtocolsHelper {
//    
//    public static func make(apiService: any APIServiceProtocol, apiVersion: WireAPI.APIVersion, context: NSManagedObjectContext) -> SupportedProtocolsHelper {
//        
//        let userClientsRepository = UserClientsRepository.make(apiService: apiService, apiVersion: apiVersion, context: context)
//        
//        let featureConfigRepository = FeatureConfigRepository(
//            featureConfigsAPI: FeatureConfigsAPIBuilder(apiService: apiService).makeAPI(for: apiVersion),
//            featureConfigLocalStore: FeatureConfigLocalStore(context: context)
//        )
//        
//        
//        return SupportedProtocolsHelper(featureConfigRepository: featureConfigRepository,
//                                 userClientsRepository: <#T##any UserClientsRepositoryProtocol#>)
//    }
//}

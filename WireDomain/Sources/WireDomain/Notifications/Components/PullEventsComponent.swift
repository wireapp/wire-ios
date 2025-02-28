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

import NeedleFoundation
import WireAPI
import WireDataModel
import WireFoundation

protocol PullEventsDependency: Dependency {
    var userID: UUID { get }
    var coreData: CoreDataStack { get }
    var cookieStorage: any CookieStorageProtocol { get }
    var selectedAccount: Account { get }
    var applicationContainer: URL { get }
    var applicationIdentifier: String { get }
    var messageLocalStore: any MessageLocalStoreProtocol { get }
    var userLocalStore: any UserLocalStoreProtocol { get }
}

protocol PullEventsServiceProvider {
    func pullEventsService(
        selfUserID: UUID,
        selfClientID: String
    ) async -> any PullEventsServiceProtocol
}

/// Provides sync objects.
final class PullEventsComponent: Component<PullEventsDependency>, PullEventsServiceProvider {
    
    func pullEventsService(
        selfUserID: UUID,
        selfClientID: String
    ) async -> any PullEventsServiceProtocol {
        
        let pullEventsSync = await pullEventsSync(
            selfUserID: selfUserID,
            selfClientID: selfClientID
        )
        
        return PullEventsService(
            coreData: dependency.coreData,
            userClientsLocalStore: userClientsLocalStore,
            updateEventsLocalStore: updateEventsLocalStore,
            eventsSync: pullEventsSync,
            generateNotificationProvider: generateNotificationComponent
        )
    }
    
    // MARK: - Children
    
    var generateNotificationComponent: GenerateNotificationComponent {
        GenerateNotificationComponent(parent: self)
    }

}

extension PullEventsComponent {
    public var conversationLocalStore: any ConversationLocalStoreProtocol {
        ConversationLocalStore(
            context: dependency.coreData.syncContext,
            mlsService: nil,
            messageLocalStore: dependency.messageLocalStore
        )
    }
    
    private func pullEventsSync(
        selfUserID: UUID,
        selfClientID: String
    ) async -> any PullUpdateEventsSyncProtocol {
        let updateEventsAPI = await APIFactory.updateEventsAPI(
            cookieStorage: dependency.cookieStorage,
            selfClientID: selfClientID,
            applicationIdentifier: dependency.applicationIdentifier
        )
        
        let updateEventDecryptor = updateEventDecryptor(
            selfUserID: selfUserID
        )

        return PullUpdateEventsSync(
            selfClientID: selfClientID,
            api: updateEventsAPI,
            store: updateEventsLocalStore,
            decryptor: updateEventDecryptor
        )
    }
    
    private func updateEventDecryptor(
        selfUserID: UUID
    ) -> any UpdateEventDecryptorProtocol {
        let proteusMessageDecryptor = proteusMessageDecryptor(
            selfUserID: selfUserID
        )
        let mlsMessageDecryptor = mlsMessageDecryptor(
            selfUserID: selfUserID
        )
        
        return UpdateEventDecryptor(
            proteusMessageDecryptor: proteusMessageDecryptor,
            mlsMessageDecryptor: mlsMessageDecryptor,
            messageLocalStore: dependency.messageLocalStore
        )
    }
    
    private func coreCryptoProvider(
        selfUserID: UUID
    ) -> any CoreCryptoProviderProtocol {
        CoreCryptoProvider(
            selfUserID: selfUserID,
            sharedContainerURL: dependency.applicationContainer,
            accountDirectory: accountContainer,
            syncContext: dependency.coreData.syncContext,
            cryptoboxMigrationManager: CryptoboxMigrationManager(),
            allowCreation: false
        )
    }
    
    private func proteusMessageDecryptor(
        selfUserID: UUID
    ) -> any ProteusMessageDecryptorProtocol {
        let coreData = dependency.coreData
        let coreCryptoProvider = coreCryptoProvider(
            selfUserID: selfUserID
        )
        
        let userClientsLocalStore = UserClientsLocalStore(context: coreData.syncContext)
        let proteusService = ProteusService(coreCryptoProvider: coreCryptoProvider)
        
        return ProteusMessageDecryptor(
            proteusService: proteusService,
            userClientsLocalStore: userClientsLocalStore,
            userLocalStore: dependency.userLocalStore
        )
    }
    
    private var featureRepository: any FeatureRepositoryInterface {
        FeatureRepository(context: dependency.coreData.syncContext)
    }
    
    private var updateEventsLocalStore: any UpdateEventsLocalStoreProtocol {
        UpdateEventsLocalStore(
            context: dependency.coreData.syncContext,
            userID: dependency.userID,
            sharedUserDefaults: .standard
        )
    }
    
    private var userClientsLocalStore: any UserClientsLocalStoreProtocol {
        UserClientsLocalStore(
            context: dependency.coreData.syncContext
        )
    }
    
    private func mlsMessageDecryptor(
        selfUserID: UUID
    ) -> any MLSMessageDecryptorProtocol {
        let coreData = dependency.coreData
        let coreCryptoProvider = coreCryptoProvider(
            selfUserID: selfUserID
        )
        
        let commitSender = CommitSender(
            coreCryptoProvider: coreCryptoProvider,
            notificationContext: coreData.syncContext.notificationContext
        )
        
        let mlsActionExecutor = MLSActionExecutor(
            coreCryptoProvider: coreCryptoProvider,
            commitSender: commitSender,
            featureRepository: featureRepository
        )
        
        let mlsDecryptionService = MLSDecryptionService(
            context: coreData.syncContext,
            mlsActionExecutor: mlsActionExecutor
        )
        
        return MLSMessageDecryptor(
            mlsDecryptionService: mlsDecryptionService,
            conversationLocalStore: conversationLocalStore
        )
    }
    
    private var accountContainer: URL {
        CoreDataStack.accountDataFolder(
            accountIdentifier: dependency.userID,
            applicationContainer: dependency.applicationContainer
        )
    }
}

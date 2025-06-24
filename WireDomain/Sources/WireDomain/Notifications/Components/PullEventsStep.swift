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
import WireDataModel
import WireFoundation
import WireNetwork
import WireNetworkInterface

protocol PullEventsDependency: Dependency {
    var userID: UUID { get }
    var backendEnvironment: BackendEnvironment2 { get }
    var minTLSVersion: WireNetwork.TLSVersion { get }
    var preferredAPIVersion: WireNetwork.APIVersion? { get }
    var coreData: CoreDataStack { get }
    var cookieStorage: any CookieStorageProtocol { get }
    var messageLocalStore: any MessageLocalStoreProtocol { get }
    var userLocalStore: any UserLocalStoreProtocol { get }
    var applicationContainer: URL { get }
    var applicationIdentifier: String { get }
    var sharedUserDefaults: UserDefaults { get }
}

protocol PullEventsStepProtocol {
    func pullEvents() async throws
}

/// Provides sync objects.
final class PullEventsStep: Component<PullEventsDependency>, PullEventsStepProtocol {

    enum Failure: Error {
        case missingProxyCredentials
        case apiVersionNotFound
    }

    private var selfUserID: UUID
    private var selfClientID: String

    init(
        parent: any Scope,
        selfUserID: UUID,
        selfClientID: String
    ) {
        self.selfUserID = selfUserID
        self.selfClientID = selfClientID
        super.init(parent: parent)
    }

    func pullEvents() async throws {
        let pendingEventsSync = await PullPendingUpdateEventsSync(
            selfClientID: selfClientID,
            api: try updateEventsAPI,
            store: updateEventsLocalStore,
            journal: journal,
            decryptor: updateEventDecryptor,
            coreCryptoProvider: coreCryptoProvider
        )

        let pullEventsUseCase = PullEventsUseCase(
            pendingEventsSync: pendingEventsSync
        )

        let eventsStream = try await pullEventsUseCase.invoke()

        try await generateNotificationStep.generateNotification(
            eventsStream: eventsStream
        )
    }

    // MARK: - Children

    var generateNotificationStep: GenerateNotificationStep {
        GenerateNotificationStep(parent: self)
    }

}

extension PullEventsStep {
    public var conversationLocalStore: any ConversationLocalStoreProtocol {
        ConversationLocalStore(
            context: dependency.coreData.syncContext,
            mlsService: nil,
            messageLocalStore: dependency.messageLocalStore
        )
    }

    public var databaseSaver: any DatabaseSaverProtocol {
        DatabaseSaver(context: dependency.coreData.syncContext)
    }

    private var sharedUserDefaults: UserDefaults {
        UserDefaults(suiteName: dependency.applicationIdentifier)!
    }

    private var journal: Journal {
        Journal(
            userID: selfUserID,
            storage: sharedUserDefaults
        )
    }

    var updateEventDecryptor: any UpdateEventDecryptorProtocol {
        UpdateEventDecryptor(
            proteusMessageDecryptor: proteusMessageDecryptor,
            mlsMessageDecryptor: mlsMessageDecryptor,
            mlsService: nil,
            messageLocalStore: dependency.messageLocalStore
        )
    }

    var coreCryptoProvider: any CoreCryptoProviderProtocol {
        CoreCryptoProvider(
            selfUserID: selfUserID,
            sharedContainerURL: dependency.applicationContainer,
            accountDirectory: accountContainer,
            syncContext: dependency.coreData.syncContext,
            cryptoboxMigrationManager: CryptoboxMigrationManager(),
            coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManager(journal: journal),
            allowCreation: false
        )
    }

    var proteusMessageDecryptor: any ProteusMessageDecryptorProtocol {
        let coreData = dependency.coreData
        let userClientsLocalStore = UserClientsLocalStore(context: coreData.syncContext)
        let proteusService = ProteusService(coreCryptoProvider: coreCryptoProvider)

        return ProteusMessageDecryptor(
            proteusService: proteusService,
            userClientsLocalStore: userClientsLocalStore,
            userLocalStore: dependency.userLocalStore
        )
    }

    var featureRepository: any FeatureRepositoryInterface {
        FeatureRepository(context: dependency.coreData.syncContext)
    }

    var updateEventsLocalStore: any UpdateEventsLocalStoreProtocol {
        UpdateEventsLocalStore(
            eventContext: dependency.coreData.eventContext,
            syncContext: dependency.coreData.syncContext,
            userID: dependency.userID,
            sharedUserDefaults: dependency.sharedUserDefaults
        )
    }

    var userClientsLocalStore: any UserClientsLocalStoreProtocol {
        UserClientsLocalStore(
            context: dependency.coreData.syncContext
        )
    }

    var mlsMessageDecryptor: any MLSMessageDecryptorProtocol {
        let mlsActionExecutor = MLSActionExecutor(
            coreCryptoProvider: coreCryptoProvider,
            featureRepository: featureRepository
        )

        let mlsDecryptionService = MLSDecryptionService(
            context: dependency.coreData.syncContext,
            mlsActionExecutor: mlsActionExecutor
        )

        return MLSMessageDecryptor(
            mlsDecryptionService: mlsDecryptionService,
            conversationLocalStore: conversationLocalStore
        )
    }

    var accountContainer: URL {
        CoreDataStack.accountDataFolder(
            accountIdentifier: dependency.userID,
            applicationContainer: dependency.applicationContainer
        )
    }
}

extension PullEventsStep {

    var networkStack: NetworkStack {
        get async throws {
            NetworkStack(
                backendEnvironment: dependency.backendEnvironment,
                minTLSVersion: dependency.minTLSVersion,
                preferredAPIVersion: dependency.preferredAPIVersion,
                proxyCredentials: try await proxyCredentials
            )
        }
    }

    var updateEventsAPI: any UpdateEventsAPI {
        get async throws {
            try await networkStack.authenticatedRESTAPI(
                userID: dependency.userID,
                clientID: selfClientID,
                cookieEncryptionKey: UserDefaults.cookiesKey()
            )
            .updateEventsAPI()
        }
    }

    var apiVersion: WireNetwork.APIVersion {
        get throws {
            let key = "SelectedAPIVersion"
            let sharedUserDefaults = dependency.sharedUserDefaults

            guard sharedUserDefaults.object(forKey: key) != nil else {
                fatal("API version not found")
            }

            let storedValue = sharedUserDefaults.integer(forKey: key)
            let legacyAPIVersion = APIVersion(rawValue: Int32(storedValue))

            guard let legacyAPIVersion,
                  let apiVersion = WireNetwork.APIVersion(rawValue: UInt(legacyAPIVersion.rawValue)) else {
                throw Failure.apiVersionNotFound
            }

            return apiVersion
        }
    }

    private var proxyCredentials: WireNetworkInterface.ProxyCredentials? {
        get async throws {
            guard
                let proxy = dependency.backendEnvironment.config.proxyConfig,
                proxy.needsAuthentication
            else {
                return nil
            }

            let keychain = WireFoundation.Keychain()
            let usernameItemID = "proxy-\(proxy.host):\(proxy.port)-username"
            let passwordItemID = "proxy-\(proxy.host):\(proxy.port)-password"

            let genericPasswordKeychainItem: KeychainQueryItem = .itemClass(.genericPassword)
            let returningDataKeychainItem: KeychainQueryItem = .returningData(true)

            let proxyUsername: String? = try? await keychain.fetchItem(
                query: [
                    genericPasswordKeychainItem,
                    .account(usernameItemID),
                    returningDataKeychainItem
                ]
            )

            let proxyPassword: String? = try? await keychain.fetchItem(
                query: [
                    genericPasswordKeychainItem,
                    .account(passwordItemID),
                    returningDataKeychainItem
                ]
            )

            guard
                let proxyUsername,
                let proxyPassword
            else {
                throw Failure.missingProxyCredentials
            }

            return .init(
                username: proxyUsername,
                password: proxyPassword
            )
        }
    }

}

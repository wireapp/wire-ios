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
    private func pullEventsSync(
        selfUserID: UUID,
        selfClientID: String
    ) async -> any PullUpdateEventsSyncProtocol {
        let userID = dependency.userID
        
        let updateEventsAPI = await updateEventsAPI(
            selfClientID: selfClientID
        )
        
        let updateEventDecryptor = updateEventDecryptor(
            selfUserID: selfUserID
        )

        let pullUpdateEventsSync = PullUpdateEventsSync(
            selfClientID: selfClientID,
            api: updateEventsAPI,
            store: updateEventsLocalStore,
            decryptor: updateEventDecryptor
        )
    }
    
    private func updateEventDecryptor(
        selfUserID: UUID
    ) -> any UpdateEventDecryptorProtocol {
        let userID = dependency.userID
        let messageLocalStore = MessageLocalStore(context: dependency.coreData.syncContext)
        let proteusMessageDecryptor = proteusMessageDecryptor(
            selfUserID: selfUserID
        )
        let mlsMessageDecryptor = mlsMessageDecryptor(
            selfUserID: selfUserID
        )
        
        return UpdateEventDecryptor(
            proteusMessageDecryptor: proteusMessageDecryptor,
            mlsMessageDecryptor: mlsMessageDecryptor,
            messageLocalStore: messageLocalStore
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
        let userID = dependency.userID
        let featureRepository = FeatureRepository(context: coreData.syncContext)
        let coreCryptoProvider = coreCryptoProvider(
            selfUserID: selfUserID
        )
        
        let mlsService = mlsService(selfUserID: selfUserID)
        let messageLocalStore = MessageLocalStore(context: coreData.syncContext)
        let conversationLocalStore = ConversationLocalStore(
            context: coreData.syncContext,
            mlsService: mlsService,
            messageLocalStore: messageLocalStore
        )
        let userClientsLocalStore = UserClientsLocalStore(context: coreData.syncContext)
        let userLocalStore = UserLocalStore(
            context: coreData.syncContext,
            conversationLocalStore: conversationLocalStore
        )
        
        let proteusService = ProteusService(coreCryptoProvider: coreCryptoProvider)
        
        return ProteusMessageDecryptor(
            proteusService: proteusService,
            userClientsLocalStore: userClientsLocalStore,
            userLocalStore: userLocalStore
        )
    }
    
    func mlsService(
        selfUserID: UUID
    ) -> any MLSServiceInterface {
        let coreData = dependency.coreData
        let userID = dependency.userID
        let coreCryptoProvider = coreCryptoProvider(
            selfUserID: selfUserID
        )
        
        let featureRepository = FeatureRepository(context: coreData.syncContext)
        
        return MLSService(
            context: coreData.syncContext,
            notificationContext: coreData.syncContext.notificationContext,
            coreCryptoProvider: coreCryptoProvider,
            conversationEventProcessor: <#T##any ConversationEventProcessorProtocol#>,
            featureRepository: featureRepository,
            userDefaults: .standard,
            syncStatus: <#T##any SyncStatusProtocol#>,
            userID: userID
        )
    }
    
    private var updateEventsLocalStore: any UpdateEventsLocalStoreProtocol {
        UpdateEventsLocalStore(
            context: dependency.coreData.syncContext,
            userID: dependency.userID,
            sharedUserDefaults: .standard
        )
    }
    
    var userClientsLocalStore: any UserClientsLocalStoreProtocol {
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
        
        let featureRepository = FeatureRepository(context: coreData.syncContext)
        
        let mlsActionExecutor = MLSActionExecutor(
            coreCryptoProvider: coreCryptoProvider,
            commitSender: commitSender,
            featureRepository: featureRepository
        )
        
        let mlsDecryptionService = MLSDecryptionService(
            context: coreData.syncContext,
            mlsActionExecutor: mlsActionExecutor
        )
        
        let messageLocalStore = MessageLocalStore(context: coreData.syncContext)
        let mlsService = mlsService(selfUserID: selfUserID)
        
        let conversationLocalStore = ConversationLocalStore(
            context: coreData.syncContext,
            mlsService: mlsService,
            messageLocalStore: messageLocalStore
        )
        
        return MLSMessageDecryptor(
            mlsDecryptionService: mlsDecryptionService,
            conversationLocalStore: conversationLocalStore
        )
    }
    
    private func updateEventsAPI(
        selfClientID: String
    ) async -> any UpdateEventsAPI {
        let authenticationManager = await authenticationManager(
            selfClientID: selfClientID
        )
        
        let apiService = await APIService(
            networkService: networkService,
            authenticationManager: authenticationManager
        )

        return UpdateEventsAPIBuilder(
            apiService: apiService
        ).makeAPI(for: apiVersion)
    }
    
    func apiService(
        applicationIdentifier: String,
        selfClientID: String
    ) async -> any APIServiceProtocol {
        let authenticationManager = await authenticationManager(
            selfClientID: selfClientID
        )
        
        return await APIService(
            networkService: networkService,
            authenticationManager: authenticationManager
        )
    }
    
    var userDefaults: UserDefaults {
        let userDefaults = UserDefaults.standard
        userDefaults.addSuite(named: dependency.applicationIdentifier)
        return userDefaults
    }

    var apiVersion: WireAPI.APIVersion {
        let key = "SelectedAPIVersion"
        
        guard userDefaults.object(forKey: key) != nil else {
            fatalError("API version not found")
        }

        let storedValue = userDefaults.integer(forKey: key)
        let legacyAPIVersion = APIVersion(rawValue: Int32(storedValue))

        guard let legacyAPIVersion,
              let apiVersion = WireAPI.APIVersion(rawValue: UInt(legacyAPIVersion.rawValue)) else {
            return .v0
        }

        return apiVersion
    }

    var networkService: NetworkService {
        get async {
            let service = await NetworkService(
                baseURL: backendEnvironment.url,
                serverTrustValidator: ServerTrustValidator(
                    pinnedKeys: backendEnvironment.pinnedKeys
                )
            )

            let minTLSVersion = WireAPI.TLSVersion.minVersionFrom(minTLSVersion)
            let config = await URLSessionConfigurationFactory(
                minTLSVersion: minTLSVersion,
                proxySettings: proxySettings
            )
            
            let session = URLSession(
                configuration: config.makeRESTAPISessionConfiguration(),
                delegate: service,
                delegateQueue: nil
            )
            service.configure(with: session)

            return service
        }
    }

    func authenticationManager(
        selfClientID: String
    ) async -> any AuthenticationManagerProtocol {
        await AuthenticationManager(
            clientID: selfClientID,
            cookieStorage: dependency.cookieStorage,
            networkService: networkService
        )
    }

    private var minTLSVersion: String? {
        appMainBundle.infoForKey("MinTLSVersion")
    }
    
    private var accountContainer: URL {
        CoreDataStack.accountDataFolder(
            accountIdentifier: dependency.userID,
            applicationContainer: dependency.applicationContainer
        )
    }
    
    var backendEnvironment: WireAPI.BackendEnvironment {
        get async {
            BackendEnvironment(
                url: legacyBackendEnvironment.backendURL,
                webSocketURL: legacyBackendEnvironment.backendWSURL,
                pinnedKeys: legacyBackendEnvironment.trustData.map { trustData in
                    PinnedKey(
                        key: trustData.certificateKey,
                        hosts: trustData.hosts.map { host in
                            switch host.rule {
                            case .equals:
                                    .equals(host.value)
                            case .endsWith:
                                    .endsWith(host.value)
                            }
                        }
                    )
                },
                proxySettings: await proxySettings
            )
        }
    }

    var appMainBundle: Bundle {
        let mainBundle: Bundle

        let runningInExtension = Bundle.main.bundlePath.hasSuffix(".appex")

        if runningInExtension {
            let extensionBundleURL = Bundle.main.bundleURL
            let mainAppBundleURL = extensionBundleURL.deletingLastPathComponent().deletingLastPathComponent()
            guard let bundle = Bundle(url: mainAppBundleURL) else { fatalError("Failed to find main app bundle") }
            mainBundle = bundle
        } else {
            mainBundle = .main
        }
        return mainBundle
    }

    var proxySettings: ProxySettings? {
        get async {
            guard let proxy = legacyBackendEnvironment.proxy else { return nil }
            
            let keychain = WireFoundation.Keychain()
            let usernameItemID = "proxy-\(proxy.host):\(proxy.port)-username"
            let passwordItemID = "proxy-\(proxy.host):\(proxy.port)-password"
            
            let proxyUsername: String? = try? await keychain.fetchItem(
                query: [
                    .itemClass(.genericPassword),
                    .account(usernameItemID),
                    .returningData(true)
                ]
            )
            
            let proxyPassword: String? = try? await keychain.fetchItem(
                query: [
                    .itemClass(.genericPassword),
                    .account(passwordItemID),
                    .returningData(true)
                ]
            )
            
            if proxy.needsAuthentication {
                guard let proxyUsername, let proxyPassword else {
                    fatalInternal(
                        "Proxy needs authentication but credentials are missing"
                    )
                    
                    return nil
                }
                
                return .authenticated(
                    host: proxy.host,
                    port: proxy.port,
                    username: proxyUsername,
                    password: proxyPassword
                )
            } else {
                return .unauthenticated(
                    host: proxy.host,
                    port: proxy.port
                )
            }
        }
    }

    private var legacyBackendEnvironment: WireDataModel.BackendEnvironment {
        guard let backendEnvironmentTypeOverride else {
            fatalError()
        }

        let environmentType = EnvironmentType(
            stringValue: backendEnvironmentTypeOverride
        )

        guard let backendEnvironment = BackendEnvironment(
            userDefaults: userDefaults,
            configurationBundle: backendBundle,
            environmentType: environmentType
        ) else {
            fatalError("Malformed backend configuration data")
        }

        return backendEnvironment
    }

    private var backendEnvironmentTypeOverride: String? {
        userDefaults.string(forKey: "BackendEnvironmentTypeOverrideKey")
    }

    private var backendBundle: Bundle {
        guard let backendBundlePath = appMainBundle.path(
            forResource: "Backend",
            ofType: "bundle"
        ) else {
            fatalError("Could not find backend.bundle")
        }

        guard let bundle = Bundle(path: backendBundlePath) else {
            fatalError("Could not load backend.bundle")
        }

        return bundle
    }
}

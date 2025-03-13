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
    var sharedUserDefaults: UserDefaults { get }
}

protocol PullEventsServiceProvider {
    var userLocalStore: any UserLocalStoreProtocol { get}
    
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

        let pullPendingEventsSync = await pullEventsSync(
            selfUserID: selfUserID,
            selfClientID: selfClientID
        )

        return PullEventsService(
            userClientsLocalStore: userClientsLocalStore,
            updateEventsLocalStore: updateEventsLocalStore,
            pendingEventsSync: pullPendingEventsSync,
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
            messageLocalStore: messageLocalStore
        )
    }
    
    public var messageLocalStore: any MessageLocalStoreProtocol {
        MessageLocalStore(
            context: dependency.coreData.syncContext
        )
    }
    
    public var userLocalStore: any UserLocalStoreProtocol {
        UserLocalStore(
            context: dependency.coreData.syncContext,
            messageLocalStore: messageLocalStore
        )
    }

    private func pullEventsSync(
        selfUserID: UUID,
        selfClientID: String
    ) async -> any PullPendingUpdateEventsSyncProtocol {
        let updateEventsAPI = await updateEventsAPI(
            selfClientID: selfClientID
        )

        let updateEventDecryptor = updateEventDecryptor(
            selfUserID: selfUserID
        )

        return PullPendingUpdateEventsSync(
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
        let coreCryptoProvider = coreCryptoProvider(
            selfUserID: selfUserID
        )

        let userClientsLocalStore = UserClientsLocalStore(context: coreData.syncContext)
        let proteusService = ProteusService(coreCryptoProvider: coreCryptoProvider)

        return ProteusMessageDecryptor(
            proteusService: proteusService,
            userClientsLocalStore: userClientsLocalStore,
            userLocalStore: userLocalStore
        )
    }

    private var featureRepository: any FeatureRepositoryInterface {
        FeatureRepository(context: dependency.coreData.syncContext)
    }

    private var updateEventsLocalStore: any UpdateEventsLocalStoreProtocol {
        UpdateEventsLocalStore(
            context: dependency.coreData.eventContext,
            userID: dependency.userID,
            sharedUserDefaults: dependency.sharedUserDefaults
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

extension PullEventsComponent {
    func updateEventsAPI(
        selfClientID: String
    ) async -> any UpdateEventsAPI {
        let authenticationManager = await makeAuthenticationManager(
            selfClientID: selfClientID
        )

        let networkService = await makeNetworkService()

        let apiService = APIService(
            networkService: networkService,
            authenticationManager: authenticationManager
        )

        let apiVersion = makeApiVersion()

        return UpdateEventsAPIBuilder(
            apiService: apiService
        ).makeAPI(for: apiVersion)
    }

    func makeApiVersion() -> WireAPI.APIVersion {
        let key = "SelectedAPIVersion"
        let sharedUserDefaults = dependency.sharedUserDefaults

        guard sharedUserDefaults.object(forKey: key) != nil else {
            fatalError("API version not found")
        }

        let storedValue = sharedUserDefaults.integer(forKey: key)
        let legacyAPIVersion = APIVersion(rawValue: Int32(storedValue))

        guard let legacyAPIVersion,
              let apiVersion = WireAPI.APIVersion(rawValue: UInt(legacyAPIVersion.rawValue)) else {
            return .v0
        }

        return apiVersion
    }

    func makeAuthenticationManager(
        selfClientID: String
    ) async -> any AuthenticationManagerProtocol {
        await AuthenticationManager(
            clientID: selfClientID,
            cookieStorage: dependency.cookieStorage,
            networkService: makeNetworkService()
        )
    }

    func makeLegacyBackendEnvironment() -> WireDataModel.BackendEnvironment {
        let sharedUserDefaults = dependency.sharedUserDefaults
        let backendEnvironmentTypeOverride = sharedUserDefaults.string(forKey: "BackendEnvironmentTypeOverrideKey")

        let environmentType = if let backendEnvironmentTypeOverride {
            EnvironmentType(
                stringValue: backendEnvironmentTypeOverride
            )
        } else {
            EnvironmentType(userDefaults: sharedUserDefaults)
        }

        guard let backendEnvironment = BackendEnvironment(
            userDefaults: sharedUserDefaults,
            configurationBundle: backendBundle,
            environmentType: environmentType
        ) else {
            fatalError("Malformed backend configuration data")
        }

        return backendEnvironment
    }

    func makeBackendEnvironment() async -> WireAPI.BackendEnvironment {
        let legacyBackendEnvironment = makeLegacyBackendEnvironment()
        let proxySettings = await makeProxySettings()

        return BackendEnvironment(
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
            proxySettings: proxySettings
        )
    }

    func makeProxySettings() async -> ProxySettings? {
        let legacyBackendEnvironment = makeLegacyBackendEnvironment()
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

    func makeNetworkService() async -> NetworkService {
        let backendEnvironment = await makeBackendEnvironment()

        let service = NetworkService(
            baseURL: backendEnvironment.url,
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: backendEnvironment.pinnedKeys
            )
        )

        let minTLSVersion = WireAPI.TLSVersion.minVersionFrom(minTLSVersion)
        let config = await URLSessionConfigurationFactory(
            minTLSVersion: minTLSVersion,
            proxySettings: makeProxySettings()
        )

        let session = URLSession(
            configuration: config.makeRESTAPISessionConfiguration(),
            delegate: service,
            delegateQueue: nil
        )
        service.configure(with: session)

        return service
    }

    var minTLSVersion: String? {
        appMainBundle.infoForKey("MinTLSVersion")
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

    var backendBundle: Bundle {
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

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

    func pullEvents() async throws {
        let selfUser = await userLocalStore.selfUserInfo()

        guard let selfClientID = selfUser.clientId else {
            return
        }

        let selfUserID = selfUser.id

        let updateEventsAPI = try await updateEventsAPI(
            selfClientID: selfClientID
        )

        let updateEventDecryptor = updateEventDecryptor(
            selfUserID: selfUserID
        )

        let pendingEventsSync = PullPendingUpdateEventsSync(
            selfClientID: selfClientID,
            api: updateEventsAPI,
            store: updateEventsLocalStore,
            decryptor: updateEventDecryptor
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

extension PullEventsStep {
    func updateEventsAPI(
        selfClientID: String
    ) async throws -> any UpdateEventsAPI {
        let authenticationManager = try await makeAuthenticationManager(
            selfClientID: selfClientID
        )

        let networkService = try await makeNetworkService()

        let apiService = APIService(
            networkService: networkService,
            authenticationManager: authenticationManager
        )

        let apiVersion = try makeApiVersion()

        return UpdateEventsAPIBuilder(
            apiService: apiService
        ).makeAPI(for: apiVersion)
    }

    func makeApiVersion() throws -> WireAPI.APIVersion {
        let key = "SelectedAPIVersion"
        let sharedUserDefaults = dependency.sharedUserDefaults

        guard sharedUserDefaults.object(forKey: key) != nil else {
            fatal("API version not found")
        }

        let storedValue = sharedUserDefaults.integer(forKey: key)
        let legacyAPIVersion = APIVersion(rawValue: Int32(storedValue))

        guard let legacyAPIVersion,
              let apiVersion = WireAPI.APIVersion(rawValue: UInt(legacyAPIVersion.rawValue)) else {
            throw Failure.apiVersionNotFound
        }

        return apiVersion
    }

    func makeAuthenticationManager(
        selfClientID: String
    ) async throws -> any AuthenticationManagerProtocol {
        await AuthenticationManager(
            clientID: selfClientID,
            cookieStorage: dependency.cookieStorage,
            networkService: try makeNetworkService()
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
            fatal("Malformed backend configuration data")
        }

        return backendEnvironment
    }

    func makeBackendEnvironment() async throws -> WireAPI.BackendEnvironment {
        let legacyBackendEnvironment = makeLegacyBackendEnvironment()
        let proxySettings = try await makeProxySettings()

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

    func makeProxySettings() async throws -> WireAPI.ProxySettings? {
        let legacyBackendEnvironment = makeLegacyBackendEnvironment()
        guard let proxy = legacyBackendEnvironment.proxy else { return nil }

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

        if proxy.needsAuthentication {
            guard let proxyUsername, let proxyPassword else {
                throw Failure.missingProxyCredentials
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

    func makeNetworkService() async throws -> NetworkService {
        let backendEnvironment = try await makeBackendEnvironment()

        let service = NetworkService(
            baseURL: backendEnvironment.url,
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: backendEnvironment.pinnedKeys,
                currentDateProvider: .system
            )
        )

        let minTLSVersion = WireAPI.TLSVersion.minVersionFrom(minTLSVersion)
        let config = await URLSessionConfigurationFactory(
            minTLSVersion: minTLSVersion,
            proxySettings: try makeProxySettings()
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
            guard let bundle = Bundle(url: mainAppBundleURL) else { fatal("Failed to find main app bundle") }
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
            fatal("Could not find backend.bundle")
        }

        guard let bundle = Bundle(path: backendBundlePath) else {
            fatal("Could not load backend.bundle")
        }

        return bundle
    }
}

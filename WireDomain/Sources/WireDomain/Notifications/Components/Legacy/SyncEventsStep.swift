//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

// TODO: [WPB-19818] delete when multibackend is released

import NeedleFoundation
import WireDataModel
import WireFoundation
import WireLogging
import WireNetwork

protocol SyncEventsDependency: Dependency {
    var userID: UUID { get }
    var coreData: CoreDataStack { get }
    var cookieStorage: any CookieStorageProtocol { get }
    var messageLocalStore: any MessageLocalStoreProtocol { get }
    var userLocalStore: any UserLocalStoreProtocol { get }
    var applicationContainer: URL { get }
    var applicationIdentifier: String { get }
    var sharedUserDefaults: UserDefaults { get }
}

protocol SyncEventsStepProtocol {
    func pullEvents() async throws
}

/// Provides sync objects.
final class SyncEventsStep: Component<SyncEventsDependency>, SyncEventsStepProtocol {

    enum Failure: Error {
        case missingProxyCredentials
        case apiVersionNotFound
        case pushChannelAlreadyOpened
    }

    private var selfUserID: UUID {
        dependency.userID
    }

    private var selfClientID: String

    private let pushChannelCoordinator: AppExtensionPushChannelCoordinator

    init(
        parent: any Scope,
        selfClientID: String
    ) {
        self.selfClientID = selfClientID
        self.pushChannelCoordinator = AppExtensionPushChannelCoordinator(clientID: selfClientID)
        super.init(parent: parent)
    }

    private var currentTask: Task<Void, any Error>?

    func pullEvents() async throws {
        let pendingEventsSync = try await PullPendingUpdateEventsSyncV2(
            selfClientID: selfClientID,
            pushChannelAPI: pushChannelAPI,
            updateEventsStore: updateEventsLocalStore,
            journal: journal,
            decryptor: updateEventDecryptor,
            coreCryptoProvider: coreCryptoProvider
        )

        // make sure no pushChannel is open
        let pushChannelState = PushChannelState(
            sharedContainerURL: dependency.applicationContainer,
            clientID: selfClientID
        )
        do {
            try await pushChannelState.markAsOpen()
        } catch {
            throw Failure.pushChannelAlreadyOpened
        }

        Task { [weak self] in
            var request = await self?.pushChannelCoordinator.listenForYieldRequests()
            WireLogger.sync.debug("requested to cancel sync", attributes: .incrementalSyncV3, .newNSE)
            self?.currentTask?.cancel()
            request?.acknowledge()
            WireLogger.sync.debug("notified main App to resume sync", attributes: .incrementalSyncV3, .newNSE)
        }

        let useCase = SyncEventsUseCase(pendingEventsSync: pendingEventsSync)

        currentTask = Task {
            do {
                try Task.checkCancellation()
                try await useCase.invoke()
            } catch {
                // either we timeout during decrypting/storing events OR an issue with the sync
                // In both cases, we end up with a stream of notifications that has not been shown, so we need to
                // continue to show them
                WireLogger.sync.warn(
                    "syncing events via websocket: \(String(describing: error))",
                    attributes: .incrementalSyncV3, .newNSE
                )
                await pushChannelState.markAsClosed()
            }
        }
        try await currentTask?.value
        WireLogger.sync.debug("closing push channel")
        await pushChannelState.markAsClosed()

        try await generateNotificationStep.generateNotification(
            eventsStream: pendingEventsSync.stream
        )
    }

    // MARK: - Children

    var generateNotificationStep: GenerateNotificationStep {
        GenerateNotificationStep(parent: self)
    }
}

extension SyncEventsStep {

    var pushChannelService: PushChannelService {
        get async throws {
            try await PushChannelService(
                networkService: pushChannelNetworkService,
                authenticationManager: authenticationManager
            )
        }
    }

    public var pushChannelAPI: any PushChannelV2API {
        get async throws {
            try await PushChannelV2APIBuilder(pushChannelService: pushChannelService).makeAPI(for: apiVersion)
        }
    }

    public var conversationLocalStore: any ConversationLocalStoreProtocol {
        ConversationLocalStore(
            context: dependency.coreData.syncContext,
            mlsService: nil,
            messageLocalStore: dependency.messageLocalStore,
            localDomain: BackendInfo.domain,
            isFederationEnabled: BackendInfo.isFederationEnabled
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
            sharedUserDefaults: sharedUserDefaults,
            syncContext: dependency.coreData.syncContext,
            cryptoboxMigrationManager: CryptoboxMigrationManager(),
            coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManager(journal: journal),
            allowCreation: false,
            localDomain: BackendInfo.domain
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

    var featureRepository: any LegacyFeatureRepositoryInterface {
        LegacyFeatureRepository(context: dependency.coreData.syncContext)
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

extension SyncEventsStep {
    // TODO: [WPB-17284] Encapsulate objects in NetworkStack (similar to what's done in WireAuthentication) to build the UpdateEventsAPI.
    var updateEventsAPI: any UpdateEventsAPI {
        get async throws {
            let apiService = await APIService(
                networkService: try networkService,
                authenticationManager: try authenticationManager
            )

            return UpdateEventsAPIBuilder(
                apiService: apiService
            ).makeAPI(for: try apiVersion)
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

    var authenticationManager: any AuthenticationManagerProtocol {
        get async throws {
            await AuthenticationManager(
                clientID: selfClientID,
                cookieStorage: dependency.cookieStorage,
                networkService: try networkService,
                onAuthenticationFailure: {}
            )
        }
    }

    var legacyBackendEnvironment: WireDataModel.BackendEnvironment {
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

    var backendEnvironment: WireNetwork.BackendEnvironment {
        get async throws {
            BackendEnvironment(
                url: legacyBackendEnvironment.backendURL,
                webSocketURL: legacyBackendEnvironment.backendWSURL,
                blacklistURL: legacyBackendEnvironment.blackListURL,
                pinnedKeys: legacyBackendEnvironment.trustData.map { trustData in
                    PinnedKey(
                        key: trustData.certificateKey,
                        rawKey: trustData.rawCertificateKey,
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
                proxySettings: try await proxySettings
            )
        }
    }

    var proxySettings: WireNetwork.ProxySettings? {
        get async throws {
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
    }

    var serverTrustValidator: ServerTrustValidator {
        get async throws {
            ServerTrustValidator(
                pinnedKeys: try await backendEnvironment.pinnedKeys,
                currentDateProvider: .system
            )
        }
    }

    var pushChannelNetworkService: NetworkService {
        get async throws {
            let backendEnvironment = try await backendEnvironment

            let networkService = NetworkService(
                baseURL: backendEnvironment.webSocketURL,
                serverTrustValidator: try await serverTrustValidator
            )
            let minTLSVersion = WireNetwork.TLSVersion.minVersionFrom(minTLSVersion)
            let configFactory = await URLSessionConfigurationFactory(
                minTLSVersion: minTLSVersion,
                proxySettings: try proxySettings
            )
            let config = configFactory.makeWebSocketSessionConfiguration()
            let session = URLSession(
                configuration: config,
                delegate: networkService,
                delegateQueue: nil
            )
            networkService.configure(with: session)
            return networkService
        }
    }

    var networkService: NetworkService {
        get async throws {
            let backendEnvironment = try await backendEnvironment

            let service = NetworkService(
                baseURL: backendEnvironment.url,
                serverTrustValidator: try await serverTrustValidator
            )

            let minTLSVersion = WireNetwork.TLSVersion.minVersionFrom(minTLSVersion)
            let config = await URLSessionConfigurationFactory(
                minTLSVersion: minTLSVersion,
                proxySettings: try proxySettings
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

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
import WireNetwork

protocol PullEventsDependency: Dependency {
    var userID: UUID { get }
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

    private var selfUserID: UUID {
        dependency.userID
    }

    private var selfClientID: String

    init(
        parent: any Scope,
        selfClientID: String
    ) {
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

extension PullEventsStep {
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

    var networkService: NetworkService {
        get async throws {
            let backendEnvironment = try await backendEnvironment

            let service = NetworkService(
                baseURL: backendEnvironment.url,
                serverTrustValidator: ServerTrustValidator(
                    pinnedKeys: backendEnvironment.pinnedKeys,
                    currentDateProvider: .system
                )
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

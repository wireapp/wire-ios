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
import WireCrypto
import WireDataModel
import WireFoundation

struct APIFactory {

    private init() {}

    static func updateEventsAPI(
        cookieStorage: any CookieStorageProtocol,
        selfClientID: String,
        applicationIdentifier: String
    ) async -> any UpdateEventsAPI {
        let userDefaults = makeUserDefaults(
            applicationIdentifier: applicationIdentifier
        )

        let authenticationManager = await makeAuthenticationManager(
            cookieStorage: cookieStorage,
            userDefaults: userDefaults,
            selfClientID: selfClientID
        )

        let networkService = await makeNetworkService(userDefaults: userDefaults)

        let apiService = APIService(
            networkService: networkService,
            authenticationManager: authenticationManager
        )

        let apiVersion = makeApiVersion(userDefaults: userDefaults)

        return UpdateEventsAPIBuilder(
            apiService: apiService
        ).makeAPI(for: apiVersion)
    }

    private static func makeApiVersion(userDefaults: UserDefaults) -> WireAPI.APIVersion {
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

    private static func makeAuthenticationManager(
        cookieStorage: any CookieStorageProtocol,
        userDefaults: UserDefaults,
        selfClientID: String
    ) async -> any AuthenticationManagerProtocol {
        await AuthenticationManager(
            clientID: selfClientID,
            cookieStorage: cookieStorage,
            networkService: makeNetworkService(userDefaults: userDefaults)
        )
    }

    private static func makeLegacyBackendEnvironment(userDefaults: UserDefaults) -> WireDataModel.BackendEnvironment {
        let backendEnvironmentTypeOverride = userDefaults.string(forKey: "BackendEnvironmentTypeOverrideKey")

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

    private static func makeUserDefaults(applicationIdentifier: String) -> UserDefaults {
        let userDefaults = UserDefaults.standard
        userDefaults.addSuite(named: applicationIdentifier)
        return userDefaults
    }

    private static func makeBackendEnvironment(userDefaults: UserDefaults) async -> WireAPI.BackendEnvironment {
        let legacyBackendEnvironment = makeLegacyBackendEnvironment(userDefaults: userDefaults)
        let proxySettings = await makeProxySettings(userDefaults: userDefaults)

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

    private static func makeProxySettings(userDefaults: UserDefaults) async -> ProxySettings? {
        let legacyBackendEnvironment = makeLegacyBackendEnvironment(userDefaults: userDefaults)
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

    private static func makeNetworkService(
        userDefaults: UserDefaults
    ) async -> NetworkService {
        let backendEnvironment = await makeBackendEnvironment(userDefaults: userDefaults)

        let service = NetworkService(
            baseURL: backendEnvironment.url,
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: backendEnvironment.pinnedKeys
            )
        )

        let minTLSVersion = WireAPI.TLSVersion.minVersionFrom(minTLSVersion)
        let config = await URLSessionConfigurationFactory(
            minTLSVersion: minTLSVersion,
            proxySettings: makeProxySettings(userDefaults: userDefaults)
        )

        let session = URLSession(
            configuration: config.makeRESTAPISessionConfiguration(),
            delegate: service,
            delegateQueue: nil
        )
        service.configure(with: session)

        return service
    }

    private static var minTLSVersion: String? {
        appMainBundle.infoForKey("MinTLSVersion")
    }

    private static var appMainBundle: Bundle {
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

    private static var backendBundle: Bundle {
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

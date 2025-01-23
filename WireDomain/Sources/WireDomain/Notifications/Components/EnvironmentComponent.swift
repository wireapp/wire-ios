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
import WireAPI
import WireFoundation

protocol EnvironmentDependency: Dependency {
    var applicationIdentifier: String { get }
}

class EnvironmentComponent: Component<EnvironmentDependency> {
    
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
                    fatalInternal("Proxy needs authentication but credentials are missing")
                    return nil
                }

                return .authenticated(host: proxy.host, port: proxy.port, username: proxyUsername, password: proxyPassword)
            } else {
                return .unauthenticated(host: proxy.host, port: proxy.port)
            }
        }
    }
    
    // MARK: - Private
    
    private var legacyBackendEnvironment: WireDataModel.BackendEnvironment {
        guard let backendEnvironmentTypeOverride else {
            fatalError()
        }
        
        let environmentType = EnvironmentType(stringValue: backendEnvironmentTypeOverride)
        
        guard let backendEnvironment = BackendEnvironment(
            userDefaults: userDefaults,
            configurationBundle: backendBundle,
            environmentType: environmentType
        ) else {
            fatalError("Malformed backend configuration data")
        }
        
        return backendEnvironment
    }
    
    private var userDefaults: UserDefaults {
        let userDefaults = UserDefaults.standard
        userDefaults.addSuite(named: dependency.applicationIdentifier)
        return userDefaults
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

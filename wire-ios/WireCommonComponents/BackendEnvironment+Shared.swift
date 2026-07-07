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
import WireTransport
import WireLogging

public extension BackendEnvironment {

    static func reset() {
        if let loaded = BackendEnvironment.load() {
            BackendEnvironment.shared = loaded
        }
    }
    
    private static func load() -> BackendEnvironment? {
        let environmentType: EnvironmentType? = if let typeOverride = AutomationHelper.sharedHelper.backendEnvironmentTypeOverride() {
            EnvironmentType(stringValue: typeOverride)
        } else {
            // read from userDefaults first
            EnvironmentType(userDefaults: .applicationGroup)
        }

        if Bundle.backendBundle == nil && environmentType == nil {
            return BackendEnvironment.defaultNoBackend
        }
        
        let finalEnvironmentType: EnvironmentType
        if let environmentType {
            finalEnvironmentType = environmentType
        } else {
            WireLogger.environment.info("fallback to production environment", attributes: .safePublic)
            finalEnvironmentType = .production
        }
        
        guard let environment = BackendEnvironment(type: finalEnvironmentType) else {
            return nil
        }
        return environment
    }

    static let backendSwitchNotification = Notification.Name("backendEnvironmentSwitchNotification")
    static var shared: BackendEnvironment = {
        if let loaded = BackendEnvironment.load() {
            return loaded
        } else {
            fatalError("Malformed backend configuration data")
        }
    }() {
        didSet {
            AutomationHelper.sharedHelper.disableBackendTypeOverride()
            shared.save(in: .applicationGroup)
            NotificationCenter.default.post(name: backendSwitchNotification, object: shared)
            WireLogger.environment.debug("Shared backend environment did change to: \(shared.title)")
        }
    }

    convenience init?(type: EnvironmentType?) {        
        if let bundle = Bundle.backendBundle {
            self.init(
                userDefaults: .applicationGroupCombinedWithStandard,
                configurationBundle: bundle,
                environmentType: type
            )
        } else {
            self.init(userDefaults: .applicationGroupCombinedWithStandard)
        }
    }

    static var defaultNoBackend = BackendEnvironment(title: "No default backend", trustData: [], environmentType: .production, endpoints: NoBackendEndpointsProvider(), proxySettings: nil, certificateTrust: NoBackendTrustProvider(), supportEmail: nil)
}

class NoBackendTrustProvider: NSObject, BackendTrustProvider {
    func verifyServerTrust(trust: SecTrust, host: String?) -> Bool {
        return false
    }
    
    var bundleIdentifier: String = "com.wire.no-default-backend"
}

class NoBackendEndpointsProvider: NSObject, BackendEndpointsProvider {
    var backendURL: URL
    
    var backendWSURL: URL
    
    var blackListURL: URL
    
    var teamsURL: URL
    
    var accountsURL: URL
    
    var websiteURL: URL
    
    var countlyURL: URL?
    
    override init() {
        self.websiteURL = URL(string: "https://example.com")!
        self.backendURL = URL(string: "https://example.com")!
        self.backendWSURL = URL(string: "wss://example.com")!
        self.blackListURL = URL(string: "https://example.com")!
        self.teamsURL = URL(string: "https://example.com")!
        self.accountsURL = URL(string: "https://example.com")!
    }
}

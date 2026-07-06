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

private let zmsLog = ZMSLog(tag: "backend-environment")

public extension BackendEnvironment {
    static let backendSwitchNotification = Notification.Name("backendEnvironmentSwitchNotification")
    static var shared: BackendEnvironment = {
        let environmentType = if let typeOverride = AutomationHelper.sharedHelper.backendEnvironmentTypeOverride() {
            EnvironmentType(stringValue: typeOverride)
        } else {
            // read from userDefaults first
            EnvironmentType(userDefaults: .applicationGroup)
        }

        guard let bundle = Bundle.backendBundle else {
            return BackendEnvironment.defaultNoBackend
        }
        
        guard let environment = BackendEnvironment(type: environmentType) else {
            fatalError("Malformed backend configuration data")
        }
        return environment
    }() {
        didSet {
            AutomationHelper.sharedHelper.disableBackendTypeOverride()
            shared.save(in: .applicationGroup)
            NotificationCenter.default.post(name: backendSwitchNotification, object: shared)
            zmsLog.debug("Shared backend environment did change to: \(shared.title)")
        }
    }

    convenience init?(type: EnvironmentType?) {
        
        guard let bundle = Bundle.backendBundle else {
            return nil
        }
        
        self.init(
            userDefaults: .applicationGroupCombinedWithStandard,
            configurationBundle: bundle,
            environmentType: type
        )
    }

    static var defaultNoBackend = BackendEnvironment(title: "No default backend", trustData: [], environmentType: .production, endpoints: NoBackendEndpointsProvider(), proxySettings: nil, certificateTrust: NoBackendTrustProvider())
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

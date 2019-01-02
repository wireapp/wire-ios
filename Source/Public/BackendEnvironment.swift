//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

let log = ZMSLog(tag: "backend-environment")

@objc public enum EnvironmentType: Int {
    case production
    case staging

    var stringValue: String {
        switch self {
        case .production:
            return "production"
        case .staging:
            return "staging"
        }
    }

    init(stringValue: String) {
        switch stringValue {
        case EnvironmentType.staging.stringValue:
            self = .staging
        default:
            self = .production
        }
    }

    public init(userDefaults: UserDefaults) {
        if let value = userDefaults.string(forKey: "ZMBackendEnvironmentType") {
            self.init(stringValue: value)
        } else {
            self = .production
        }
    }
}

public class BackendEnvironment: NSObject {
    let endpoints: BackendEndpointsProvider
    let certificateTrust: BackendTrustProvider
    
    init(endpoints: BackendEndpointsProvider, certificateTrust: BackendTrustProvider) {
        self.endpoints = endpoints
        self.certificateTrust = certificateTrust
    }
    
    // Will try to deserialize backend environment from .json files inside configurationBundle.
    public static func from(environmentType: EnvironmentType, configurationBundle: Bundle) -> BackendEnvironment? {        
        struct SerializedData: Decodable {
            let endpoints: BackendEndpoints
            let pinnedKeys: [TrustData]?
        }

        guard let path = configurationBundle.path(forResource: environmentType.stringValue, ofType: "json") else {
            log.error("Could not find \(environmentType.stringValue).json inside bundle \(configurationBundle)")
            return nil 
        }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { 
            log.error("Could not read \(environmentType.stringValue).json")
            return nil 
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            let backendData = try decoder.decode(SerializedData.self, from: data)
            let pinnedKeys = backendData.pinnedKeys ?? []
            let certificateTrust = ServerCertificateTrust(trustData: pinnedKeys)
            return BackendEnvironment(endpoints: backendData.endpoints, certificateTrust: certificateTrust) 
        } catch {
            log.error("Could decode information from \(environmentType.stringValue).json")
            return nil
        }
    }

}

extension BackendEnvironment: BackendEnvironmentProvider {
    public var backendURL: URL {
        return endpoints.backendURL
    }
    
    public var backendWSURL: URL {
        return endpoints.backendWSURL
    }
    
    public var blackListURL: URL {
        return endpoints.blackListURL
    }
    
    public var frontendURL: URL {
        return endpoints.frontendURL
    }
    
    public func verifyServerTrust(trust: SecTrust, host: String?) -> Bool {
        return certificateTrust.verifyServerTrust(trust: trust, host: host)
    }
}

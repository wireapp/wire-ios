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

// Swift migration notice: this protocol conforms to NSObjectProtocol only to be usable from Obj-C.
@objc public protocol BackendEnvironmentProvider: NSObjectProtocol {
    /// Backend base URL.
    var backendURL: URL { get }
    /// URL for SSL WebSocket connection.
    var backendWSURL: URL { get }
    /// URL for version blacklist file.
    var blackListURL: URL { get }
    /// Frontent URL, used to open the necessary web resources, like password reset.
    var frontendURL: URL { get }
}

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

// Swift migration notice: this class conforms to NSObject only to be usable from Obj-C.
@objcMembers
public class BackendEnvironment: NSObject, BackendEnvironmentProvider, Decodable {

    public let backendURL: URL
    public let backendWSURL: URL
    public let blackListURL: URL
    public let frontendURL: URL

    public init(backendURL: URL, backendWSURL: URL, blackListURL: URL, frontendURL: URL) {
        self.backendURL   = backendURL
        self.backendWSURL = backendWSURL
        self.blackListURL = blackListURL
        self.frontendURL  = frontendURL

        super.init()
    }

    // Will try to deserialize backend environment from .json files inside configurationBundle.
    public static func from(environmentType: EnvironmentType, configurationBundle: Bundle) -> Self? {
        guard let path = configurationBundle.path(forResource: environmentType.stringValue, ofType: "json") else { return nil }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return try? JSONDecoder().decode(self, from: data)
    }
}

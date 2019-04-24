//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension BackendEnvironment {

    private static let defaultsKey = "ZMBackendEnvironmentData"

    public convenience init?(userDefaults: UserDefaults, configurationBundle: Bundle) {
        let environmentType = EnvironmentType(userDefaults: userDefaults)
        switch environmentType {
        case .production, .staging:
            guard let path = configurationBundle.path(forResource: environmentType.stringValue, ofType: "json") else {
                Logging.backendEnvironment.error("Could not find configuration for \(environmentType.stringValue)")
                return nil
            }
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                Logging.backendEnvironment.error("Could not read \(path)")
                return nil
            }
            self.init(environmentType: environmentType, data: data)
        case .custom:
            guard let data = userDefaults.data(forKey: BackendEnvironment.defaultsKey) else {
                Logging.backendEnvironment.error("Could not read data from user defaults")
                return nil
            }
            self.init(environmentType: environmentType, data: data)
        }
    }
    
    public func save(in userDefaults: UserDefaults) {
        type.save(in: userDefaults)
        
        switch type {
        case .custom:
            struct SerializedData: Encodable {
                let title: String
                let endpoints: BackendEndpoints
            }
            
            let endpoints = BackendEndpoints(backendURL: self.endpoints.backendURL,
                                             backendWSURL: self.endpoints.backendWSURL,
                                             blackListURL: self.endpoints.blackListURL,
                                             teamsURL: self.endpoints.teamsURL,
                                             accountsURL: self.endpoints.accountsURL,
                                             websiteURL: self.endpoints.websiteURL)
            
            let data = SerializedData(title: title, endpoints: endpoints)
            let encoded = try? JSONEncoder().encode(data)
            userDefaults.set(encoded, forKey: BackendEnvironment.defaultsKey)
        default:
            break
        }
    }
}

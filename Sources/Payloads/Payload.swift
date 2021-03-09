// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

enum Payload {

    typealias UserClients = [Payload.UserClient]
    typealias UserClientByUserID = [String: UserClients]
    typealias UserClientByDomain = [String: UserClientByUserID]
    
    struct QualifiedUserID: Codable, Hashable {
        
        enum CodingKeys: String, CodingKey {
            case uuid = "id"
            case domain
        }
        
        let uuid: UUID
        let domain: String
    }
        
    struct Location: Codable {
        
        enum CodingKeys: String, CodingKey {
            case longitude = "lon"
            case latitide = "lat"
        }
        
        let longitude: Double
        let latitide: Double
    }
    
    struct UserClient: Codable {
        
        enum CodingKeys: String, CodingKey {
            case id
            case type
            case creationDate = "time"
            case label
            case location
            case deviceClass = "class"
            case deviceModel = "model"
        }
        
        let id: String
        let type: String?
        let creationDate: Date?
        let label: String?
        let location: Location?
        let deviceClass: String
        let deviceModel: String?

        init(id: String,
             deviceClass: String,
             type: String? = nil,
             creationDate: Date? = nil,
             label: String? = nil,
             location: Location? = nil,
             deviceModel: String? = nil) {
            self.id = id
            self.type = type
            self.creationDate = creationDate
            self.label = label
            self.location = location
            self.deviceClass = deviceClass
            self.deviceModel = deviceModel
        }
        
    }
}


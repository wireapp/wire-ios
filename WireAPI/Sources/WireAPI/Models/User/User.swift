//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

public enum UserAssetSize: String, Codable, Equatable {
    case preview
    case complete
}

public enum UserAssetType: String, Codable, Equatable {
    case image
}

public struct UserAsset: Codable, Equatable {
    let key: String
    let size: UserAssetSize
    let type: UserAssetType
}

public struct Service: Equatable {
    let id: String
    let provider: String
}

public enum SupportedProtocol: String, Equatable, Codable {
    case proteus
    case mls
}

public struct QualifiedID: Codable, Equatable {
    let uuid: UUID
    let domain: String

    enum CodingKeys: String, CodingKey {
        case uuid = "id"
        case domain
    }
}

public typealias UserID = QualifiedID

public struct User: Equatable {
    let id: UserID
    let name: String
    let handle: String?
    let teamID: UUID
    let accentID: Int
    let assets: [UserAsset]
    let deleted: Bool?
    let email: String?
    let expiresAt: String?
    let service: Service?
    let supportedProtocols: Set<SupportedProtocol>?
    let legalholdStatus: LegalholdStatus
}

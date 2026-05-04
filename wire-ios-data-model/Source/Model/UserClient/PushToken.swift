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

import Foundation

/// Token from Apple Push Notification Service, only supporting standard type
public struct PushToken: Equatable, Sendable {

    // MARK: - Properties

    public let deviceToken: Data
    public let appIdentifier: String
    public let transportType: String

    // MARK: - Life cycle

    public init(
        deviceToken: Data,
        appIdentifier: String,
        transportType: String
    ) {
        self.deviceToken = deviceToken
        self.appIdentifier = appIdentifier
        self.transportType = transportType
    }

    // MARK: - Methods

    public var deviceTokenString: String {
        deviceToken.zmHexEncodedString()
    }

}

// MARK: - Codable

extension PushToken: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.deviceToken = try container.decode(Data.self, forKey: .deviceToken)
        self.appIdentifier = try container.decode(String.self, forKey: .appIdentifier)
        self.transportType = try container.decode(String.self, forKey: .transportType)
    }

    enum CodingKeys: String, CodingKey {

        case deviceToken
        case appIdentifier
        case transportType

    }

}

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

/// Client device for a user.

public struct UserClient: Equatable, Identifiable, Codable {

    /// The unique id of the client.

    public let id: String

    /// The type of user client.

    public let type: UserClientType

    /// The date when the client was activated.

    public let activationDate: Date

    /// A label describing the client.

    public let label: String?

    /// A description of the client device model.

    public let model: String?

    /// The device class of the client.

    public let deviceClass: DeviceClass?

    /// When the client was last active.

    public let lastActiveDate: Date?

    /// The mls public keys for the client.

    public let mlsPublicKeys: MLSPublicKeys?

    /// The device cookie.

    public let cookie: String?

    /// The capabilities of the client.

    public let capabilities: [UserClientCapability]

    enum CodingKeys: String, CodingKey {

        case id
        case type
        case activationDate = "time"
        case label
        case model
        case deviceClass = "class"
        case lastActiveDate = "last_active"
        case mlsPublicKeys = "mls_public_keys"
        case cookie
        case capabilities

    }

}

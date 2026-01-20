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

/// Capabilities of a user client.

public enum UserClientCapability: Sendable {

    /// The client consents to being subject legalhold
    /// (directly or indirectly).

    case legalholdConsent

    /// The client is able to use new incremental sync from server using websocket acknowledgement (async notifications)

    case consumableNotifications

}

enum UserClientCapabilityV0: String, Codable, Sendable, ToAPIModelConvertible {
    case legalholdConsent = "legalhold-implicit-consent"
    case consumableNotifications = "consumable-notifications"

    func toAPIModel() -> UserClientCapability {
        switch self {
        case .legalholdConsent:
            .legalholdConsent
        case .consumableNotifications:
            .consumableNotifications
        }
    }
}

extension UserClientCapability: ToNetworkConvertible {
    func toNetworkModel() -> UserClientCapabilityV0 {
        switch self {
        case .legalholdConsent:
            .legalholdConsent
        case .consumableNotifications:
            .consumableNotifications
        }
    }
}

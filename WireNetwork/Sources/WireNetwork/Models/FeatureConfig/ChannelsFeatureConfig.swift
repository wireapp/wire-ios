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

/// A configuration for the *Channels* feature.

public struct ChannelsFeatureConfig: Equatable, Sendable {

    /// The feature's status.

    public let status: FeatureConfigStatus

    /// This determines which users can create channels

    public let allowedToCreateChannels: ChannelsPermission

    /// This determines which users can create public channels

    public let allowedToOpenChannels: ChannelsPermission

    public init(
        status: FeatureConfigStatus,
        allowedToCreateChannels: ChannelsPermission,
        allowedToOpenChannels: ChannelsPermission
    ) {
        self.status = status
        self.allowedToCreateChannels = allowedToCreateChannels
        self.allowedToOpenChannels = allowedToOpenChannels
    }
}

public enum ChannelsPermission: Sendable {

    /// Member, Admin, Owner
    case teamMembers
    /// Partner (a.k.a. external), Member, Admin, Owner
    case everyone
    /// Admin, Owner
    case admins
}

enum ChannelsPermissionV0: String, Sendable, Decodable, ToAPIModelConvertible {

    case teamMembers = "team-members"
    case everyone
    case admins

    func toAPIModel() -> ChannelsPermission {
        switch self {
        case .teamMembers:
            .teamMembers
        case .everyone:
            .everyone
        case .admins:
            .admins
        }
    }
}

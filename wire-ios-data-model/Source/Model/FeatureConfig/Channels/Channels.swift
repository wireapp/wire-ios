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

public extension Feature {

    struct Channels: Codable {

        // MARK: - Properties

        /// If `enabled` then the feature is available to the user.

        public let status: Status

        /// The configuration used to control how the feature behaves.

        public let config: Config

        // MARK: - Life cycle

        public init(status: Feature.Status = .disabled, config: Config = .init()) {
            self.status = status
            self.config = config
        }

        // MARK: - Types

        // WARNING: This config is encoded and stored in the database, so any changes
        // to it will require some migration code.

        public struct Config: Codable, Equatable {
            enum CodingKeys: String, CodingKey {
                case allowedToCreateChannels = "allowed_to_create_channels"
                case allowedToOpenChannels = "allowed_to_open_channels"
            }

            public let allowedToCreateChannels: ChannelsPermission
            public let allowedToOpenChannels: ChannelsPermission

            public init(
                allowedToCreateChannels: ChannelsPermission = .teamMembers,
                allowedToOpenChannels: ChannelsPermission = .teamMembers
            ) {
                self.allowedToCreateChannels = allowedToCreateChannels
                self.allowedToOpenChannels = allowedToOpenChannels
            }

            public init(from decoder: any Decoder) throws {
                let container: KeyedDecodingContainer<Feature.Channels.Config.CodingKeys> = try decoder
                    .container(keyedBy: Feature.Channels.Config.CodingKeys.self)

                self.allowedToCreateChannels = try container.decode(
                    ChannelsPermission.self,
                    forKey: .allowedToCreateChannels
                )
                self.allowedToOpenChannels = try container.decode(
                    ChannelsPermission.self,
                    forKey: .allowedToOpenChannels
                )
            }

            public enum ChannelsPermission: String, Codable {

                /// Member, Admin, Owner
                case teamMembers = "team-members"
                /// Partner (a.k.a. external), Member, Admin, Owner
                case everyone
                /// Admin, Owner
                case admins
            }
        }

    }

}

public extension Feature.Channels {

    var isEnabled: Bool {
        status == .enabled
    }

    func canCreateChannels(role: TeamRole) -> Bool {
        isEnabled && config.allowedToCreateChannels.contains(role)
    }

    func canOpenChannels(role: TeamRole) -> Bool {
        isEnabled && config.allowedToOpenChannels.contains(role)
    }

}

private extension Feature.Channels.Config.ChannelsPermission {

    func contains(_ role: TeamRole) -> Bool {
        switch self {
        case .everyone:
            role.isOne(of: .partner, .member, .admin, .owner)
        case .teamMembers:
            role.isOne(of: .member, .admin, .owner)
        case .admins:
            role.isOne(of: .admin, .owner)
        }
    }

}

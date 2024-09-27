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

extension Feature {
    public struct MLS: Codable {
        // MARK: Lifecycle

        public init(status: Feature.Status = .disabled, config: Config = .init()) {
            self.status = status
            self.config = config
        }

        // MARK: Public

        // MARK: - Types

        // WARNING: This config is encoded and stored in the database, so any changes
        // to it will require some migration code.

        public struct Config: Codable, Equatable {
            // MARK: Lifecycle

            public init(
                protocolToggleUsers: [UUID] = [],
                defaultProtocol: MessageProtocol = .proteus,
                allowedCipherSuites: [MLSCipherSuite] = [.MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519],
                defaultCipherSuite: MLSCipherSuite = .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
                supportedProtocols: Set<MessageProtocol> = []
            ) {
                self.protocolToggleUsers = protocolToggleUsers
                self.defaultProtocol = defaultProtocol
                self.allowedCipherSuites = allowedCipherSuites
                self.defaultCipherSuite = defaultCipherSuite
                self.supportedProtocols = supportedProtocols
            }

            public init(from decoder: any Decoder) throws {
                let container: KeyedDecodingContainer<Feature.MLS.Config.CodingKeys> = try decoder
                    .container(keyedBy: Feature.MLS.Config.CodingKeys.self)
                self.protocolToggleUsers = try container.decode(
                    [UUID].self,
                    forKey: Feature.MLS.Config.CodingKeys.protocolToggleUsers
                )
                self.defaultProtocol = try container.decode(
                    Feature.MLS.Config.MessageProtocol.self,
                    forKey: Feature.MLS.Config.CodingKeys.defaultProtocol
                )
                self.allowedCipherSuites = try container.decode(
                    [Feature.MLS.Config.MLSCipherSuite].self,
                    forKey: Feature.MLS.Config.CodingKeys.allowedCipherSuites
                )
                self.defaultCipherSuite = try container.decode(
                    Feature.MLS.Config.MLSCipherSuite.self,
                    forKey: Feature.MLS.Config.CodingKeys.defaultCipherSuite
                )

                // Supported protocols was added in v4 so we decode if present and provide a default if it's not there.
                self.supportedProtocols = try container.decodeIfPresent(
                    Set<Feature.MLS.Config.MessageProtocol>.self,
                    forKey: Feature.MLS.Config.CodingKeys.supportedProtocols
                ) ?? [.proteus]
            }

            // MARK: Public

            public enum MessageProtocol: String, Codable {
                case proteus
                case mls
                case mixed
            }

            @objc
            public enum MLSCipherSuite: Int, Codable {
                case MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519 = 1
                case MLS_128_DHKEMP256_AES128GCM_SHA256_P256 = 2
                case MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519 = 3
                case MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448 = 4
                case MLS_256_DHKEMP521_AES256GCM_SHA512_P521 = 5
                case MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448 = 6
                case MLS_256_DHKEMP384_AES256GCM_SHA384_P384 = 7
            }

            /// The ids of users who have the option to create new MLS groups.

            public let protocolToggleUsers: [UUID]

            /// The default protocol to use when creating a conversation.

            public let defaultProtocol: MessageProtocol

            /// The list of cipher suites that are allowed to be used with mls.

            public let allowedCipherSuites: [MLSCipherSuite]

            /// The default cipher suite used when creating a new MLS group.

            public let defaultCipherSuite: MLSCipherSuite

            /// The list of supported message protocols.

            public let supportedProtocols: Set<MessageProtocol>
        }

        // MARK: - Properties

        /// Whether MLS is availble to the user.

        public let status: Status

        /// The configuration used to control how the MLS behaves.

        public let config: Config
    }
}

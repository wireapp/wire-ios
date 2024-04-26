//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

    struct MLS: Codable {

        // MARK: - Properties

        /// Whether MLS is availble to the user.

        public let status: Status

        /// The configuration used to control how the MLS behaves.

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

            /// The ids of users who have the option to create new MLS groups.

            public let protocolToggleUsers: [UUID]

            /// The default protocol to use when creating a conversation.

            public let defaultProtocol: MessageProtocol

            /// The list of cipher suites that are allowed to be used with mls.

            public let allowedCipherSuites: [MLSCipherSuite]

            /// The default cipher suite used when creating a new MLS group.

            public let defaultCipherSuite: MLSCipherSuite

            /// The list of supported message protocols

            public let supportedProtocols: Set<MessageProtocol>

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

            public enum MessageProtocol: String, Codable {

                case proteus
                case mls
                case mixed

            }

            public enum MLSSignatureAlgorithm: String, CustomStringConvertible {
                case Ed25519
                case Ed448
                case P256
                case P384
                case P521

                public var description: String {
                    rawValue
                }
            }

            @objc
            public enum MLSCipherSuite: Int, Codable, CustomStringConvertible {

                case MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519 = 1
                case MLS_128_DHKEMP256_AES128GCM_SHA256_P256 = 2
                case MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519 = 3
                case MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448 = 4
                case MLS_256_DHKEMP521_AES256GCM_SHA512_P521 = 5
                case MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448 = 6
                case MLS_256_DHKEMP384_AES256GCM_SHA384_P384 = 7

                public var description: String {
                    switch self {

                    case .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519:
                        return "MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519"
                    case .MLS_128_DHKEMP256_AES128GCM_SHA256_P256:
                        return "MLS_128_DHKEMP256_AES128GCM_SHA256_P256"
                    case .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519:
                        return "MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519"
                    case .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448:
                        return "MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448"
                    case .MLS_256_DHKEMP521_AES256GCM_SHA512_P521:
                        return "MLS_256_DHKEMP521_AES256GCM_SHA512_P521"
                    case .MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448:
                        return "MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448"
                    case .MLS_256_DHKEMP384_AES256GCM_SHA384_P384:
                        return "MLS_256_DHKEMP384_AES256GCM_SHA384_P384"
                    }
                }

                public var signature: MLSSignatureAlgorithm {
                    return switch self {
                    case .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519, .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519:
                            .Ed25519
                    case .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448, .MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448:
                            .Ed448
                    case .MLS_128_DHKEMP256_AES128GCM_SHA256_P256:
                            .P256
                    case .MLS_256_DHKEMP384_AES256GCM_SHA384_P384:
                            .P384
                    case .MLS_256_DHKEMP521_AES256GCM_SHA512_P521:
                            .P521
                    }
                }
            }

        }

    }

}

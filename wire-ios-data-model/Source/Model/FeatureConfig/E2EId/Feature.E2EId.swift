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

public extension Feature {
    struct E2EI: Codable {
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
            public let acmeDiscoveryUrl: String?
            public let verificationExpiration: UInt
            public let crlProxy: String?
            public let useProxyOnMobile: Bool?

            public init(
                acmeDiscoveryUrl: String? = nil,
                verificationExpiration: UInt = 86400,
                crlProxy: String? = nil,
                useProxyOnMobile: Bool? = nil) {
                    self.acmeDiscoveryUrl = acmeDiscoveryUrl
                    self.verificationExpiration = verificationExpiration
                    self.crlProxy = crlProxy
                    self.useProxyOnMobile = useProxyOnMobile
                }
        }
    }
}

public extension Feature.E2EI {
    var isEnabled: Bool {
        return status == .enabled
    }
}

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
    public struct SelfDeletingMessages: Codable {
        // MARK: Lifecycle

        public init(status: Feature.Status = .enabled, config: Config = .init()) {
            self.status = status
            self.config = config
        }

        // MARK: Public

        // MARK: - Types

        // WARNING: This config is encoded and stored in the database, so any changes
        // to it will require some migration code.

        public struct Config: Codable, Equatable {
            // MARK: Lifecycle

            public init(enforcedTimeoutSeconds: UInt = 0) {
                self.enforcedTimeoutSeconds = enforcedTimeoutSeconds
            }

            // MARK: Public

            /// The number of seconds after which all enforced self-deleting messages
            /// will delete.
            ///
            /// A value of 0 indicates that the self-deleting messages are not mandatory.

            public let enforcedTimeoutSeconds: UInt
        }

        // MARK: - Properties

        /// If `enabled` then the feature is available to the user.

        public let status: Status

        /// The configuration used to control how the feature behaves.

        public let config: Config
    }
}

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
    public struct MLSMigration: Codable {
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
                startTime: Date? = nil,
                finaliseRegardlessAfter: Date? = nil
            ) {
                self.startTime = startTime
                self.finaliseRegardlessAfter = finaliseRegardlessAfter
            }

            // MARK: Public

            /// The starting time of the migration

            public let startTime: Date?

            /// The date until the migration has to finalise

            public let finaliseRegardlessAfter: Date?
        }

        // MARK: - Properties

        /// Whether MLS Migration is enabled.

        public let status: Status

        /// The configuration used to control how the MLS Migration behaves.

        public let config: Config
    }
}

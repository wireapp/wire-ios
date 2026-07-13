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

    struct PreventAdminlessGroups: Codable {

        public let status: Status
        public let config: Config

        public init(status: Feature.Status = .disabled, config: Config = .init()) {
            self.status = status
            self.config = config
        }

        // WARNING: This config is encoded and stored in the database, so any changes
        // to it will require some migration code.

        public struct Config: Codable, Equatable {

            public let promotionStrategy: PromotionStrategy
            public let deletionTimeout: Int
            public let reminderTimeouts: [Int]

            public init(
                promotionStrategy: PromotionStrategy = .alphabetical,
                deletionTimeout: Int = 0,
                reminderTimeouts: [Int] = []
            ) {
                self.promotionStrategy = promotionStrategy
                self.deletionTimeout = deletionTimeout
                self.reminderTimeouts = reminderTimeouts
            }

        }

        /// How the backend selects an admin candidate when automatic promotion is needed.
        public enum PromotionStrategy: String, Codable, Equatable {
            /// The eligible member whose display name comes first alphabetically is selected.
            case alphabetical
            /// A random eligible member is selected.
            case random
            /// All eligible members are selected.
            case all
        }

    }

}

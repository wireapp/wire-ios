////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

    struct MLSMigration: Codable {

        public let status: Status
        public let config: Config

        public init(
            status: Feature.Status = .disabled,
            config: Config = .init()
        ) {
            self.status = status
            self.config = config
        }

        public struct Config: Codable, Equatable {

            public let startTime: Date?
            public let finaliseRegardlessAfter: Date?

            public init(
                startTime: Date? = nil,
                finaliseRegardlessAfter: Date? = nil
            ) {
                self.startTime = startTime
                self.finaliseRegardlessAfter = finaliseRegardlessAfter
            }

        }

    }

}

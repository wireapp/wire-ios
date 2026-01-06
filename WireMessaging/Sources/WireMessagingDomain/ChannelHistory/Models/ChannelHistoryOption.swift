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

public enum ChannelHistoryOption: Equatable, Hashable, CaseIterable, Sendable, Identifiable {
    case off
    case oneDay
    case oneWeek
    case fourWeeks
    case unlimited
    case custom

    public var id: Self { self }

    public struct Custom: Equatable, Hashable, Sendable {
        public enum Unit: Equatable, Hashable, CaseIterable, Sendable, Identifiable {
            case days
            case weeks

            public var id: Self { self }
        }

        public init(
            unit: Unit = .days,
            value: Int = 10
        ) {
            self.unit = unit
            self.value = value
        }

        public var unit: Unit
        public var value: Int
    }
}

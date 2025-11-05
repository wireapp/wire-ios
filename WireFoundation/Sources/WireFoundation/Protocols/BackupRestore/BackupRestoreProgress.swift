//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// A simple container for storing a progress value (current/total) of a create or import backup operation.

public struct BackupProgress: Equatable, Sendable {

    public var current: Int
    public var total: Int

    public init(current: Int, total: Int) {
        self.current = current
        self.total = total
    }

}

// MARK: - Convenience

public extension BackupProgress {

    init(_ current: Int, _ total: Int) {
        self.init(current: current, total: total)
    }

}

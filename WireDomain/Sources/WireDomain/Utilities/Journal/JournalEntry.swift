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

/// An object that can be recorded into the user's
/// account journal. This can be used to keep track
/// of information to help make decisions at a later
/// date, such as whether some migration code needs
/// to be run.

public protocol JournalEntry: Codable {

    /// The unique name of the entry.

    static var uniqueName: String { get }

    /// The default entry to use an an intial value.

    static var defaultValue: Self { get }

}

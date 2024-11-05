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

/// Represents a folder in the system
public struct Folder: Equatable {
    /// Unique identifier for the folder. Can be nil for temporary folders
    public let identifier: UUID?

    /// Display name of the folder. Can be nil if not set
    public let name: String?

    /// The type of folder (favorite or regular)
    public let kind: FolderKind

    /// Creates a new folder instance
    /// - Parameters:
    ///   - identifier: Unique identifier for the folder. Can be nil for temporary folders
    ///   - name: Display name of the folder. Can be nil if not set
    ///   - kind: The type of folder
    public init(identifier: UUID?, name: String?, kind: FolderKind) {
        self.identifier = identifier
        self.name = name
        self.kind = kind
    }
}

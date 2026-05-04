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

/// Represents a conversation in the context of folder operations
public struct Conversation: Sendable {
    /// Unique identifier for the conversation
    public let identifier: UUID

    /// Identifier of the folder containing this conversation. Nil if not in any folder
    public let currentFolderIdentifier: UUID?

    /// Creates a new conversation instance
    /// - Parameters:
    ///   - identifier: Unique identifier for the conversation
    ///   - currentFolderIdentifier: Identifier of the containing folder, if any
    public init(identifier: UUID, currentFolderIdentifier: UUID?) {
        self.identifier = identifier
        self.currentFolderIdentifier = currentFolderIdentifier
    }
}

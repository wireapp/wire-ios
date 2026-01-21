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

/// The result of fetching a wire cells node.
public enum WireDriveFetchedNode: Sendable, Equatable {

    /// A `WireCellsNode` was found on the server.
    case node(WireDriveNode)

    /// No `WireCellsNode` was found on the server - it may have been deleted or the user might not have permission to
    /// access to it.
    case notFound

    public var isDeleted: Bool {
        switch self {
        case let .node(node):
            node.isRecycled
        case .notFound:
            true
        }
    }
}

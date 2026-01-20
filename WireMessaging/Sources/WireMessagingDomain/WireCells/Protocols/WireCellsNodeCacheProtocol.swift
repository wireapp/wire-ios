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

package import Foundation

/// A cached `WireCellsNode`.
///
/// A `nil` value indicates that the node was not found on the server, for example it may have been deleted. This is
/// different from the value never having been added to the cache.
public struct WireCellsNodeCacheItem: Equatable, Sendable {

    public let node: WireCellsNode?

    /// Whether the node is deleted or in the recycle bin.
    public var isDeletedOrRecycled: Bool {
        guard let node else { return true }
        return node.isRecycled
    }

}

// sourcery: AutoMockable
/// Caches `WireCellsNode` values.
package protocol WireCellsNodeCacheProtocol: Sendable {

    /// Sets a `WireCellsNodeCacheItem` for a given `nodeID`.
    func setItem(_ value: WireCellsNodeCacheItem, for nodeID: UUID) async

    /// Returns a `WireCellsNodeCacheItem` for a given `nodeID`, or `nil` if no value is cached.
    @MainActor
    func item(for nodeID: UUID) -> WireCellsNodeCacheItem?

}

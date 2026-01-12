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

/// Fetches cached and remote `WireCellsNodes` for a given node ID.
package struct WireCellsFetchNodeUseCase {

    private let repository: any WireCellsNodesRepositoryProtocol
    private let cache: any WireCellsNodeCacheProtocol

    package init(
        repository: any WireCellsNodesRepositoryProtocol,
        cache: any WireCellsNodeCacheProtocol
    ) {
        self.repository = repository
        self.cache = cache
    }

    /// Returns a stream that first yields a cached `WireCellsNode` if available, then fetches and yields the latest
    /// `WireCellsNode` from the server.
    package func invoke(nodeID: UUID) -> AsyncThrowingStream<WireCellsNode?, any Error> {
        AsyncThrowingStream { [repository, cache] continuation in
            Task {
                if let cached = await cache.item(for: nodeID) {
                    continuation.yield(cached.node)
                }

                do {
                    let latest = try await repository.getNode(id: nodeID)
                    await cache.setItem(WireCellsNodeCacheItem(node: latest), for: nodeID)
                    continuation.yield(latest)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

}

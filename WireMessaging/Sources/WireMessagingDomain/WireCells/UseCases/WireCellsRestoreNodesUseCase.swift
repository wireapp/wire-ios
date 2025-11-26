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

package import Foundation

package enum WireCellsRestoreNodesError: Error {
    case serverFailedToRestoreNodes
}

/// Restores `WireCellNodes`s on the server and deletes locally cached data.
/// Restoration means moving from the recycle bin back to where the node was originally before it was moved to the recycle bin.
package struct WireCellsRestoreNodesUseCase: WireCellsRestoreNodesUseCaseProtocol {

    private let repository: any WireCellsNodesRepositoryProtocol
    private let fileCache: any FileCache
    private let localAssetStore: any WireCellsLocalAssetStoreProtocol

    package init(
        repository: any WireCellsNodesRepositoryProtocol,
        fileCache: any FileCache,
        localAssetStore: any WireCellsLocalAssetStoreProtocol
    ) {
        self.repository = repository
        self.fileCache = fileCache
        self.localAssetStore = localAssetStore
    }

    package func invoke(nodeIDs: [UUID]) async throws {
        // First delete local assets (from the recycle bin) as this is less likely to fail then deleting nodes on server and local assets can
        // be re-downloaded if needed.
        for nodeID in nodeIDs {
            guard let localAsset = try await localAssetStore.asset(nodeID: nodeID) else { continue }

            // The file is just moved from the recycle bin but the download cache still needs to be cleared because the cache key changes.
            switch localAsset.downloadState {
            case let .downloaded(cacheKey):
                try await fileCache.deleteFile(forKey: cacheKey)
            default:
                break
            }
        }
        try await localAssetStore.deleteAssets(nodeIDs: nodeIDs)

        // Then restore nodes on the server.
        if try await repository.restoreNodes(nodeIDs: nodeIDs) == false {
            throw WireCellsRestoreNodesError.serverFailedToRestoreNodes
        }
    }

}

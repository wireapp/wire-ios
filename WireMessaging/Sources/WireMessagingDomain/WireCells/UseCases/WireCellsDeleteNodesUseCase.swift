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

package enum WireCellsDeleteNodesError: Error {
    case serverFailedToDeleteNodes
}

/// Deletes `WireCellNodes`s from both the server and locally cached data.
package struct WireCellsDeleteNodesUseCase: WireCellsDeleteNodesUseCaseProtocol {

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

    package func invoke(nodeIDs: [UUID], deletePermanently: Bool) async throws {
        // First delete local assets as this is less likely to fail then deleting nodes on server and local assets can
        // be re-downloaded if needed.
        for nodeID in nodeIDs {
            guard let localAsset = try await localAssetStore.asset(nodeID: nodeID) else { continue }

            switch localAsset.downloadState {
            case let .downloaded(cacheKey):
                try await fileCache.deleteFile(forKey: cacheKey)
            default:
                break
            }
        }
        try await localAssetStore.deleteAssets(nodeIDs: nodeIDs)

        // Then delete nodes from server.
        if try await repository.deleteNodes(nodeIDs: nodeIDs, permanently: deletePermanently) == false {
            throw WireCellsDeleteNodesError.serverFailedToDeleteNodes
        }
    }

}

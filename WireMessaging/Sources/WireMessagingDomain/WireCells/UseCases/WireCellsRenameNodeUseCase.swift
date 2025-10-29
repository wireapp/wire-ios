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

package enum WireCellsRenameNodeError: Error {
    case serverFailedToRenameNode
    case fileAlreadyExists
    case invalidPath
}

/// Renames a `WireCellNode` on the server.
package struct WireCellsRenameNodeUseCase: WireCellsRenameNodeUseCaseProtocol {

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

    package func invoke(
        nodeID: UUID,
        nodeFilepath: String,
        newFilename: String
    ) async throws {
        guard let url = URL(string: nodeFilepath) else {
            throw WireCellsRenameNodeError.invalidPath
        }

        let pathExtension = url.pathExtension
        let directory = url.deletingLastPathComponent()
        let targetPath = directory.appendingPathComponent("\(newFilename).\(pathExtension)")

        // Checks whether a file doesn't already exist at this path.
        let preCheckResult = try await repository.preCheck(
            path: targetPath.absoluteString,
            findAvailablePath: false
        )

        guard !preCheckResult.fileExists else {
            throw WireCellsRenameNodeError.fileAlreadyExists
        }

        // Renames the file.
        let didRenameFile = try await repository.renameNode(
            nodeID: nodeID,
            targetPath: targetPath.absoluteString
        )

        guard didRenameFile else {
            throw WireCellsRenameNodeError.serverFailedToRenameNode
        }

        // Updates the local asset with the new path.
        guard var modifiedAsset = try await localAssetStore.asset(nodeID: nodeID) else {
            return
        }

        modifiedAsset.path = targetPath.absoluteString

        try await localAssetStore.upsertAsset(modifiedAsset)
    }

}

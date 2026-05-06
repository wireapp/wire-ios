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

/// Moves a `WireDriveNode` on the server.
@MainActor
package struct WireDriveMoveNodeUseCase {

    private let nodesRepository: any WireDriveNodesRepositoryProtocol
    private let localAssetRepository: any WireDriveLocalAssetRepositoryProtocol

    package init(
        nodesRepository: any WireDriveNodesRepositoryProtocol,
        localAssetRepository: any WireDriveLocalAssetRepositoryProtocol
    ) {
        self.nodesRepository = nodesRepository
        self.localAssetRepository = localAssetRepository
    }

    /// Moves a `WireCellNode` on the server and updates the local asset with the new path.
    ///
    /// - Parameters:
    ///  - nodeID: The ID of the node to move.
    ///  - containerPath: The path of the new container (e.g folder or conversation) of the node.
    package func invoke(
        nodeID: UUID,
        containerPath: String
    ) async throws {
        try await nodesRepository.moveNode(nodeID: nodeID, newContainerPath: containerPath)

        if var localAsset = try localAssetRepository.asset(nodeID: nodeID),
           let node = try await nodesRepository.getNode(id: nodeID) {
            localAsset.path = node.path
            try localAssetRepository.updateAsset(localAsset)
        }

    }

}

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
package import Combine

package enum WireCellsRenameNodeError: Error {
    case serverFailedToRenameNode
    case fileAlreadyExists
    case invalidPath
}

package typealias WireCellsNodeRenameNotifier = WireCellsRenameNodeUseCase.WireCellsNodeRenameNotifier

/// Renames a `WireCellNode` on the server.
package struct WireCellsRenameNodeUseCase: WireCellsRenameNodeUseCaseProtocol {

    private let nodesRepository: any WireCellsNodesRepositoryProtocol
    private let localAssetsRepository: any WireCellsLocalAssetRepositoryProtocol
    private let nodeCache: any WireCellsNodeCacheProtocol
    private let nodeRenameNotifier: WireCellsNodeRenameNotifier

    package init(
        nodesRepository: any WireCellsNodesRepositoryProtocol,
        localAssetsRepository: any WireCellsLocalAssetRepositoryProtocol,
        nodeCache: any WireCellsNodeCacheProtocol,
        nodeRenameNotifier: WireCellsNodeRenameNotifier
    ) {
        self.nodesRepository = nodesRepository
        self.localAssetsRepository = localAssetsRepository
        self.nodeCache = nodeCache
        self.nodeRenameNotifier = nodeRenameNotifier
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

        // Checks whether the path doesn't already exist.
        let preCheckResult = try await nodesRepository.preCheck(
            path: targetPath.absoluteString,
            findAvailablePath: false
        )

        guard !preCheckResult.fileExists else {
            throw WireCellsRenameNodeError.fileAlreadyExists
        }

        // Renames the file on the server.
        let didRenameFile = try await nodesRepository.renameNode(
            nodeID: nodeID,
            targetPath: targetPath.absoluteString
        )

        guard didRenameFile else {
            throw WireCellsRenameNodeError.serverFailedToRenameNode
        }

        // Refreshes the node metadata and updates the local asset.
        let (node, _) = try await localAssetsRepository.refreshAssetMetadata(
            nodeID: nodeID
        )

        // Updates the node cache.
        await nodeCache.setItem(.init(node: node), for: nodeID)

        // Node is up-to-date, notifies observers.
        await nodeRenameNotifier.send(nodeID)
    }

}

package extension WireCellsRenameNodeUseCase {
    @MainActor
    struct WireCellsNodeRenameNotifier {
        private let subject = PassthroughSubject<UUID, Never>()

        package init() {}

        package var publisher: AnyPublisher<UUID, Never> {
            subject.eraseToAnyPublisher()
        }

        func send(_ nodeID: UUID) {
            subject.send(nodeID)
        }
    }
}

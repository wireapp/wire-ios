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
package import WireCellsAPI

package final actor WireCellsCellsDataSource: WireCellsCellsRepository {
    private let awsClient: any WireCellsAwsClient
    private let cellsApi: any WireCellsCellsAPI
    private let fileManager: FileManager

    package init(
        awsClient: any WireCellsAwsClient,
        cellsApi: any WireCellsCellsAPI,
        fileManager: FileManager = .default
    ) {
        self.awsClient = awsClient
        self.cellsApi = cellsApi
        self.fileManager = fileManager
    }

    package func preCheck(nodePath: String) async throws -> WireCellsPreCheckResult {
        let result = try await cellsApi.preCheck(path: nodePath)
        return result.fileExists
            ? .fileExists(nextPath: result.nextPath ?? nodePath)
            : .success
    }

    package func uploadFile(
        path: URL,
        node: WireCellsCellNode,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws {
        // FIXME: Fix and uncomment
//        try await awsClient.upload(path: path, node: node.toDto(), onProgressUpdate: onProgressUpdate)
    }

    package func getFiles(
        path: String?,
        query: String,
        limit: Int,
        offset: Int
    ) async throws -> [WireCellsCellNode] {
        let response = try await (
            path == nil
                ? cellsApi.getFiles(query: query, limit: limit, offset: offset)
                : cellsApi.getFilesForPath(path: path!, limit: limit, offset: offset)
        )
        return response.nodes.map { $0.toModel() }
    }

    package func deleteFile(nodeUUID: UUID) async throws {
        try await cellsApi.delete(uuid: nodeUUID)
    }

    package func deleteFiles(paths: [String]) async throws {
        try await cellsApi.delete(paths: paths)
    }

    package func publishDrafts(nodes: [WireCellsNodeID]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { [weak self] group in
            guard let self else { return }
            for node in nodes {
                group.addTask { [weak self] in
                    guard let self else { return }
                    try await cellsApi.publishDraft(uuid: node.uuid, versionID: node.versionID)
                }
            }
            try await group.waitForAll()
        }
    }

    package func cancelDraft(nodeID: WireCellsNodeID) async throws {
        try await cellsApi.cancelDraft(uuid: nodeID.uuid, versionID: nodeID.versionID)
    }

    package func downloadFile(
        out: URL,
        cellPath: String,
        onProgressUpdate: @escaping (UInt64) -> Void
    ) async throws {
        guard let stream = OutputStream(url: out, append: true) else {
            throw WireCellsRepositoryError.failedToCreateWriteStream
        }
        // Create an empty file at the destination URL
        fileManager.createFile(atPath: out.path, contents: nil, attributes: nil)

        let fileHandle = try FileHandle(forWritingTo: out)
        // FIXME: Fix and uncomment
//        try await awsClient.download(objectKey: cellPath, to: fileHandle, onProgressUpdate: onProgressUpdate)
    }

    package func getPreviews(nodeUUID: UUID) async throws -> [WireCellsNodePreview] {
        let dto = try await cellsApi.getNode(uuid: nodeUUID)
        // TODO: Handle the case when the dto is nil
        return dto.previews.map {
            WireCellsNodePreview(url: $0.url, dimension: $0.dimension ?? 0)
        }
    }

    package func getNode(nodeUUID: UUID) async throws -> WireCellsCellNode {
        let dto = try await cellsApi.getNode(uuid: nodeUUID)
        return dto.toModel()
    }

    package func createPublicLink(nodeUUID: UUID, fileName: String) async throws -> WireCellsPublicLink {
        try await cellsApi.createPublicLink(uuid: nodeUUID, fileName: fileName)
    }

    package func getPublicLink(linkUUID: UUID) async throws -> URL {
        try await cellsApi.getPublicLink(uuid: linkUUID)
    }

    package func deletePublicLink(linkUUID: UUID) async throws {
        try await cellsApi.deletePublicLink(uuid: linkUUID)
    }
}

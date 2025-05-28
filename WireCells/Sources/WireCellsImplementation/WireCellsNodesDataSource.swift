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

package final actor WireCellsNodesDataSource: WireCellsNodesRepository {
    private let awsClient: any WireCellsAWSClient
    private let cellsAPI: WireCellsNodesAPI
    private let fileManager: FileManager

    package init(credentials: WireCellsCredentials) {
        self.init(
            awsClient: WireCellsAWSClientImplementation(credentials: credentials),
            cellsAPI: WireCellsNodesAPI(
                serverURL: credentials.serverURL.appendingPathComponent("/v2"),
                accessToken: credentials.accessToken
            )
        )
    }

    init(
        awsClient: any WireCellsAWSClient,
        cellsAPI: WireCellsNodesAPI,
        fileManager: FileManager = .default
    ) {
        self.awsClient = awsClient
        self.cellsAPI = cellsAPI
        self.fileManager = fileManager
    }

    package func preCheck(nodePath: String) async throws -> WireCellsPreCheckResult {
        let result = try await cellsAPI.preCheck(path: nodePath)
        return result.fileExists
            ? .fileExists(nextPath: result.nextPath ?? nodePath)
            : .success
    }

    package func uploadFile(path: URL, node: WireCellsNode) async -> AsyncThrowingStream<Int, any Error> {
        await awsClient.upload(path: path, node: node.toDTO())
    }

    package func getFiles(
        path: String?,
        query: String,
        limit: Int,
        offset: Int
    ) async throws -> [WireCellsNode] {
        let response = try await (
            path == nil
                ? cellsAPI.getFiles(query: query, limit: limit, offset: offset)
                : cellsAPI.getFilesForPath(path: path!, limit: limit, offset: offset)
        )
        return response.nodes.map { $0.toModel() }
    }

    package func deleteFile(nodeUUID: UUID) async throws {
        try await cellsAPI.delete(uuid: nodeUUID)
    }

    package func deleteFiles(paths: [String]) async throws {
        try await cellsAPI.delete(paths: paths)
    }

    package func publishDrafts(nodes: [WireCellsNodeID]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { [weak self] group in
            guard let self else { return }
            for node in nodes {
                group.addTask { [weak self] in
                    guard let self else { return }
                    try await cellsAPI.publishDraft(uuid: node.uuid, versionID: node.versionID)
                }
            }
            try await group.waitForAll()
        }
    }

    package func cancelDraft(nodeID: WireCellsNodeID) async throws {
        try await cellsAPI.cancelDraft(uuid: nodeID.uuid, versionID: nodeID.versionID)
    }

    package func downloadFile(
        out: URL,
        cellPath: String,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws {
        guard let stream = OutputStream(url: out, append: true) else {
            throw WireCellsRepositoryError.failedToCreateWriteStream
        }
        // Create an empty file at the destination URL
        fileManager.createFile(atPath: out.path, contents: nil, attributes: nil)

        let fileHandle = try FileHandle(forWritingTo: out)
        try await awsClient.download(objectKey: cellPath, to: fileHandle, onProgressUpdate: onProgressUpdate)
    }

    package func getPreviews(nodeUUID: UUID) async throws -> [WireCellsNodePreview] {
        let dto = try await cellsAPI.getNode(uuid: nodeUUID)
        return dto.previews.map {
            WireCellsNodePreview(url: $0.url, dimension: $0.dimension ?? 0)
        }
    }

    package func getNode(nodeUUID: UUID) async throws -> WireCellsNode {
        let dto = try await cellsAPI.getNode(uuid: nodeUUID)
        return dto.toModel()
    }

    package func createPublicLink(nodeUUID: UUID, fileName: String) async throws -> WireCellsPublicLink {
        try await cellsAPI.createPublicLink(uuid: nodeUUID, fileName: fileName)
    }

    package func getPublicLink(linkUUID: UUID) async throws -> URL {
        try await cellsAPI.getPublicLink(uuid: linkUUID)
    }

    package func deletePublicLink(linkUUID: UUID) async throws {
        try await cellsAPI.deletePublicLink(uuid: linkUUID)
    }
}

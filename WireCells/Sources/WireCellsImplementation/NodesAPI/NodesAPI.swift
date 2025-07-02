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

package enum NodesAPIError: Error {
    case failedToCreateWriteStream
}

// sourcery: AutoMockable
package protocol NodesAPIProtocol: Sendable {
    func preCheck(nodePath: String) async throws -> WireCellsPreCheckResult

    func downloadFile(
        out: URL,
        cellPath: String,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws

    func uploadFile(path: URL, node: WireCellsNode, versionID: UUID) async -> AsyncThrowingStream<Int, any Error>

    func getFiles(
        path: String?,
        query: String,
        limit: Int,
        offset: Int
    ) async throws -> [WireCellsNode]

    func deleteFile(nodeID: UUID) async throws

    func cancelDraft(nodeID: UUID, versionID: UUID) async throws

    func publishDraft(nodeID: UUID, versionID: UUID) async throws

    func getPreviews(nodeID: UUID) async throws -> [WireCellsNodePreview]

    func getNode(nodeID: UUID) async throws -> WireCellsNode

    func deleteFiles(paths: [String]) async throws

    func createPublicLink(nodeID: UUID, fileName: String) async throws -> WireCellsPublicLink

    func getPublicLink(linkUUID: UUID) async throws -> URL

    func deletePublicLink(linkUUID: UUID) async throws
}

package final actor NodesAPI: NodesAPIProtocol {
    private let awsClient: AWSClient
    private let restAPI: RestAPI
    private let fileManager: FileManager

    package init(credentials: WireCellsCredentials) {
        self.init(
            awsClient: AWSClient(credentials: credentials),
            restAPI: RestAPI(
                serverURL: credentials.serverURL.appendingPathComponent("/v2"),
                accessToken: credentials.accessToken
            )
        )
    }

    init(
        awsClient: AWSClient,
        restAPI: RestAPI,
        fileManager: FileManager = .default
    ) {
        self.awsClient = awsClient
        self.restAPI = restAPI
        self.fileManager = fileManager
    }

    package func preCheck(nodePath: String) async throws -> WireCellsPreCheckResult {
        let result = try await restAPI.preCheck(path: nodePath)
        return result.fileExists
            ? .fileExists(nextPath: result.nextPath ?? nodePath)
            : .success
    }

    package func uploadFile(
        path: URL,
        node: WireCellsNode,
        versionID: UUID
    ) async -> AsyncThrowingStream<Int, any Error> {
        await awsClient.upload(path: path, node: node.toDTO(), versionID: versionID)
    }

    package func getFiles(
        path: String?,
        query: String,
        limit: Int,
        offset: Int
    ) async throws -> [WireCellsNode] {
        let response = try await (
            path == nil
                ? restAPI.getFiles(query: query, limit: limit, offset: offset)
                : restAPI.getFilesForPath(path: path!, limit: limit, offset: offset)
        )
        return response.nodes.map { $0.toModel() }
    }

    package func deleteFile(nodeID: UUID) async throws {
        try await restAPI.delete(uuid: nodeID)
    }

    package func deleteFiles(paths: [String]) async throws {
        try await restAPI.delete(paths: paths)
    }

    package func publishDraft(nodeID: UUID, versionID: UUID) async throws {
        try await restAPI.publishDraft(uuid: nodeID, versionID: versionID)
    }

    package func cancelDraft(nodeID: UUID, versionID: UUID) async throws {
        try await restAPI.cancelDraft(uuid: nodeID, versionID: versionID)
    }

    package func downloadFile(
        out: URL,
        cellPath: String,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws {
        guard let stream = OutputStream(url: out, append: true) else {
            throw NodesAPIError.failedToCreateWriteStream
        }
        // Create an empty file at the destination URL
        fileManager.createFile(atPath: out.path, contents: nil, attributes: nil)

        let fileHandle = try FileHandle(forWritingTo: out)
        try await awsClient.download(objectKey: cellPath, to: fileHandle, onProgressUpdate: onProgressUpdate)
    }

    package func getPreviews(nodeID: UUID) async throws -> [WireCellsNodePreview] {
        let dto = try await restAPI.getNode(uuid: nodeID)
        return dto.previews.map {
            WireCellsNodePreview(url: $0.url, dimension: $0.dimension ?? 0)
        }
    }

    package func getNode(nodeID: UUID) async throws -> WireCellsNode {
        let dto = try await restAPI.getNode(uuid: nodeID)
        return dto.toModel()
    }

    package func createPublicLink(nodeID: UUID, fileName: String) async throws -> WireCellsPublicLink {
        try await restAPI.createPublicLink(uuid: nodeID, fileName: fileName)
    }

    package func getPublicLink(linkUUID: UUID) async throws -> URL {
        try await restAPI.getPublicLink(uuid: linkUUID)
    }

    package func deletePublicLink(linkUUID: UUID) async throws {
        try await restAPI.deletePublicLink(uuid: linkUUID)
    }
}

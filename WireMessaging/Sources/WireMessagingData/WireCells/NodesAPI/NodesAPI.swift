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

import CellsSDK
package import Foundation
package import WireMessagingDomain

package enum NodesAPIError: Error {
    case failedToCreateWriteStream
}

package final actor NodesAPI: NodesAPIProtocol, WireCellsNodesRepositoryProtocol {
    private let awsClient: AWSClient
    private let restAPI: RestAPI
    private let fileManager: FileManager

    package init(serverURL: URL, accessToken: any AccessTokenProvider) {
        self.init(
            awsClient: AWSClient(serverURL: serverURL, accessToken: accessToken),
            restAPI: RestAPI(
                serverURL: serverURL.appendingPathComponent("/v2"),
                accessToken: accessToken
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

    /// Deletes nodes by their `UUID`s.
    ///
    /// - Parameters:
    ///  - nodeIDs: The `UUID`s of the nodes to delete.
    ///  - permanently: Whether to permanently delete the nodes or move them to the recycle bin.
    /// - Returns: Whether the deletion was successful.
    package func deleteNodes(nodeIDs: [UUID], permanently: Bool) async throws -> Bool {
        try await restAPI.deleteNodes(nodeIDs: nodeIDs, permanently: permanently)
    }

    package func preCheck(path: String, findAvailablePath: Bool) async throws -> (fileExists: Bool, nextPath: String?) {
        let result = try await restAPI.preCheck(path: path, findAvailablePath: findAvailablePath)
        return (result.fileExists, result.nextPath)
    }

    package func renameNode(nodeID: UUID, targetPath: String) async throws -> Bool {
        try await restAPI.renameNode(nodeID: nodeID, targetPath: targetPath)
    }

    package func publishDraft(nodeID: UUID, versionID: UUID) async throws {
        try await restAPI.publishDraft(uuid: nodeID, versionID: versionID)
    }

    package func deleteVersion(nodeID: UUID, versionID: UUID) async throws {
        try await restAPI.deleteVersion(uuid: nodeID, versionID: versionID)
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
        return dto.previews.compactMap { $0.toModel() }
    }

    package func getNode(nodeID: UUID) async throws -> WireCellsNode {
        let dto = try await restAPI.getNode(uuid: nodeID)
        return dto.toDomainModel()
    }

    package func getNode(id: UUID) async throws -> WireCellsNode? {
        do {
            return try await getNode(nodeID: id)
        } catch let error as CellsSDK.ErrorResponse where error.httpStatusCode == 404 {
            return nil
        }
    }

    package func getNodes(
        _ request: WireCellsGetNodesRequest
    ) async throws -> (nodes: [WireCellsNode], nextOffset: Int?) {
        do {
            let (nodes, nextOffset) = try await restAPI.getNodes(request)
            return (nodes: nodes.map { $0.toDomainModel() }, nextOffset: nextOffset)
            // user not yet created, wire users are "lazily" sync to pydio users the first time they are part of a cells
            // conversation
        } catch let error as CellsSDK.ErrorResponse where error.httpStatusCode == 401 {
            return (nodes: [], nextOffset: nil)
        } catch {
            throw error
        }
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

private extension CellsSDK.ErrorResponse {

    var httpStatusCode: Int? {
        switch self {
        case let .error(_, _, response, _):
            (response as? HTTPURLResponse)?.statusCode
        }
    }
}

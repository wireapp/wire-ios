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

import CellsSDK
package import Foundation
package import WireMessagingDomain

package enum NodesAPIError: Error {
    case failedToCreateWriteStream
    case moveFailed
}

package final actor NodesAPI: NodesAPIProtocol, WireDriveNodesRepositoryProtocol,
    WireDriveEditingURLRepositoryProtocol {
    private let awsClient: AWSClient
    private let localStore: any WireDriveConversationsLocalStoreProtocol
    private let restAPI: RestAPI
    private let fileManager: FileManager

    package init(
        serverURLResolver: @escaping @Sendable () throws -> URL,
        localStore: any WireDriveConversationsLocalStoreProtocol,
        accessToken: any AccessTokenProvider
    ) {
        self.init(
            awsClient: AWSClient(
                serverURLResolver: serverURLResolver,
                accessToken: accessToken
            ),
            localStore: localStore,
            restAPI: RestAPI(
                serverURLResolver: serverURLResolver,
                accessToken: accessToken
            )
        )
    }

    init(
        awsClient: AWSClient,
        localStore: any WireDriveConversationsLocalStoreProtocol,
        restAPI: RestAPI,
        fileManager: FileManager = .default
    ) {
        self.awsClient = awsClient
        self.restAPI = restAPI
        self.fileManager = fileManager
        self.localStore = localStore
    }

    package func preCheck(nodePath: String, findAvailablePath: Bool) async throws -> WireDrivePreCheckResult {
        let result = try await restAPI.preCheck(
            path: nodePath,
            findAvailablePath: findAvailablePath
        )

        return result.fileExists
            ? .fileExists(nextPath: result.nextPath ?? nodePath)
            : .success
    }

    package func uploadFile(
        path: URL,
        node: WireDriveNode,
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

    package func restoreNodes(nodeIDs: [UUID]) async throws -> Bool {
        try await restAPI.restoreNodes(nodeIDs: nodeIDs)
    }

    package func renameNode(nodeID: UUID, targetPath: String) async throws -> Bool {
        try await restAPI.renameNode(nodeID: nodeID, targetPath: targetPath, targetIsParent: false)
    }

    package func moveNode(nodeID: UUID, newContainerPath: String) async throws {
        guard try await restAPI.renameNode(nodeID: nodeID, targetPath: newContainerPath, targetIsParent: true) else {
            throw NodesAPIError.moveFailed
        }
    }

    package func publishDraft(nodeID: UUID, versionID: UUID) async throws {
        try await restAPI.publishDraft(uuid: nodeID, versionID: versionID)
    }

    package func deleteVersion(nodeID: UUID, versionID: UUID) async throws {
        try await restAPI.deleteVersion(uuid: nodeID, versionID: versionID)
    }

    package func getVersions(nodeID: UUID) async throws -> [WireDriveNodeVersion] {
        let versionsDTO = try await restAPI.getVersions(uuid: nodeID)
        return versionsDTO.toDomainModel()
    }

    package func restoreVersion(nodeID: UUID, versionID: UUID) async throws {
        try await restAPI.restoreVersion(uuid: nodeID, versionID: versionID)
    }

    package func downloadFile(
        out: URL,
        cellPath: String,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws {
        guard OutputStream(url: out, append: true) != nil else {
            throw NodesAPIError.failedToCreateWriteStream
        }
        // Create an empty file at the destination URL
        fileManager.createFile(atPath: out.path, contents: nil, attributes: nil)

        let fileHandle = try FileHandle(forWritingTo: out)
        try await awsClient.download(objectKey: cellPath, to: fileHandle, onProgressUpdate: onProgressUpdate)
    }

    package func getPreviews(nodeID: UUID) async throws -> [WireDriveNodePreview] {
        let dto = try await restAPI.getNode(uuid: nodeID)
        return dto.previews.compactMap { $0.toModel() }
    }

    package func getNode(nodeID: UUID) async throws -> WireDriveNode {
        let dto = try await restAPI.getNode(uuid: nodeID)
        let conversations = await localStore.fetchDriveConversations()
        return dto.toDomainModel(conversations: conversations)
    }

    package func getNode(id: UUID) async throws -> WireDriveNode? {
        do {
            return try await getNode(nodeID: id)
        } catch let error as CellsSDK.ErrorResponse where error.httpStatusCode == 404 {
            return nil
        }
    }

    package func getNodes(
        _ request: WireDriveGetNodesRequest
    ) async throws -> (nodes: [WireDriveNode], nextOffset: Int?) {
        do {
            let (nodes, nextOffset) = try await restAPI.getNodes(request)
            let conversations = await localStore.fetchDriveConversations()
            return (nodes: nodes.filter { !$0.isDraft }.map { $0.toDomainModel(conversations: conversations) }, nextOffset: nextOffset)
            // user not yet created, wire users are "lazily" sync to pydio users the first time they are part of a cells
            // conversation
        } catch let error as CellsSDK.ErrorResponse where error.httpStatusCode == 401 {
            return (nodes: [], nextOffset: nil)
        } catch {
            throw error
        }
    }

    package func getEditorURL(id: UUID) async throws -> (url: URL, date: Date)? {
        try await restAPI.getEditorURL(id: id)
    }

    package func createPublicLink(nodeID: UUID, label: String) async throws -> WireDrivePublicLink {
        try await restAPI.createPublicLink(
            uuid: nodeID,
            label: label
        )
    }

    package func getPublicLink(linkID: String) async throws -> WireDrivePublicLink {
        try await restAPI.getPublicLink(linkID: linkID)
    }

    package func deletePublicLink(linkID: String) async throws {
        try await restAPI.deletePublicLink(linkID: linkID)
    }

    package func updatePublicLinkExpiration(
        linkID: String,
        expiration: Date?
    ) async throws -> WireDrivePublicLink {
        try await restAPI.updatePublicLinkExpiration(
            linkID: linkID,
            expiration: expiration
        )
    }

    package func updatePublicLinkPassword(
        linkID: String,
        password: String?
    ) async throws -> WireDrivePublicLink {
        try await restAPI.updatePublicLinkPassword(
            linkID: linkID,
            password: password
        )
    }

    package func updateTags(nodeID: UUID, tags: [String]) async throws {
        try await restAPI.updateTags(uuid: nodeID, tags: tags)
    }

    package func getAllTags() async throws -> [String] {
        try await restAPI.getAllTags()
    }

    package func createFolder(at path: String) async throws -> WireDriveNode {
        let createdNode = try await restAPI.createFolder(at: path)
        let conversations = await localStore.fetchDriveConversations()
        return createdNode.toDomainModel(conversations: conversations)
    }

    package func createFile(at path: String, templateUuid: String) async throws -> WireDriveNode {
        let createdNode = try await restAPI.createFile(at: path, templateUuid: templateUuid)
        let conversations = await localStore.fetchDriveConversations()
        return createdNode.toDomainModel(conversations: conversations)
    }

    package func getTemplates() async throws -> [WireDriveFileTemplate] {
        try await restAPI.getTemplates()?.toDomainModel() ?? []
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

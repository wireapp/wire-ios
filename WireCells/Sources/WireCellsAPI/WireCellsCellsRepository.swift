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


public import Foundation

public enum WireCellsRepositoryError: Error {
    case failedToCreateWriteStream
}

public protocol WireCellsCellsRepository: Actor {
    func preCheck(nodePath: String) async throws -> WireCellsPreCheckResult

    func downloadFile(
        out: URL,
        cellPath: String,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws

    func uploadFile(
        path: URL,
        node: WireCellsCellNode,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws

    func getFiles(
        path: String?,
        query: String,
        limit: Int,
        offset: Int
    ) async throws -> [WireCellsCellNode]

    func deleteFile(nodeUUID: UUID) async throws

    func cancelDraft(nodeID: WireCellsNodeID) async throws

    func publishDrafts(nodes: [WireCellsNodeID]) async throws

    func getPreviews(nodeUUID: UUID) async throws -> [WireCellsNodePreview]

    func getNode(nodeUUID: UUID) async throws -> WireCellsCellNode

    func deleteFiles(paths: [String]) async throws

    func createPublicLink(nodeUUID: UUID, fileName: String) async throws -> WireCellsPublicLink

    func getPublicLink(linkUUID: UUID) async throws -> URL

    func deletePublicLink(linkUUID: UUID) async throws
}

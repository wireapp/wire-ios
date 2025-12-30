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

// sourcery: AutoMockable
package protocol NodesAPIProtocol: Sendable {
    func preCheck(nodePath: String, findAvailablePath: Bool) async throws -> WireCellsPreCheckResult

    func downloadFile(
        out: URL,
        cellPath: String,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws

    func uploadFile(path: URL, node: WireCellsNode, versionID: UUID) async throws -> AsyncThrowingStream<Int, any Error>

    func deleteVersion(nodeID: UUID, versionID: UUID) async throws

    func publishDraft(nodeID: UUID, versionID: UUID) async throws

    func getPreviews(nodeID: UUID) async throws -> [WireCellsNodePreview]

    func getNode(nodeID: UUID) async throws -> WireCellsNode

    func deleteNodes(nodeIDs: [UUID], permanently: Bool) async throws -> Bool

    func createPublicLink(nodeID: UUID, fileName: String) async throws -> WireCellsPublicLink

    func getPublicLink(linkUUID: UUID) async throws -> URL

    func deletePublicLink(linkUUID: UUID) async throws

    func updateTags(nodeID: UUID, tags: [String]) async throws

    func getAllTags() async throws -> [String]

    func getVersions(nodeID: UUID) async throws -> [WireCellsNodeVersion]
}

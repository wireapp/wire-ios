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

// sourcery: AutoMockable
package protocol WireCellsNodeUploadManagerProtocol: Sendable {
    /// Starts file upload. Returns the new node after pre-checking.
    func upload(
        nodeID: UUID,
        versionID: UUID,
        assetPath: URL,
        assetSize: UInt64,
        destNodePath: String
    ) async throws -> (node: WireCellsNode, stream: AsyncStream<WireCellsUploadStatus>)

    /// Observe upload events for a specific node UUID.
    func observeUpload(nodeID: UUID) async -> AsyncStream<WireCellsUploadStatus>?

    /// Cancel an ongoing upload.
    func cancelUpload(nodeID: UUID) async

    /// Get current upload info for a node, if any.
    func getUploadInfo(nodeID: UUID) async -> WireCellsNodeUploadInfo?

    /// Check if a node is currently uploading.
    func isUploading(nodeID: UUID) async -> Bool
}

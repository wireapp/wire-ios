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

public protocol WireCellsNodeUploadManager: Actor {
    /// Starts file upload. Returns the new node after pre-checking.
    func upload(assetPath: URL, assetSize: UInt64, destNodePath: String) async throws -> WireCellsNode

    /// Observe upload events for a specific node UUID.
    func observeUpload(nodeID: WireCellsNodeID) async -> AsyncStream<WireCellsNodeUploadEvent>?

    /// Retry a failed upload.
    func retryUpload(nodeID: WireCellsNodeID) async

    /// Cancel an ongoing upload.
    func cancelUpload(nodeID: WireCellsNodeID) async

    /// Get current upload info for a node, if any.
    func getUploadInfo(nodeID: WireCellsNodeID) async -> WireCellsNodeUploadInfo?

    /// Check if a node is currently uploading.
    func isUploading(nodeID: WireCellsNodeID) async -> Bool
}

public struct WireCellsNodeUploadInfo: Equatable, Hashable, Sendable {
    public let progress: Float
    public let uploadFailed: Bool

    package init(progress: Float = 0.0, uploadFailed: Bool = false) {
        self.progress = progress
        self.uploadFailed = uploadFailed
    }
}

public enum WireCellsNodeUploadEvent: Equatable, Hashable, Sendable {
    case uploadProgress(Float)
    case uploadCompleted
    case uploadError
    case uploadCancelled
}

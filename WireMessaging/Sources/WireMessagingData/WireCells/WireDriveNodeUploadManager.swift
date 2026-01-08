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
import WireLogging
package import WireMessagingDomain

package final actor WireDriveNodeUploadManager: WireDriveNodeUploadManagerProtocol {
    private let fileManager: FileManager
    private let nodesAPI: any NodesAPIProtocol

    private actor Uploads {
        var uploads: [UUID: WireDriveUploadInfo] = [:]

        func set(_ nodeID: UUID, info: WireDriveUploadInfo) {
            uploads[nodeID] = info
        }

        func get(_ nodeID: UUID) -> WireDriveUploadInfo? {
            uploads[nodeID]
        }

        func remove(_ nodeID: UUID) {
            uploads.removeValue(forKey: nodeID)
        }

        func update(_ nodeID: UUID, with transform: (WireDriveUploadInfo) -> WireDriveUploadInfo) {
            if let current = uploads[nodeID] {
                uploads[nodeID] = transform(current)
            }
        }

        func allKeys() -> [UUID] {
            Array(uploads.keys)
        }
    }

    private let uploads = Uploads()

    package init(
        fileManager: FileManager = .default,
        nodesAPI: any NodesAPIProtocol
    ) {
        self.fileManager = fileManager
        self.nodesAPI = nodesAPI
    }

    package func upload(
        nodeID: UUID,
        versionID: UUID,
        assetPath: URL,
        assetSize: UInt64,
        destNodePath: String
    ) async throws -> (node: WireDriveNode, stream: AsyncStream<WireDriveUploadStatus>) {
        let result = try await nodesAPI.preCheck(
            nodePath: destNodePath,
            findAvailablePath: true
        )

        let resolvedPath: String = switch result {
        case let .fileExists(nextPath):
            nextPath
        case .success:
            destNodePath
        }

        let node = WireDriveNode(
            uuid: nodeID,
            path: resolvedPath,
            modified: nil,
            size: assetSize,
            eTag: nil,
            type: nil,
            isRecycled: false,
            isDraft: true,
            contentUrl: nil,
            contentHash: nil,
            mimeType: nil,
            previews: [],
            ownerUserID: nil,
            conversationID: nil,
            publicLinkID: nil,
            downloadURL: nil
        )

        let stream = await startUpload(assetPath: assetPath, assetSize: assetSize, node: node, versionID: versionID)

        return (node, stream)
    }

    private func startUpload(
        assetPath: URL,
        assetSize: UInt64,
        node: WireDriveNode,
        versionID: UUID
    ) async -> AsyncStream<WireDriveUploadStatus> {
        let (stream, continuation) = AsyncStream.makeStream(of: WireDriveUploadStatus.self)
        let task = Task { [nodesAPI] in
            do {
                let upload = try await nodesAPI.uploadFile(path: assetPath, node: node, versionID: versionID)

                for try await progress in upload {
                    await self.updateUploadProgress(
                        nodeID: node.id,
                        uploaded: UInt64(progress),
                        total: assetSize
                    )
                    continuation.yield(.uploading(progress: Float(progress) / Float(assetSize)))
                }
                await uploads.remove(node.id)
                continuation.yield(WireDriveUploadStatus.uploaded(isDraft: true))
                continuation.finish()
            } catch {
                WireLogger.wireDrive.info("Failed to upload file: \(error)")

                await uploads.remove(node.id)
                continuation.yield(WireDriveUploadStatus.failed(error: WireDriveUploadError(error)))
                continuation.finish()
            }
        }

        let info = WireDriveUploadInfo(
            node: node,
            versionID: versionID,
            localPath: assetPath,
            task: task,
            continuation: continuation,
            stream: stream
        )

        await uploads.set(node.id, info: info)

        return stream
    }

    package func observeUpload(nodeID: UUID) async -> AsyncStream<WireDriveUploadStatus>? {
        await uploads.get(nodeID)?.stream
    }

    package func cancelUpload(nodeID: UUID) async {
        if let info = await uploads.get(nodeID) {
            info.continuation.yield(.cancelled)
            info.continuation.finish()
            info.task.cancel()
            await uploads.remove(nodeID)
        }
    }

    package func getUploadInfo(nodeID: UUID) async -> WireDriveNodeUploadInfo? {
        await uploads.get(nodeID)?.toUploadInfo()
    }

    package func isUploading(nodeID: UUID) async -> Bool {
        await uploads.get(nodeID) != nil
    }

    private func updateUploadProgress(nodeID: UUID, uploaded: UInt64, total: UInt64) async {
        let progress = Float(uploaded) / Float(total)
        await uploads.update(nodeID) { $0.withProgress(progress) }
    }
}

struct WireDriveUploadInfo {
    let node: WireDriveNode
    let versionID: UUID
    let localPath: URL
    let task: Task<Void, Never>

    var continuation: AsyncStream<WireDriveUploadStatus>.Continuation
    var progress: Float = 0.0

    var stream: AsyncStream<WireDriveUploadStatus>

    func toUploadInfo() -> WireDriveNodeUploadInfo {
        WireDriveNodeUploadInfo(progress: progress)
    }

    func withProgress(_ newProgress: Float) -> WireDriveUploadInfo {
        var copy = self
        copy.progress = newProgress
        return copy
    }
}

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
import WireLogging
package import WireMessagingDomain

package final actor WireCellsNodeUploadManager: WireCellsNodeUploadManagerProtocol {
    private let fileManager: FileManager
    private let nodesAPI: any NodesAPIProtocol

    private actor Uploads {
        var uploads: [UUID: WireCellsUploadInfo] = [:]

        func set(_ nodeID: UUID, info: WireCellsUploadInfo) {
            uploads[nodeID] = info
        }

        func get(_ nodeID: UUID) -> WireCellsUploadInfo? {
            uploads[nodeID]
        }

        func remove(_ nodeID: UUID) {
            uploads.removeValue(forKey: nodeID)
        }

        func update(_ nodeID: UUID, with transform: (WireCellsUploadInfo) -> WireCellsUploadInfo) {
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
    ) async throws -> (node: WireCellsNode, stream: AsyncStream<WireCellsUploadStatus>) {
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

        let node = WireCellsNode(
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
        node: WireCellsNode,
        versionID: UUID
    ) async -> AsyncStream<WireCellsUploadStatus> {
        let (stream, continuation) = AsyncStream.makeStream(of: WireCellsUploadStatus.self)
        let task = Task { [nodesAPI] in
            let upload = await nodesAPI.uploadFile(path: assetPath, node: node, versionID: versionID)

            do {
                for try await progress in upload {
                    await self.updateUploadProgress(
                        nodeID: node.id,
                        uploaded: UInt64(progress),
                        total: assetSize
                    )
                    continuation.yield(.uploading(progress: Float(progress) / Float(assetSize)))
                }
                await uploads.remove(node.id)
                continuation.yield(WireCellsUploadStatus.uploaded(isDraft: true))
                continuation.finish()
            } catch {
                WireLogger.wireCells.info("Failed to upload file: \(error)")

                await uploads.remove(node.id)
                continuation.yield(WireCellsUploadStatus.failed(error: WireCellsUploadError(error)))
                continuation.finish()
            }
        }

        let info = WireCellsUploadInfo(
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

    package func observeUpload(nodeID: UUID) async -> AsyncStream<WireCellsUploadStatus>? {
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

    package func getUploadInfo(nodeID: UUID) async -> WireCellsNodeUploadInfo? {
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

struct WireCellsUploadInfo {
    let node: WireCellsNode
    let versionID: UUID
    let localPath: URL
    let task: Task<Void, Never>

    var continuation: AsyncStream<WireCellsUploadStatus>.Continuation
    var progress: Float = 0.0

    var stream: AsyncStream<WireCellsUploadStatus>

    func toUploadInfo() -> WireCellsNodeUploadInfo {
        WireCellsNodeUploadInfo(progress: progress)
    }

    func withProgress(_ newProgress: Float) -> WireCellsUploadInfo {
        var copy = self
        copy.progress = newProgress
        return copy
    }
}

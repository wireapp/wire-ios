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

import Foundation
import WireCellsAPI

package final actor WireCellsCellUploadManagerImpl: WireCellsCellUploadManager {
    private let fileManager: FileManager
    private let repository: any WireCellsCellsRepository

    private actor Uploads {
        var uploads: [WireCellsNodeID: WireCellsUploadInfo] = [:]

        func set(_ nodeID: WireCellsNodeID, info: WireCellsUploadInfo) {
            uploads[nodeID] = info
        }

        func get(_ nodeID: WireCellsNodeID) -> WireCellsUploadInfo? {
            uploads[nodeID]
        }

        func remove(_ nodeID: WireCellsNodeID) {
            uploads.removeValue(forKey: nodeID)
        }

        func update(_ nodeID: WireCellsNodeID, with transform: (WireCellsUploadInfo) -> WireCellsUploadInfo) {
            if let current = uploads[nodeID] {
                uploads[nodeID] = transform(current)
            }
        }

        func allKeys() -> [WireCellsNodeID] {
            Array(uploads.keys)
        }
    }

    private let uploads = Uploads()

    init(
        fileManager: FileManager = .default,
        repository: any WireCellsCellsRepository
    ) {
        self.fileManager = fileManager
        self.repository = repository
    }

    func upload(assetPath: URL, assetSize: UInt64, destNodePath: String) async throws -> WireCellsCellNode {
        let result = try await repository.preCheck(nodePath: destNodePath)

        let resolvedPath: String
        switch result {
        case .fileExists(let nextPath):
            resolvedPath = nextPath
        case .success:
            resolvedPath = destNodePath
        }

        let node = WireCellsCellNode(
            uuid: UUID(),
            versionID: UUID().uuidString,
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
            publicLinkID: nil
        )

        startUpload(assetPath: assetPath, node: node)

        return node
    }

    private func startUpload(assetPath: URL, node: WireCellsCellNode) {
        let stream = AsyncStream<WireCellsCellUploadEvent> { continuation in
            let task = Task {
                do {
                    try await repository.uploadFile(
                        path: assetPath,
                        node: node,
                        onProgressUpdate: { [weak self] uploaded in
                            Task { [weak self] in
                                await self?.updateUploadProgress(
                                    nodeID: node.id,
                                    uploaded: uploaded,
                                    total: node.size ?? 1
                                )
                                continuation.yield(WireCellsCellUploadEvent.uploadProgress(Float(uploaded) / Float(node.size ?? 1)))
                            }
                        }
                    )
                    await uploads.remove(node.id)
                    continuation.yield(WireCellsCellUploadEvent.uploadCompleted)
                    continuation.finish()
                } catch {
                    await uploads.update(node.id) { $0.withUploadFailed() }
                    continuation.yield(WireCellsCellUploadEvent.uploadError)
                    continuation.finish()
                }
            }

            let info = WireCellsUploadInfo(
                node: node,
                localPath: assetPath,
                task: task,
                continuation: continuation,
                stream: stream
            )
            Task { await uploads.set(node.id, info: info) }
        }

        // we need to store the stream reference in UploadInfo above, and provide `observeUpload`
    }

    func observeUpload(nodeID: WireCellsNodeID) async -> AsyncStream<WireCellsCellUploadEvent>? {
        await uploads.get(nodeID)?.stream
    }

    func retryUpload(nodeID: WireCellsNodeID) async {
        if let info = await uploads.get(nodeID) {
            if fileManager.fileExists(atPath: info.localPath.path) == true {
                startUpload(assetPath: info.localPath, node: info.node)
            } else {
                await uploads.update(nodeID) { $0.withUploadFailed() }
                info.continuation.yield(.uploadError)
                info.continuation.finish()
            }
        }
    }

    func cancelUpload(nodeID: WireCellsNodeID) async {
        if let info = await uploads.get(nodeID) {
            info.continuation.yield(.uploadCancelled)
            info.continuation.finish()
            info.task.cancel()
            await uploads.remove(nodeID)
        }
    }

    func getUploadInfo(nodeID: WireCellsNodeID) async -> WireCellsCellUploadInfo? {
        await uploads.get(nodeID)?.toUploadInfo()
    }

    func isUploading(nodeID: WireCellsNodeID) async -> Bool {
        await uploads.get(nodeID) != nil
    }

    private func updateUploadProgress(nodeID: WireCellsNodeID, uploaded: UInt64, total: UInt64) async {
        let progress = Float(uploaded) / Float(total)
        await uploads.update(nodeID) { $0.withProgress(progress) }
    }
}

struct WireCellsUploadInfo {
    let node: WireCellsCellNode
    let localPath: URL
    let task: Task<Void, Never>

    var continuation: AsyncStream<WireCellsCellUploadEvent>.Continuation
    var progress: Float = 0.0
    var uploadFailed: Bool = false

    var stream: AsyncStream<WireCellsCellUploadEvent>

    func toUploadInfo() -> WireCellsCellUploadInfo {
        WireCellsCellUploadInfo(progress: progress, uploadFailed: uploadFailed)
    }

    func withProgress(_ newProgress: Float) -> WireCellsUploadInfo {
        var copy = self
        copy.progress = newProgress
        return copy
    }

    func withUploadFailed() -> WireCellsUploadInfo {
        var copy = self
        copy.uploadFailed = true
        return copy
    }
}

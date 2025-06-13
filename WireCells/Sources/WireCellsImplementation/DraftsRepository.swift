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

import Collections
@preconcurrency import Combine
import Foundation
package import UniformTypeIdentifiers
package import WireCellsAPI
import WireLogging

package protocol DraftsRepositoryProtocol: Actor {

    func add(assetURL: URL, assetSize: Int, cellName: String, fileName: String, fileType: UTType?) async
    func drafts(for cellName: String) -> AsyncStream<[WireCellsDraft]>
    func publishAll(for cellName: String) async throws
    func clearPublished(for cellName: String)

}

enum DraftsRepositoryError: Error, Equatable {

    case notAllFilesAreUploaded
    case notAllFilesArePublished

}

package actor DraftsRepository: DraftsRepositoryProtocol {

    typealias CellName = String

    private let drafts: CurrentValueSubject<[CellName: OrderedDictionary<UUID, WireCellsDraft>], Never>
    private var continuations: [UUID: AsyncStream<[WireCellsDraft]>.Continuation] = [:]
    private let uploadManager: any WireCellsNodeUploadManagerProtocol
    private let nodesAPI: any NodesAPIProtocol

    package init(uploadManager: any WireCellsNodeUploadManagerProtocol, nodesAPI: any NodesAPIProtocol) {
        self.init(uploadManager: uploadManager, nodesAPI: nodesAPI, drafts: [:])
    }

    init(
        uploadManager: any WireCellsNodeUploadManagerProtocol,
        nodesAPI: any NodesAPIProtocol,
        drafts: [CellName: OrderedDictionary<UUID, WireCellsDraft>]
    ) {
        self.uploadManager = uploadManager
        self.nodesAPI = nodesAPI
        self.drafts = CurrentValueSubject(drafts)
    }

    deinit {
        continuations.values.forEach { $0.finish() }
    }

    package func add(assetURL: URL, assetSize: Int, cellName: String, fileName: String, fileType: UTType?) async {
        let draft = WireCellsDraft(
            nodeID: UUID(),
            versionID: UUID(),
            assetURL: assetURL,
            fileType: fileType,
            status: .uploading(progress: 0),
            name: fileName,
            bytes: assetSize,
            mimeType: nil
        )
        drafts.value[cellName, default: [:]][draft.nodeID] = draft

        do {
            let (node, stream) = try await uploadManager.upload(
                nodeID: draft.nodeID,
                versionID: draft.versionID,
                assetPath: assetURL,
                assetSize: UInt64(assetSize),
                destNodePath: "\(cellName)/\(fileName)"
            )

            // Update draft name if changed
            if let updatedName = URL(string: node.path)?.lastPathComponent, updatedName != draft.name {
                drafts.value[cellName]?[draft.nodeID]?.name = updatedName
            }

            for await status in stream {
                setStatus(status, cellName: cellName, id: draft.nodeID)
            }

            // Set post upload values
            let latestNode = try await nodesAPI.getNode(nodeID: draft.nodeID)
            if let mimeTime = latestNode.mimeType {
                drafts.value[cellName]?[draft.nodeID]?.mimeType = mimeTime
            }

        } catch {
            setStatus(.failed(error: WireCellsUploadError(error)), cellName: cellName, id: draft.nodeID)
        }
    }

    package func drafts(for cellName: String) -> AsyncStream<[WireCellsDraft]> {
        let continuationID = UUID()
        let (stream, continuation) = AsyncStream.makeStream(
            of: [WireCellsDraft].self,
            bufferingPolicy: .bufferingNewest(1)
        )

        let cancellable = drafts.sink { drafts in
            let result = drafts[cellName] ?? [:]
            continuation.yield(Array(result.values))
        }
        continuation.onTermination = { _ in
            cancellable.cancel()

            Task { [weak self] in
                await self?.removeContinuation(for: continuationID)
            }
        }

        continuations[continuationID] = continuation

        return stream
    }

    /// Publishes **all** drafts for the specified cell name.
    ///
    /// - parameter cellName: The name of the cell for which to publish drafts.
    /// - throws: An error if not **all** files have been uploaded before publishing or if not all files are published
    /// when the method completes.

    package func publishAll(for cellName: String) async throws {
        guard let drafts = drafts.value[cellName] else { return }

        guard drafts.areAllUploaded else {
            throw DraftsRepositoryError.notAllFilesAreUploaded
        }

        let results = await withTaskGroup(
            of: Result<UUID, any Error>.self,
            returning: [Result<UUID, any Error>].self
        ) { [nodesAPI] group in
            for (nodeID, draft) in drafts where draft.status == .uploaded(isDraft: true) {
                group.addTask {
                    do {
                        try await nodesAPI.publishDraft(nodeID: nodeID, versionID: draft.versionID)
                        return .success(nodeID)
                    } catch {
                        WireLogger.wireCells.error("Failed to publish draft: \(error)")
                        return .failure(error)
                    }
                }
            }

            return await group.reduce(into: []) { partial, result in
                partial.append(result)
            }
        }

        let publishedIDs = results.compactMap { try? $0.get() }
        for id in publishedIDs {
            setStatus(.uploaded(isDraft: false), cellName: cellName, id: id)
        }

        guard self.drafts.value[cellName]?.areAllPublished == true else {
            throw DraftsRepositoryError.notAllFilesArePublished
        }
    }

    package func clearPublished(for cellName: String) {
        drafts.value[cellName]?.removeAll { $0.value.status == .uploaded(isDraft: false) }
    }

    private func removeContinuation(for uuid: UUID) async {
        continuations[uuid] = nil
    }

    private func setStatus(_ status: WireCellsUploadStatus, cellName: CellName, id: UUID) {
        drafts.value[cellName]?[id]?.status = status
    }

    #if DEBUG
        var getDraftsForTesting: [CellName: OrderedDictionary<UUID, WireCellsDraft>] {
            drafts.value
        }

        func setDraftsForTesting(_ drafts: [CellName: OrderedDictionary<UUID, WireCellsDraft>]) {
            self.drafts.value = drafts
        }
    #endif

}

private extension OrderedDictionary<UUID, WireCellsDraft> {
    var areAllUploaded: Bool {
        allSatisfy {
            switch $0.value.status {
            case .uploaded:
                true
            case .uploading, .failed, .cancelled:
                false
            }
        }
    }

    var areAllPublished: Bool {
        values.allSatisfy { $0.status == .uploaded(isDraft: false) }
    }
}

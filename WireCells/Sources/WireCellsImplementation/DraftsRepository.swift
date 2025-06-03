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

}

enum DraftsRepositoryError: Error, Equatable {

    case notAllFilesAreUploaded
    case notAllFilesArePublished

}

package actor DraftsRepository: DraftsRepositoryProtocol {

    typealias CellName = String

    private let drafts: CurrentValueSubject<[CellName: OrderedDictionary<WireCellsNodeID, WireCellsDraft>], Never>
    private var continuations: [UUID: AsyncStream<[WireCellsDraft]>.Continuation] = [:]
    private let uploadManager: any WireCellsNodeUploadManagerProtocol
    private let nodesAPI: any NodesAPIProtocol

    package init(uploadManager: any WireCellsNodeUploadManagerProtocol, nodesAPI: any NodesAPIProtocol) {
        self.init(uploadManager: uploadManager, nodesAPI: nodesAPI, drafts: [:])
    }

    init(
        uploadManager: any WireCellsNodeUploadManagerProtocol,
        nodesAPI: any NodesAPIProtocol,
        drafts: [CellName: OrderedDictionary<WireCellsNodeID, WireCellsDraft>]
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
            id: .new(),
            assetURL: assetURL,
            fileType: fileType,
            status: .uploading(progress: 0),
            name: fileName,
            bytes: assetSize
        )
        drafts.value[cellName, default: [:]][draft.id] = draft

        do {
            let (node, stream) = try await uploadManager.upload(
                id: draft.id,
                assetPath: assetURL,
                assetSize: UInt64(assetSize),
                destNodePath: "\(cellName)/\(fileName)"
            )

            // Update draft name if changed
            if let updatedName = URL(string: node.path)?.lastPathComponent, updatedName != draft.name {
                drafts.value[cellName]?[draft.id]?.name = updatedName
            }

            for await status in stream {
                setStatus(status, cellName: cellName, id: draft.id)
            }

        } catch {
            setStatus(.failed(error: WireCellsUploadError(error)), cellName: cellName, id: draft.id)
        }
    }

    package func drafts(for cellName: String) -> AsyncStream<[WireCellsDraft]> {
        let continuationID = UUID()
        let (stream, continuation) = AsyncStream.makeStream(
            of: [WireCellsDraft].self,
            bufferingPolicy: .bufferingOldest(0)
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
            of: Result<WireCellsNodeID, any Error>.self,
            returning: [Result<WireCellsNodeID, any Error>].self
        ) { [nodesAPI] group in
            for (nodeID, draft) in drafts where draft.status == .uploaded(isDraft: true) {
                group.addTask {
                    do {
                        try await nodesAPI.publishDraft(nodeID: nodeID)
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

    private func removeContinuation(for uuid: UUID) async {
        continuations[uuid] = nil
    }

    private func allDraftsArePublished(cellName: CellName) -> Bool {
        guard let drafts = drafts.value[cellName] else { return false }
        return drafts.values.allSatisfy { $0.status == .uploaded(isDraft: false) }
    }

    private func getStatus(cellName: CellName, id: WireCellsNodeID) -> WireCellsUploadStatus? {
        drafts.value[cellName]?[id]?.status
    }

    private func setStatus(_ status: WireCellsUploadStatus, cellName: CellName, id: WireCellsNodeID) {
        drafts.value[cellName]?[id]?.status = status
    }

    #if DEBUG
    var getDraftsForTesting: [CellName: OrderedDictionary<WireCellsNodeID, WireCellsDraft>] {
        drafts.value
    }

    func setDraftsForTesting(_ drafts: [CellName: OrderedDictionary<WireCellsNodeID, WireCellsDraft>]) {
        self.drafts.value = drafts
    }
    #endif

}

private extension WireCellsNodeID {
    static func new() -> WireCellsNodeID {
        WireCellsNodeID(uuid: UUID(), versionID: UUID())
    }
}

private extension OrderedDictionary<WireCellsNodeID, WireCellsDraft> {
    var areAllUploaded: Bool {
        allSatisfy {
            switch $0.value.status {
            case .uploaded:
                return true
            case .uploading, .failed, .cancelled:
                return false
            }
        }
    }

    var areAllPublished: Bool {
        values.allSatisfy { $0.status == .uploaded(isDraft: false) }
    }
}

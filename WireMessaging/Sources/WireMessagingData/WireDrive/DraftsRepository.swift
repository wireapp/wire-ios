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

import Collections
@preconcurrency import Combine
import Foundation
package import UniformTypeIdentifiers
import WireLogging
package import WireMessagingDomain

enum DraftsRepositoryError: Error, Equatable {

    case notAllFilesAreUploaded
    case notAllFilesArePublished

}

package actor DraftsRepository: DraftsRepositoryProtocol {

    typealias CellName = String

    private let drafts: CurrentValueSubject<[CellName: OrderedDictionary<UUID, WireDriveDraft>], Never>
    private var continuations: [UUID: AsyncStream<[WireDriveDraft]>.Continuation] = [:]
    private let uploadManager: any WireDriveNodeUploadManagerProtocol
    private let nodesAPI: any NodesAPIProtocol

    package init(uploadManager: any WireDriveNodeUploadManagerProtocol, nodesAPI: any NodesAPIProtocol) {
        self.init(uploadManager: uploadManager, nodesAPI: nodesAPI, drafts: [:])
    }

    init(
        uploadManager: any WireDriveNodeUploadManagerProtocol,
        nodesAPI: any NodesAPIProtocol,
        drafts: [CellName: OrderedDictionary<UUID, WireDriveDraft>]
    ) {
        self.uploadManager = uploadManager
        self.nodesAPI = nodesAPI
        self.drafts = CurrentValueSubject(drafts)
    }

    deinit {
        continuations.values.forEach { $0.finish() }
    }

    package func drafts(for cellName: String) -> AsyncStream<[WireDriveDraft]> {
        let continuationID = UUID()
        let (stream, continuation) = AsyncStream.makeStream(
            of: [WireDriveDraft].self,
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

    package func publishAll(for cellName: String) async throws -> [WireDriveDraft] {
        guard let drafts = drafts.value[cellName] else { return [] }

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
                        WireLogger.wireDrive.error("Failed to publish draft: \(error)")
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
        
        return drafts.map { $0.value }
    }

    /// Clears all published drafts for the specified cell name.
    ///
    /// - parameter cellName: The name of the cell for which to clear published drafts.
    /// - returns: The list of cleared published drafts.

    package func clearPublishedDrafts(for cellName: String) -> [WireDriveDraft] {
        guard let drafts = drafts.value[cellName] else { return [] }

        let publishedDrafts = drafts.values.filter { $0.status == .uploaded(isDraft: false) }
        for draft in publishedDrafts {
            deleteDraft(nodeID: draft.nodeID, cellName: cellName)
        }
        return publishedDrafts
    }

    /// Adds a draft for the given cell name.

    package func addDraft(_ draft: WireDriveDraft, for cellName: String) {
        drafts.value[cellName, default: [:]][draft.nodeID] = draft
    }

    /// Returns the draft for the given node ID and cell name, if it exists.

    package func fetchDraft(nodeID: UUID, cellName: String) -> WireDriveDraft? {
        drafts.value[cellName]?[nodeID]
    }

    /// Deletes draft for the given node ID and cell name.

    package func deleteDraft(nodeID: UUID, cellName: String) {
        drafts.value[cellName]?.removeValue(forKey: nodeID)
    }

    /// Updates draft for the given cell name.

    package func updateDraft(_ new: WireDriveDraft, for cellName: String) {
        guard let old = fetchDraft(nodeID: new.nodeID, cellName: cellName), new != old else { return }

        drafts.value[cellName]?[new.nodeID] = new
    }

    // MARK: - Private

    private func removeContinuation(for uuid: UUID) async {
        continuations[uuid] = nil
    }

    private func setStatus(_ status: WireDriveUploadStatus, cellName: CellName, id: UUID) {
        drafts.value[cellName]?[id]?.status = status
    }

    #if DEBUG
        var getDraftsForTesting: [CellName: OrderedDictionary<UUID, WireDriveDraft>] {
            drafts.value
        }

        func setDraftsForTesting(_ drafts: [CellName: OrderedDictionary<UUID, WireDriveDraft>]) {
            self.drafts.value = drafts
        }
    #endif

}

private extension OrderedDictionary<UUID, WireDriveDraft> {
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

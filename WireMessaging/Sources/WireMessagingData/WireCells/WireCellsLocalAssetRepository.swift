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

package import Combine
package import Foundation
package import WireMessagingDomain

/// Repository for accessing & updating `WireCellsLocalAsset`s.
///
/// This repository acts on the `@MainActor` to allow for non async main thread access of assets from the UI.
package final class WireCellsLocalAssetRepository: WireCellsLocalAssetRepositoryProtocol {

    private typealias GetNodeTask = Task<WireCellsNode, any Error>
    typealias NodeID = UUID

    private let nodesAPI: any NodesAPIProtocol
    private let fileDownloader: any FileDownloading
    private let fileCache: any FileCache
    private let store: any WireCellsLocalAssetStoreProtocol

    @MainActor private var getNodeTasks: [NodeID: GetNodeTask] = [:]

    @MainActor private var downloadTasks: [NodeID: Task<Void, any Error>] = [:]

    package convenience init(
        nodesAPI: any NodesAPIProtocol,
        fileCache: any FileCache,
        store: any WireCellsLocalAssetStoreProtocol,
    ) {
        self.init(nodesAPI: nodesAPI, fileDownloader: URLSession.shared, fileCache: fileCache, store: store)
    }

    init(
        nodesAPI: any NodesAPIProtocol,
        fileDownloader: any FileDownloading,
        fileCache: any FileCache,
        store: any WireCellsLocalAssetStoreProtocol
    ) {
        self.nodesAPI = nodesAPI
        self.fileDownloader = fileDownloader
        self.fileCache = fileCache
        self.store = store
    }

    /// Returns a `WireCellsLocalAsset` for the given `nodeID` or nil if metadata for the asset has has never been
    /// fetched.
    @MainActor
    package func asset(nodeID: UUID) throws -> WireMessagingDomain.WireCellsLocalAsset? {
        try store.asset(nodeID: nodeID)
    }

    /// Refreshes the local asset metadata for a given `nodeID` and deletes any cached file if necessary.
    ///
    /// The metadata (name etc) and file associated with a given `nodeID` may change. This method fetches the latest
    /// metadata from the server, updates local metadata if it has changed and deletes any cached file if it's
    /// `eTag` has changed.
    @MainActor
    package func refreshAssetMetadata(
        nodeID: UUID
    ) async throws -> (node: WireCellsNode, asset: WireCellsLocalAsset) {
        try await _refreshAssetMetadata(nodeID: nodeID)
    }

    /// Downloads the asset for the given `nodeID`.
    ///
    /// This method first refreshes the assets metadata - see `refreshMetadata(nodeID:)`.
    /// The download can be observed via the `observeAsset(nodeID:)` method.
    @MainActor
    package func downloadAsset(nodeID: UUID) async throws {
        if let existingTask = downloadTasks[nodeID] {
            try await existingTask.value
        } else {
            defer { downloadTasks[nodeID] = nil }

            let task = Task { try await _downloadAsset(nodeID: nodeID) }
            downloadTasks[nodeID] = task
            try await task.value
        }
    }

    /// Observes the asset for the given `nodeID`. A value of `nil` is emitted if the asset has never been fetched.
    @MainActor
    package func observeAsset(nodeID: UUID) -> AnyPublisher<WireMessagingDomain.WireCellsLocalAsset?, Never> {
        store.observeAsset(nodeID: nodeID)
    }

    /// Cancels the asset download for a given `nodeID`.
    @MainActor
    package func cancelDownload(nodeID: UUID) {
        downloadTasks[nodeID]?.cancel()
    }

    // MARK: - Private

    @MainActor
    private func _downloadAsset(nodeID: UUID) async throws {
        do {
            let node = try await getNode(nodeID: nodeID)
            let (downloadURL, eTag) = try node.downloadInfo

            try store.upsertAsset(
                WireCellsLocalAsset(
                    nodeID: nodeID,
                    eTag: eTag,
                    path: node.path,
                    contentType: node.mimeType,
                    size: node.size,
                    downloadState: .pending
                )
            )

            let (progress, download) = fileDownloader.download(from: downloadURL)
            for await progress in progress {
                var asset = try verifyAsset(nodeID: nodeID, eTag: eTag)
                asset.downloadState = .downloading(progress: progress)
                try store.upsertAsset(asset)
            }

            let (tempURL, _) = try await download.value

            var asset = try verifyAsset(nodeID: nodeID, eTag: eTag)
            try await fileCache.saveFile(at: tempURL, key: asset.cacheKey)

            asset = try verifyAsset(nodeID: nodeID, eTag: eTag)
            asset.downloadState = .downloaded(cacheKey: asset.cacheKey)
            try store.upsertAsset(asset)
        } catch {
            // We don't care about the eTag when setting download state to failed.
            if var asset = try store.asset(nodeID: nodeID) {
                asset.downloadState = .failed(error: error)
                try store.upsertAsset(asset)
            }

            throw error
        }
    }

    /// Returns the asset for the given `nodeID` and `eTag` or throws if the asset doesn't exist.
    @MainActor
    private func verifyAsset(nodeID: UUID, eTag: String) throws -> WireCellsLocalAsset {
        guard let asset = try store.asset(nodeID: nodeID), asset.eTag == eTag else {
            throw WireCellsLocalAssetRepositoryError.unknownAsset
        }
        return asset
    }

    @MainActor
    private func _refreshAssetMetadata(
        nodeID: UUID
    ) async throws -> (node: WireCellsNode, asset: WireCellsLocalAsset) {
        let node = try await getNode(nodeID: nodeID)
        let (_, eTag) = try node.downloadInfo

        var asset = try store.asset(nodeID: nodeID) ?? WireCellsLocalAsset(
            nodeID: nodeID,
            eTag: eTag,
            path: node.path,
            contentType: node.mimeType,
            size: node.size,
            downloadState: .pending
        )

        let downloadState: WireCellsLocalAsset.DownloadState
        switch asset.downloadState {
        case let .downloaded(cacheKey) where asset.eTag != eTag:
            try await fileCache.deleteFile(forKey: cacheKey)
            downloadState = .pending
        default:
            downloadState = asset.downloadState
        }

        asset.eTag = eTag
        asset.path = node.path
        asset.contentType = node.mimeType
        asset.size = node.size
        asset.downloadState = downloadState

        try store.upsertAsset(asset)

        return (node, asset)
    }

    @MainActor
    private func getNode(nodeID: UUID) async throws -> WireCellsNode {
        if let task = getNodeTasks[nodeID] {
            return try await task.value
        } else {
            defer { getNodeTasks[nodeID] = nil }

            let task = Task { try await nodesAPI.getNode(nodeID: nodeID) }
            getNodeTasks[nodeID] = task
            return try await task.value
        }
    }

}

// MARK: - Helpers

private extension WireCellsNode {

    var downloadInfo: (URL: URL, eTag: String) {
        get throws {
            typealias Error = WireCellsLocalAssetRepositoryError
            guard let downloadURL else { throw Error.missingDownloadURL }
            guard let eTag else { throw Error.missingETag }
            return (downloadURL, eTag)
        }
    }

}

private extension WireCellsLocalAsset {

    var cacheKey: String {
        WireCellsLocalAsset.cacheKey(nodeID: nodeID, eTag: eTag, path: path)
    }

}

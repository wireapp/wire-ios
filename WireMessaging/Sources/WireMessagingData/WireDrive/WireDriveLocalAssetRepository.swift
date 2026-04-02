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

package import Combine
package import Foundation
package import WireMessagingDomain

/// Repository for accessing & updating `WireCellsLocalAsset`s.
///
/// This repository acts on the `@MainActor` to allow for non async main thread access of assets from the UI.
package final class WireDriveLocalAssetRepository: WireDriveLocalAssetRepositoryProtocol {

    private typealias GetNodeTask = Task<WireDriveNode, any Error>
    typealias NodeID = UUID

    private let nodesAPI: any NodesAPIProtocol
    private let fileDownloader: any FileDownloading
    private let fileCache: any FileCache
    private let store: any WireDriveLocalAssetStoreProtocol

    @MainActor private var getNodeTasks: [NodeID: GetNodeTask] = [:]

    @MainActor private var downloadTasks: [NodeID: Task<Void, any Error>] = [:]

    package convenience init(
        nodesAPI: any NodesAPIProtocol,
        fileCache: any FileCache,
        store: any WireDriveLocalAssetStoreProtocol,
    ) {
        self.init(nodesAPI: nodesAPI, fileDownloader: URLSession.shared, fileCache: fileCache, store: store)
    }

    init(
        nodesAPI: any NodesAPIProtocol,
        fileDownloader: any FileDownloading,
        fileCache: any FileCache,
        store: any WireDriveLocalAssetStoreProtocol
    ) {
        self.nodesAPI = nodesAPI
        self.fileDownloader = fileDownloader
        self.fileCache = fileCache
        self.store = store
    }

    /// Returns a `WireCellsLocalAsset` for the given `nodeID` or nil if metadata for the asset has has never been
    /// fetched.
    @MainActor
    package func asset(nodeID: UUID) throws -> WireMessagingDomain.WireDriveLocalAsset? {
        try store.asset(nodeID: nodeID)
    }
    
    @MainActor
    package func allAssets() throws -> [WireMessagingDomain.WireDriveLocalAsset] {
        try store.allAssets()
    }
    
    @MainActor
    package func offlineAssets() throws -> [WireMessagingDomain.WireDriveLocalAsset] {
        try store.allAssets().filter { $0.isAvailableOffline }
    }

    /// Refreshes the local asset metadata for a given `nodeID` and deletes any cached file if necessary.
    ///
    /// The metadata (name etc) and file associated with a given `nodeID` may change. This method fetches the latest
    /// metadata from the server, updates local metadata if it has changed and deletes any cached file if it's
    /// `eTag` has changed.
    @MainActor
    package func refreshAssetMetadata(nodeID: UUID) async throws -> (node: WireDriveNode, asset: WireDriveLocalAsset) {
        try await _refreshAssetMetadata(nodeID: nodeID)
    }

    /// Downloads the asset for the given `nodeID`.
    ///
    /// This method first refreshes the assets metadata - see `refreshMetadata(nodeID:)`.
    /// The download can be observed via the `observeAsset(nodeID:)` method.
    @MainActor
    package func downloadAsset(nodeID: UUID, isAvailableOffline: Bool) async throws {
        if let existingTask = downloadTasks[nodeID] {
            try await existingTask.value
        } else {
            defer { downloadTasks[nodeID] = nil }

            let task = Task { try await _downloadAsset(nodeID: nodeID, isAvailableOffline: isAvailableOffline) }
            downloadTasks[nodeID] = task
            try await task.value
        }
    }

    /// Observes the asset for the given `nodeID`. A value of `nil` is emitted if the asset has never been fetched.
    @MainActor
    package func observeAsset(nodeID: UUID) -> AnyPublisher<WireMessagingDomain.WireDriveLocalAsset?, Never> {
        store.observeAsset(nodeID: nodeID)
    }

    /// Cancels the asset download for a given `nodeID`.
    @MainActor
    package func cancelDownload(nodeID: UUID) {
        downloadTasks[nodeID]?.cancel()
    }

    @MainActor
    package func updateAsset(_ asset: WireDriveLocalAsset) throws {
        try store.upsertAsset(asset)
    }

    @MainActor
    package func deleteAsset(nodeID: UUID) async throws {
        guard let asset = try store.asset(nodeID: nodeID),
              let cacheKey = asset.downloadState.cacheKey else {
            return
        }

        try await store.deleteAssets(nodeIDs: [nodeID])
        try await fileCache.deleteFile(forKey: cacheKey)
    }

    // MARK: - Private

    @MainActor
    private func _downloadAsset(nodeID: UUID, isAvailableOffline: Bool) async throws {
        do {
            let node = try await getNode(nodeID: nodeID)
            let (downloadURL, eTag) = try node.downloadInfo

            try updateAsset(
                WireDriveLocalAsset(
                    nodeID: nodeID,
                    eTag: eTag,
                    path: node.path,
                    contentType: node.mimeType,
                    size: node.size,
                    conversationName: node.conversation?.name,
                    ownerName: node.ownerUserName,
                    modified: node.modified,
                    isAvailableOffline: isAvailableOffline,
                    downloadState: .pending
                )
            )

            let (progress, urlDownloadTask) = fileDownloader.download(from: downloadURL)

            var fileSize: WireDriveLocalAsset.FileSize = .small

            let timerTask = Task {
                try await Task.sleep(for: .seconds(1))
                fileSize = .large
            }

            for try await progress in progress {
                var asset = try verifyAsset(nodeID: nodeID, eTag: eTag)
                asset.downloadState = .downloading(progress: progress)
                asset.fileSize = fileSize
                try updateAsset(asset)
            }

            timerTask.cancel()

            if Task.isCancelled {
                urlDownloadTask.cancel()
                try Task.checkCancellation()
            }

            let (tempURL, _) = try await urlDownloadTask.value
            let key = WireDriveLocalAsset.cacheKey(nodeID: nodeID, eTag: eTag, path: node.path)
            try await fileCache.saveFile(at: tempURL, key: key)

            var asset = try verifyAsset(nodeID: nodeID, eTag: eTag)
            asset.downloadState = .downloaded(cacheKey: key)

            try updateAsset(asset)
        } catch {
            // We don't care about the eTag when setting download state to failed.
            if var asset = try store.asset(nodeID: nodeID) {
                // On cancellation error, resets the asset to its initial download state.
                asset.downloadState = (error is CancellationError) ? .pending : .failed(error: error)
                asset.isAvailableOffline = false
                try store.upsertAsset(asset)
            }

            throw error
        }
    }

    /// Returns the asset for the given `nodeID` and `eTag` or throws if the asset doesn't exist.
    @MainActor
    private func verifyAsset(nodeID: UUID, eTag: String) throws -> WireDriveLocalAsset {
        guard let asset = try store.asset(nodeID: nodeID), asset.eTag == eTag else {
            throw WireDriveLocalAssetRepositoryError.unknownAsset
        }
        return asset
    }

    @MainActor
    private func _refreshAssetMetadata(
        nodeID: UUID
    ) async throws -> (node: WireDriveNode, asset: WireDriveLocalAsset) {
        let node = try await getNode(nodeID: nodeID)
        let (_, eTag) = try node.downloadInfo

        var asset = try store.asset(nodeID: nodeID) ?? WireDriveLocalAsset(
            nodeID: nodeID,
            eTag: eTag,
            path: node.path,
            contentType: node.mimeType,
            size: node.size,
            conversationName: node.conversation?.name,
            ownerName: node.ownerUserName,
            modified: node.modified,
            isAvailableOffline: false,
            downloadState: .pending
        )

        let downloadState: WireDriveLocalAsset.DownloadState
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

        try updateAsset(asset)

        return (node, asset)
    }

    @MainActor
    private func getNode(nodeID: UUID) async throws -> WireDriveNode {
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

private extension WireDriveNode {

    var downloadInfo: (URL: URL, eTag: String) {
        get throws {
            typealias Error = WireDriveLocalAssetRepositoryError
            guard let downloadURL else { throw Error.missingDownloadURL }
            guard let eTag else { throw Error.missingETag }
            return (downloadURL, eTag)
        }
    }

}

private extension WireDriveLocalAsset {

    var cacheKey: String {
        WireDriveLocalAsset.cacheKey(nodeID: nodeID, eTag: eTag, path: path)
    }

}

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

@MainActor
package final class WireCellsLocalAssetRepository: WireCellsLocalAssetRepositoryProtocol {

    enum DownloadState {
        case downloading(progress: Double, task: DownloadTask)
        case error(error: any Error)
    }

    private typealias GetNodeTask = Task<WireCellsNode, any Error>
    typealias DownloadTask = Task<(URL, URLResponse), any Error>
    typealias NodeID = UUID

    private let nodesAPI: any NodesAPIProtocol
    private let fileDownloader: any FileDownloading
    private let fileCache: any FileCache
    private let metadataStore: any WireCellsLocalAssetMetadataStore

    private var downloadStates: [NodeID: DownloadState]
    private var getNodeTasks: [NodeID: GetNodeTask] = [:]
    private let updates = PassthroughSubject<(UUID, WireCellsLocalAsset?), Never>()

    package convenience init(
        nodesAPI: any NodesAPIProtocol,
        fileCache: any FileCache,
        store: any WireCellsLocalAssetMetadataStore,
    ) {
        self.init(nodesAPI: nodesAPI, fileCache: fileCache, store: store, downloadStates: [:])
    }

    init(
        nodesAPI: any NodesAPIProtocol,
        fileDownloader: any FileDownloading = URLSession.shared,
        fileCache: any FileCache,
        store: any WireCellsLocalAssetMetadataStore,
        downloadStates: [NodeID: DownloadState] = [:],
    ) {
        self.nodesAPI = nodesAPI
        self.fileDownloader = fileDownloader
        self.fileCache = fileCache
        self.metadataStore = store
        self.downloadStates = downloadStates
    }

    /// Returns a `WireCellsLocalAsset` for the given `nodeID` or nil if metadata for the asset has has never been
    /// fetched.

    package func asset(nodeID: UUID) throws -> WireCellsLocalAsset? {
        guard let metadata = try metadataStore.assetMetadata(nodeID: nodeID) else { return nil }

        return Self.asset(metadata: metadata, downloadState: downloadStates[nodeID])
    }

    /// Refreshes the local asset metadata for a given `nodeID` and deletes any cached file if necessary.
    ///
    /// The metadata (name etc) and file associated with a given `nodeID` may change. This method fetches the latest
    /// metadata from the server, updates local metadata if it has changed and deletes any cached file if it's
    /// `eTag` has changed.

    package func refreshMetadata(nodeID: UUID) async throws {
        _ = try await _refreshMetadata(nodeID: nodeID)
    }

    /// Downloads the asset for the given `nodeID`.
    ///
    /// This method first refreshes the assets metadata - see `refreshMetadata(nodeID:)`.
    /// The download can be observed via the `observeAsset(nodeID:)` method.

    package func downloadAsset(nodeID: UUID) async throws {
        switch downloadStates[nodeID] {
        case .downloading:
            throw WireCellsLocalAssetRepositoryError.downloadAlreadyInProgress
        case .error:
            setDownloadState(nodeID: nodeID, state: .none)
        case .none:
            break
        }

        do {
            var (node, metadata) = try await _refreshMetadata(nodeID: nodeID)
            let (downloadURL, eTag) = try node.downloadInfo

            let (progress, download) = fileDownloader.download(from: downloadURL)

            for await progress in progress {
                setDownloadState(nodeID: nodeID, state: .downloading(progress: progress, task: download))
            }

            let (tempURL, _) = try await download.value
            try await fileCache.saveFile(at: tempURL, key: metadata.cacheKey)

            if try metadataStore.assetMetadata(nodeID: nodeID)?.eTag == eTag {
                // downloaded file is up-to-date so update the metadata
                metadata.isDownloaded = true
                try metadataStore.upsertAssetMetadata(metadata)
            } else {
                // remove the out-of-date file
                try await fileCache.deleteFile(forKey: metadata.cacheKey)
            }

            setDownloadState(nodeID: nodeID, state: .none)
        } catch {
            setDownloadState(nodeID: nodeID, state: .error(error: error))
            throw error
        }

    }

    /// Observes the asset for the given `nodeID`. A value of `nil` is emitted if the asset has never been fetched.

    package func observeAsset(nodeID: UUID) -> AnyPublisher<WireCellsLocalAsset?, Never> {
        updates.filter { $0.0 == nodeID }.map(\.1).eraseToAnyPublisher()
    }

    /// Cancels the asset download for a given `nodeID`.

    package func cancelDownload(nodeID: UUID) {
        switch downloadStates[nodeID] {
        case let .downloading(_, task):
            task.cancel()
        default:
            break
        }

        setDownloadState(nodeID: nodeID, state: nil)
    }

    // MARK: - Private

    private func _refreshMetadata(
        nodeID: UUID
    ) async throws -> (node: WireCellsNode, metadata: WireCellsLocalAssetMetadata) {
        let task = getNodeTask(nodeID: nodeID)

        getNodeTasks[nodeID] = task
        let node = try await task.value
        getNodeTasks[nodeID] = nil

        guard let eTag = node.eTag else {
            throw WireCellsLocalAssetRepositoryError.missingETag
        }

        var metadata = try metadataStore.assetMetadata(nodeID: nodeID) ?? WireCellsLocalAssetMetadata(
            nodeID: nodeID,
            eTag: eTag,
            path: node.path,
            contentType: node.mimeType,
            size: node.size,
            isDownloaded: false
        )

        let oldPersistenceKey = metadata.cacheKey
        let needsCleanup = metadata.isDownloaded && eTag != metadata.eTag

        metadata.eTag = eTag
        metadata.path = node.path
        metadata.contentType = node.mimeType
        metadata.size = node.size
        metadata.isDownloaded = needsCleanup ? false : metadata.isDownloaded

        try metadataStore.upsertAssetMetadata(metadata)

        if needsCleanup {
            try await fileCache.deleteFile(forKey: oldPersistenceKey)
        }

        notifyObservers(nodeID: nodeID)

        return (node, metadata)
    }

    private func notifyObservers(nodeID: UUID) {
        updates.send((nodeID, try? asset(nodeID: nodeID)))
    }

    private func setDownloadState(nodeID: UUID, state: DownloadState?) {
        downloadStates[nodeID] = state

        notifyObservers(nodeID: nodeID)
    }

    private static func asset(
        metadata: WireCellsLocalAssetMetadata,
        downloadState: DownloadState?
    ) -> WireCellsLocalAsset {
        let state: WireCellsLocalAsset.DownloadState = if metadata.isDownloaded {
            .downloaded(cacheKey: metadata.cacheKey)
        } else if let downloadState {
            switch downloadState {
            case let .downloading(progress, _):
                .downloading(progress: progress)
            case let .error(error):
                .failed(error: error)
            }
        } else {
            .pending
        }

        return WireCellsLocalAsset(
            nodeID: metadata.nodeID,
            eTag: metadata.eTag,
            path: metadata.path,
            contentType: metadata.contentType,
            size: metadata.size,
            downloadState: state
        )
    }

    private func getNodeTask(nodeID: UUID) -> GetNodeTask {
        if let task = getNodeTasks[nodeID] {
            task
        } else {
            // swiftlint:disable:next unhandled_throwing_task
            Task { [nodesAPI] in
                try await nodesAPI.getNode(nodeID: nodeID)
            }
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

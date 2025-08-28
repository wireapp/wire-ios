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

import Combine
import SwiftUI
import UniformTypeIdentifiers
import WireFoundation
package import WireMessagingDomain
import WireMessagingDomainSupport

/// An item in the `FilesView`.
struct FilesViewItem: Identifiable, Equatable {

    /// Identifier of this item on the wire cells backend.
    let id: UUID

    /// The filename of the file including its extension.
    let filename: String

    /// The name of the user who owns (uploaded) this file.
    let ownedBy: String?

    /// The date when the file was last modified.
    let modifiedAt: Date?

    /// The icon representing the file type.
    let icon: FileIcon
}

@MainActor
/// View model for the `FilesView`.
package final class FilesViewModel: ObservableObject {

    private typealias LoadItemsTask = Task<(items: [FilesViewItem], nextPage: WireCellsPageToken?), any Error>

    private enum Constants {

        /// How close to the end of the list before loading more items.
        static let loadMoreThreshold = 5
    }

    enum State: Equatable {
        case loading
        case received(items: [FilesViewItem])
        case noData
        case pending // cells are not ready yet

        var items: [FilesViewItem] {
            switch self {
            case let .received(items):
                items
            default:
                []
            }
        }
    }

    private let fetchNodesUseCase: WireCellsFetchNodesUseCase
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private let fileCache: any FileCache

    package init(
        fetchNodesUseCase: WireCellsFetchNodesUseCase,
        isCellsStatePending: Bool,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        fileCache: any FileCache
    ) {
        self.fetchNodesUseCase = fetchNodesUseCase
        self.localAssetRepository = localAssetRepository
        self.fileCache = fileCache
        self.state = isCellsStatePending ? .pending : .loading
    }

    @Published private var nextPageToken: WireCellsPageToken?
    @Published private var loadMoreTask: LoadItemsTask?
    @Published var alert: AlertModel?
    @Published var viewingURL: URL?
    @Published var state: State

    /// Whether there are more items to load.
    var hasMore: Bool {
        nextPageToken != nil
    }

    /// Whether the view model is currently loading items.
    var isLoading: Bool {
        loadMoreTask != nil
    }

    /// Reloads the items, clearing any previously loaded items.
    ///
    /// This method cancels any ongoing load operation and starts a new one.
    func reload() async {
        guard state != .pending else {
            return
        }

        cancelLoad()
        state = .loading
        nextPageToken = nil

        await loadMore(initialFetch: true)
    }

    /// Loads more items if available and `index` is towards the end of the list.
    ///
    /// This method checks if the `index` is within the threshold for loading more items. For example given a threshold
    /// of 5, when 10 items are loaded, it will load more when the index is 5 or above - i.e. when one of the last 5
    /// items is being displayed.
    ///
    /// - Parameter index: The index of the item which requested load more.
    func loadMoreIfNeeded(index: Int) async {
        let remaining = state.items.count - index - 1
        if remaining < Constants.loadMoreThreshold, nextPageToken != nil {
            await loadMore(initialFetch: false)
        }
    }

    /// Returns a `FilesItemViewModel` for the item at the given index.
    func itemViewModel(index: Int) -> FilesItemViewModel {
        FilesItemViewModel(item: state.items[index], localAssetRepository: localAssetRepository)
    }

    /// Downloads if necessary and views the asset represented by the given item.
    func viewAsset(item: FilesViewItem) async {
        do {
            if let result = try await localURL(for: item), result.item == item {
                viewingURL = result.url
            }
        } catch URLError.notConnectedToInternet, URLError.networkConnectionLost {
            alert = .noInternet
        } catch {
            alert = .unknownError
        }
    }

    // MARK: - Private

    private func localURL(for item: FilesViewItem) async throws -> (item: FilesViewItem, url: URL)? {
        // If the file is already downloaded, return the local URL.
        if
            let cacheKey = try localAssetRepository.asset(nodeID: item.id)?.downloadState.cacheKey,
            let url = fileCache.fileURL(forKey: cacheKey) {
                return (item, url)
        }

        let cacheKey: String?
        do {
            try await localAssetRepository.downloadAsset(nodeID: item.id)
            cacheKey = try localAssetRepository.asset(nodeID: item.id)?.downloadState.cacheKey
        } catch WireCellsLocalAssetRepositoryError.downloadAlreadyInProgress {
            try await awaitDownload(item: item)
            cacheKey = try localAssetRepository.asset(nodeID: item.id)?.downloadState.cacheKey
        }
        let url = cacheKey.flatMap { fileCache.fileURL(forKey: $0) }
        return url.map { (item, $0) } ?? nil
    }

    private func cancelLoad() {
        loadMoreTask?.cancel()
        loadMoreTask = nil
    }

    private func loadMore(initialFetch: Bool) async {
        guard loadMoreTask == nil else { return }

        let task = Task { try await fetchItems(token: nextPageToken) }

        loadMoreTask = task
        do {
            let (newItems, nextPage) = try await task.value
            var items = state.items
            items.append(contentsOf: newItems)
            state = initialFetch && items.isEmpty ? .noData : .received(items: items)
            nextPageToken = nextPage
        } catch URLError.notConnectedToInternet, URLError.networkConnectionLost {
            alert = .noInternet
            state = .noData
        } catch {
            alert = .unknownError
            state = .noData
        }
        loadMoreTask = nil
    }

    private nonisolated func fetchItems(
        token: WireCellsPageToken?
    ) async throws -> (items: [FilesViewItem], nextPage: WireCellsPageToken?) {
        let (nodes, nextPage) = try await fetchNodesUseCase.invoke(searchTerm: nil, token: token)

        let items = nodes.map { node in
            let url = URL(string: node.path)
            return FilesViewItem(
                id: node.id,
                filename: url?.lastPathComponent ?? node.path,
                ownedBy: node.ownerUserName,
                modifiedAt: node.modified,
                icon: .make(
                    type: node.mimeType.map { UTType(mimeType: $0) } ?? nil,
                    fileExtension: url?.pathExtension
                )
            )
        }

        try Task.checkCancellation()
        return (items, nextPage)
    }

    private func awaitDownload(item: FilesViewItem) async throws {
        for await item in localAssetRepository.observeAsset(nodeID: item.id).values {
            try Task.checkCancellation()

            switch item?.downloadState {
            case .downloaded:
                return
            case let .failed(error):
                throw error
            default:
                break
            }
        }
    }

}

private extension WireCellsLocalAsset.DownloadState {

    var cacheKey: String? {
        switch self {
        case let .downloaded(key):
            return key
        default:
            return nil
        }
    }
}

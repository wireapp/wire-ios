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
import WireLogging
package import WireMessagingDomain
import WireMessagingDomainSupport

/// An item in the `FilesView`.
struct FilesViewItem: Identifiable, Hashable {

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

    private typealias LoadItemsTask = Task<(items: [FilesViewItem], isLastPage: Bool), any Error>

    private enum Constants {

        /// How close to the end of the list before loading more items.
        static let loadMoreThreshold = 5
    }

    enum State: Equatable {

        case loading
        case received(items: [FilesViewItem])
        case pending // cells are not ready yet
        case error

        var items: [FilesViewItem] {
            switch self {
            case let .received(items):
                items
            default:
                []
            }
        }

        var isLoaded: Bool {
            switch self {
            case .loading, .pending, .error:
                false
            case .received:
                true
            }
        }
    }

    private let fetchNodesUseCase: WireCellsFetchNodesUseCase
    private let deleteNodesUseCase: WireCellsDeleteNodesUseCase
    private let createFolderUseCase: WireCellsCreateFolderUseCase
    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private let fileCache: any FileCache
    private var lastSelectedItem: FilesViewItem?
    private let cellName: String? // nil when browsing all files
    private var subfoldersPath: String? = nil // nil when no subfolders (folder is created at the root)
    private var subscriptions = Set<AnyCancellable>()

    @Published private(set) var hasMore = true
    @Published private var loadMoreTask: LoadItemsTask?
    @Published var searchText = ""
    @Published var alert: AlertModel?
    @Published var viewingURL: URL?
    @Published var state: State
    @Published var createFolderView: CreateFolderView?
    var didCreateFolder: Bool = false

    package init(
        fetchNodesUseCase: WireCellsFetchNodesUseCase,
        deleteNodesUseCase: WireCellsDeleteNodesUseCase,
        createFolderUseCase: WireCellsCreateFolderUseCase,
        isCellsStatePending: Bool,
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        fileCache: any FileCache,
        cellName: String? = nil,
    ) {
        self.fetchNodesUseCase = fetchNodesUseCase
        self.deleteNodesUseCase = deleteNodesUseCase
        self.createFolderUseCase = createFolderUseCase
        self.localAssetRepository = localAssetRepository
        self.fileCache = fileCache
        self.cellName = cellName
        self.state = isCellsStatePending ? .pending : .loading

        bindSearch()
    }

    /// Whether the view model is currently loading items.
    var isLoading: Bool {
        loadMoreTask != nil
    }

    private func bindSearch() {
        $searchText
            .removeDuplicates()
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.reload() }
            }
            .store(in: &subscriptions)
    }

    /// Reloads the items, clearing any previously loaded items.
    /// - Parameters:
    ///   - refreshing: Whether the reload was triggered by a pull-to-refresh action.
    ///
    /// Cancels any ongoing load operation and starts a new one.
    /// When `refreshing` is `true`, the current state is preserved since loading is managed by the system.

    func reload(refreshing: Bool = false) async {
        guard state != .pending else {
            return
        }

        cancelLoad()
        state = refreshing ? state : .loading
        hasMore = true

        await loadMore(refreshing: refreshing)
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
        if remaining < Constants.loadMoreThreshold, hasMore {
            await loadMore()
        }
    }

    /// Returns a `FilesItemViewModel` for the item at the given index.
    func itemViewModel(index: Int) -> FilesItemViewModel {
        FilesItemViewModel(
            item: state.items[index],
            localAssetRepository: localAssetRepository,
            onOpen: { [weak self] item in
                await self?.viewAsset(item: item)
            },
            onDelete: { [weak self] item in
                await self?.deleteItem(item)
            }
        )
    }

    /// Downloads if necessary and views the asset represented by the given item.
    func viewAsset(item: FilesViewItem) async {
        // Bookkeeping ensure we only attempt to display the most recently selected item.
        lastSelectedItem = item

        do {
            if let url = try await localURL(for: item), item == lastSelectedItem {
                viewingURL = url
            }
        } catch URLError.notConnectedToInternet, URLError.networkConnectionLost {
            alert = .noInternet
        } catch {
            alert = .unknownError
        }
    }
    
    func onCreateFolder() {
        guard let cellName else {
            return
        }
        
        let viewModel = CreateFolderViewModel(
            createFolderUseCase: createFolderUseCase,
            model: .init(
                cellName: cellName,
                subfoldersPath: subfoldersPath
            )
        )
        
        // to know whether we need to reload nodes.
        viewModel.$didCreate
            .sink { [weak self] didCreate in
                self?.didCreateFolder = didCreate
            }.store(in: &subscriptions)
        
        createFolderView = CreateFolderView(
            viewModel: viewModel
        )
    }

    // MARK: - Private

    private func localURL(for item: FilesViewItem) async throws -> URL? {
        // If the file is already downloaded, return the local URL.
        if
            let cacheKey = try localAssetRepository.asset(nodeID: item.id)?.downloadState.cacheKey,
            let url = fileCache.fileURL(forKey: cacheKey) {
            return url
        }

        let cacheKey: String?
        do {
            try await localAssetRepository.downloadAsset(nodeID: item.id)
            cacheKey = try localAssetRepository.asset(nodeID: item.id)?.downloadState.cacheKey
        } catch WireCellsLocalAssetRepositoryError.downloadAlreadyInProgress {
            try await awaitDownload(item: item)
            cacheKey = try localAssetRepository.asset(nodeID: item.id)?.downloadState.cacheKey
        }
        return cacheKey.flatMap { fileCache.fileURL(forKey: $0) }
    }

    private func cancelLoad() {
        loadMoreTask?.cancel()
        loadMoreTask = nil
    }

    private func loadMore(refreshing: Bool = false) async {
        guard loadMoreTask == nil else { return }

        let offset = refreshing ? 0 : state.items.count
        let task = Task { try await fetchItems(offset: offset) }

        loadMoreTask = task
        do {
            let (newItems, isLastPage) = try await task.value
            let receivedItems = Self.processItems(refreshing ? newItems : state.items + newItems)
            state = .received(items: [])
            hasMore = !isLastPage
        } catch is CancellationError {
            return // developer-driven error, discard
        } catch {
            if state.items.isEmpty {
                state = .error
            } else {
                let urlError = (error as? URLError)?.code
                let isNoInternetError = urlError == .notConnectedToInternet || urlError == .networkConnectionLost
                alert = isNoInternetError ? .noInternet : .unknownError
            }

            hasMore = state.items.isEmpty ? true : hasMore
        }
        loadMoreTask = nil
    }

    private nonisolated func fetchItems(
        offset: Int
    ) async throws -> (items: [FilesViewItem], isLastPage: Bool) {
        let (nodes, isLastPage) = try await fetchNodesUseCase.invoke(
            searchTerm: searchText.isEmpty ? nil : searchText,
            offset: offset
        )

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
        return (items, isLastPage)
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

    private func deleteItem(_ asset: FilesViewItem) async {
        guard state.isLoaded else {
            WireLogger.wireCells.error("Attempt to delete asset while not visible", attributes: .safePublic)
            return
        }

        var currentItems = state.items
        currentItems.removeAll { $0.id == asset.id }
        state = .received(items: Self.processItems(currentItems))

        do {
            try await deleteNodesUseCase.invoke(nodeIDs: [asset.id])
        } catch {
            guard state.isLoaded else { return }

            var currentItems = state.items
            currentItems.append(asset)
            state = .received(items: Self.processItems(currentItems))
        }
    }

    /// Sorts items first by modified date descending, then by filename ascending.
    /// If multiple items have the same `nodeID`, only the first is kept.
    private static func processItems(_ items: [FilesViewItem]) -> [FilesViewItem] {
        // sort
        let sorted = items.sorted { left, right in
            if let leftModified = left.modifiedAt, let rightModified = right.modifiedAt {
                if leftModified == rightModified {
                    left.filename < right.filename
                } else {
                    leftModified > rightModified
                }
            } else if left.modifiedAt != nil {
                true
            } else if right.modifiedAt != nil {
                false
            } else {
                left.filename < right.filename
            }
        }

        var nodeIDs = Set<UUID>()
        var results: [FilesViewItem] = []
        for item in sorted where !nodeIDs.contains(item.id) {
            nodeIDs.insert(item.id)
            results.append(item)
        }

        return results
    }

}
